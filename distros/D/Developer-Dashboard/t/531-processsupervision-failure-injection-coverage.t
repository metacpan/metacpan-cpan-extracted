#!/usr/bin/env perl

use strict;
use warnings;
use Symbol qw(gensym);

{
    package DD::Test::EmptyProcRead;
    sub TIEHANDLE { return bless {}, shift }
    sub READLINE { return undef if $main::FORCE_EMPTY_READ == 2; return '' }
    sub CLOSE { return 1 }
}

# BEGIN-time CORE::GLOBAL::open override: it fails or redirects only for exact
# registered paths, so these branches run the same for root and non-root users.
our ( %OPEN_FAIL, %OPEN_REDIRECT, %READ_DUP_FAIL, $FORCE_DEV_FD_LINK, $FORCE_EMPTY_READ, $EMPTY_READ_PATH );

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        # Force the first descriptor duplication to fail so the writable
        # fallback branch is exercised on both Unix and Windows.
        if ( @_ >= 3 && defined $_[1] && $_[1] eq '<&'
             && defined $_[2] && $READ_DUP_FAIL{$_[2]} ) {
            $! = 9;
            return 0;
        }
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] ) {
            my $path = $_[2];
            if ( $FORCE_EMPTY_READ && defined $EMPTY_READ_PATH && $path eq $EMPTY_READ_PATH ) {
                $_[0] = gensym();
                tie *{ $_[0] }, 'DD::Test::EmptyProcRead';
                return 1;
            }
            if ( $OPEN_FAIL{$path} ) {
                $! = 13;
                return 0;
            }
            if ( my $redirect = $OPEN_REDIRECT{$path} ) {
                return CORE::open( $_[0], $redirect->[0], @{$redirect}[ 1 .. $#{$redirect} ] );
            }
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };

    *CORE::GLOBAL::readlink = sub (_) {
        if ($FORCE_DEV_FD_LINK && $_[0] =~ m{\A/proc/self/fd/}) {
            return 'anon_inode:[eventfd]' if $FORCE_DEV_FD_LINK == 2;
            return undef;
        }
        if ($FORCE_DEV_FD_LINK && $_[0] =~ m{\A/dev/fd/}) {
            return undef if $FORCE_DEV_FD_LINK == 3;
            return 'ordinary-file' if $FORCE_DEV_FD_LINK == 4;
            return 'anon_inode:[eventfd]';
        }
        return CORE::readlink($_[0]);
    };
}

use Test::More;
use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::ProcessSupervision;

my $dir  = tempdir( CLEANUP => 1 );
my $self = bless {}, 'Developer::Dashboard::ProcessSupervision';

# In-place overwrite on Windows: the source pending file is consumed.
{
    no warnings 'redefine';
    local *Developer::Dashboard::ProcessSupervision::is_windows = sub { 1 };
    my $source = File::Spec->catfile( $dir, 'source.tmp' );
    my $target = File::Spec->catfile( $dir, 'target.json' );
    open my $fh, '>', $source or die $!;
    print {$fh} "payload";
    close $fh;
    my ( $ok, $err ) = $self->_overwrite_state_file_in_place( $source, $target );
    ok( $ok, 'in-place overwrite succeeds' );
    ok( !-e $source, 'the pending source file is removed after the overwrite' );
    ( $ok, $err ) = Developer::Dashboard::ProcessSupervision::_overwrite_state_file_in_place( $self, $source, $target );
    ok( !$ok, 'a missing source is reported as a failure' );
}

# Descriptor listing yields numeric descriptors only.
{
    my @fds = $self->_open_file_descriptors;
    ok( scalar( grep { $_ == 0 } @fds ), 'descriptor listing includes stdin' );
    ok( !scalar( grep { $_ !~ /^\d+$/ } @fds ), 'descriptor listing is numeric only' );
}

# Windows branch: with no /proc or /dev/fd, the descriptor listing probes
# the CRT descriptor table instead, so it still includes the standard
# descriptors. Proved on Linux by localizing the platform; on Windows the
# branch is live.
{
    my @win_fds;
    {
        local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
        @win_fds = $self->_open_file_descriptors;
    }
    ok( scalar( grep { $_ == 0 } @win_fds ), 'on Windows the descriptor listing still includes stdin' );
    ok( !scalar( grep { $_ !~ /^\d+$/ } @win_fds ), 'on Windows the descriptor listing is numeric only' );
}

# Simulate procfs/devfs listing the same descriptor more than once. This
# reaches the deduplication branch independent of host descriptor layout.
{
    no warnings 'redefine';
    local *Developer::Dashboard::ProcessSupervision::_fd_candidate_paths = sub {
        return ('/proc/self/fd/3', '/dev/fd/3', '/dev/fd/7');
    };
    # The procfs/devfs listing is the non-Windows branch: on Windows the
    # product probes the CRT descriptor table and never consults candidate
    # paths. Localize the platform, as the Windows-branch block above does in
    # the other direction, so the deduplication is proved on every host.
    local $Developer::Dashboard::Platform::OS_NAME = 'linux';
    is_deeply( [ $self->_open_file_descriptors ], [3, 7],
        '_open_file_descriptors removes duplicate procfs/devfs descriptor entries' );
}

# Child-library path filtering uses the current working directory when the
# captured base is empty and rejects non-path @INC hooks and empty entries.
{
    local $Developer::Dashboard::ProcessSupervision::PERL_LIBRARY_BASE = '';
    local @INC = ( undef, [], '', 'relative-lib' );
    is_deeply(
        [ $self->_perl_library_args ],
        [ '-I' . File::Spec->rel2abs('relative-lib') ],
        '_perl_library_args resolves relative paths from cwd and omits non-path @INC entries',
    );
}

# Non-canonical @INC entries are canonicalised: on Windows Strawberry Perl
# and local::lib PERL5LIB entries mix separators
# (C:\...\try\lib\perl5/MSWin32-x64-multi-thread), and the spawned child must
# receive the native form.
{
    local $Developer::Dashboard::ProcessSupervision::PERL_LIBRARY_BASE = '';
    local @INC = ('/tmp//double-slash-lib');
    is_deeply(
        [ $self->_perl_library_args ],
        [ '-I' . File::Spec->canonpath('/tmp//double-slash-lib') ],
        '_perl_library_args canonicalises non-canonical @INC entries',
    );
}

{
    no warnings 'redefine';
    local $Developer::Dashboard::ProcessSupervision::PERL_LIBRARY_BASE = '';
    local @INC = ('relative-lib');
    local *Developer::Dashboard::ProcessSupervision::getcwd = sub { return undef };
    is_deeply(
        [ $self->_perl_library_args ],
        [ '-I' . File::Spec->rel2abs('relative-lib') ],
        '_perl_library_args remains usable when getcwd cannot provide a fallback base',
    );
}

# Descriptor cleanup must leave non-pipe descriptors alone and close selected
# inherited-pipe descriptors. The close call is stubbed so this unit test never
# changes the test process' own descriptor table.
{
    no warnings 'redefine';
    my @closed;
    local *Developer::Dashboard::ProcessSupervision::_open_file_descriptors = sub { return ( 42, 43 ) };
    local *Developer::Dashboard::ProcessSupervision::_descriptor_is_inherited_pipe = sub {
        return $_[1] == 43;
    };
    local *POSIX::close = sub { push @closed, $_[0]; return 1 };
    is( $self->_close_inherited_fds, 1, '_close_inherited_fds completes after checking inherited descriptors' );
    is_deeply( \@closed, [43], 'cleanup skips non-pipes and closes only inherited pipe descriptors' );
}

# Cover the descriptor fallbacks without changing real process descriptors.
# The write-only file is never a pipe or socket, and can be closed normally.
{
    my $regular = File::Spec->catfile( $dir, 'descriptor-fallback' );
    open my $regular_fh, '>', $regular or die "Unable to open $regular: $!";
    my $fd = fileno($regular_fh);
    ok( defined $fd, 'the descriptor fallback fixture has a file number' );

    {
        local $READ_DUP_FAIL{$fd} = 1;
        is(
            $self->_descriptor_is_inherited_pipe( $fd, close_ipc => 1 ),
            0,
            'a failed read duplication falls back to a writable descriptor',
        );
    }

    {
        local $FORCE_DEV_FD_LINK = 1;
        is(
            Developer::Dashboard::ProcessSupervision::_fd_link_target($fd),
            'anon_inode:[eventfd]',
            'the descriptor link falls back to devfs when procfs is unavailable',
        );
        is(
            $self->_descriptor_is_inherited_pipe( $fd, close_ipc => 1 ),
            1,
            'an anonymous kernel descriptor is recognised through the fallback',
        );
    }

    {
        no warnings 'redefine';
        local *Developer::Dashboard::ProcessSupervision::_fd_link_target = sub {
            return undef;
        };
        is(
            $self->_descriptor_is_inherited_pipe( $fd, close_ipc => 1 ),
            0,
            'a descriptor without any link target is not an inherited pipe',
        );
    }


    {
        local $FORCE_DEV_FD_LINK = 2;
        is( Developer::Dashboard::ProcessSupervision::_fd_link_target($fd),
            'anon_inode:[eventfd]',
            'procfs descriptor link is preferred when available' );
    }
    {
        local $FORCE_DEV_FD_LINK = 3;
        is( Developer::Dashboard::ProcessSupervision::_fd_link_target($fd), undef,
            'missing procfs and devfs descriptor links return undef' );
    }
    {
        local $FORCE_DEV_FD_LINK = 4;
        is( $self->_descriptor_is_inherited_pipe( $fd, close_ipc => 1 ), 0,
            'a defined non-anonymous fd target is not an inherited pipe' );
    }
    close $regular_fh or die "Unable to close $regular: $!";
}

# Inherited-pipe detection for an unknown descriptor.
is( $self->_descriptor_is_inherited_pipe(99999), 0, 'a closed descriptor is not an inherited pipe' );

# Process environment marker reads.
{
    my $envfile = File::Spec->catfile( $dir, 'environ' );
    open my $fh, '>', $envfile or die $!;
    print {$fh} "A=1\0DD_MARK=found\0";
    close $fh;

    my $real = $$;
    my $real_proc = "/proc/$real/environ";

    {
        local $OPEN_REDIRECT{$real_proc} = [ '<', $envfile ];
        SKIP: {
            skip 'procfs permission precondition unavailable', 1 if !-r $real_proc;
            is( $self->_read_process_env_marker( $real, 'DD_MARK' ), 'found',
                'the marker is read from the process environment' );
        }
        is( $self->_read_process_env_marker( $real, 'MISSING' ), undef, 'an absent marker reads as undef' );
    }
    {
        local $OPEN_FAIL{$real_proc} = 1;
        is( $self->_read_process_env_marker( $real, 'DD_MARK' ), undef, 'an unopenable environ file reads as undef' );
    }
    {
        my $empty = File::Spec->catfile( $dir, 'empty-environ' );
        open my $efh, '>', $empty or die $!;
        close $efh;
        local $OPEN_REDIRECT{$real_proc} = [ '<', $empty ];
        is( $self->_read_process_env_marker( $real, 'DD_MARK' ), undef, 'an empty environ reads as undef' );
    }
    {
        local $OPEN_REDIRECT{$real_proc} = [ '<', $dir ];
        my $marker;
        my ( $stdout, $stderr, $exit ) = capture {
            $marker = $self->_read_process_env_marker( $real, 'DD_MARK' );
        };
        is( $marker, undef, 'an unreadable environ slurp reads as undef' );
        is( $stdout, '', 'an unreadable environ slurp emits no standard output' );
        is( $stderr, '', 'an unreadable environ slurp emits no warning' );
    }
}

# Read procfs metadata from a private directory so macOS and Windows also
# execute the real parser instead of skipping Linux-only /proc entries.
{
    require File::Path;
    my $root = File::Spec->catdir( $dir, 'portable-proc' );
    my $pid = 61234;
    my $pid_dir = File::Spec->catdir( $root, $pid );
    File::Path::make_path($pid_dir);
    my $environ = File::Spec->catfile( $pid_dir, 'environ' );
    open my $fh, '>:raw', $environ or die "Unable to create $environ: $!";
    print {$fh} "NOT_AN_ENV_ENTRY\0DD_MARK=fixture\0";
    close $fh or die "Unable to close $environ: $!";
    local $Developer::Dashboard::ProcessSupervision::PROCFS_ROOT = $root;
    is( $self->_read_process_env_marker( $pid, 'DD_MARK' ), 'fixture',
        '_read_process_env_marker parses real binary NUL-delimited fixture data' );
    is( $self->_read_process_env_marker( $pid, 'ABSENT' ), undef,
        '_read_process_env_marker returns undef for a missing key in readable procfs data' );
    is( $self->_read_process_env_marker( $pid + 1, 'DD_MARK' ), undef,
        '_read_process_env_marker handles a missing procfs entry on every platform' );
    {
        # The reader opens "$PROCFS_ROOT/$pid/environ" with forward slashes
        # on every platform; key the injected failure on that spelling too,
        # since File::Spec gives backslashes on Windows.
        local $OPEN_FAIL{$environ} = 1;
        local $OPEN_FAIL{"$root/$pid/environ"} = 1;
        is( $self->_read_process_env_marker( $pid, 'DD_MARK' ), undef,
            '_read_process_env_marker handles a denied open after the readable-file check' );
    }
    my $ns_dir = File::Spec->catdir( $pid_dir, 'ns' );
    File::Path::make_path($ns_dir);
    my $namespace = File::Spec->catfile( $ns_dir, 'pid' );
    is( $self->_pid_namespace_id($pid), undef,
        '_pid_namespace_id ignores a missing namespace link' );
    SKIP: {
        skip 'symlinks unavailable on this host', 1 if !symlink( 'pid:[fixture]', $namespace );
        is( $self->_pid_namespace_id($pid), 'pid:[fixture]',
            '_pid_namespace_id reads a valid procfs namespace link' );
    }
}

# The namespace comparison accepts an unknown identity but distinguishes
# a real matching namespace from a foreign one, irrespective of host procfs.
{
    no warnings 'redefine';
    local *Developer::Dashboard::ProcessSupervision::_pid_namespace_id = sub {
        my ( undef, $pid ) = @_;
        return 'ns:[self]' if $pid == $$;
        return 'ns:[self]' if $pid == 61001;
        return 'ns:[other]' if $pid == 61002;
        return '' if $pid == 61003;
        return undef;
    };
    is( $self->_same_pid_namespace(61001), 1, 'matching namespace is accepted' );
    is( $self->_same_pid_namespace(61002), 0, 'foreign namespace is rejected' );
    is( $self->_same_pid_namespace(61003), 1, 'empty target namespace is conservatively accepted' );
    is( $self->_same_pid_namespace(61004), 1, 'unreadable target namespace is conservatively accepted' );
    {
        local *Developer::Dashboard::ProcessSupervision::_pid_namespace_id = sub {
            return undef if $_[1] == $$;
            return 'ns:[other]';
        };
        is( $self->_same_pid_namespace(61002), 1,
            'unknown current namespace is conservatively accepted' );
    }
    {
        local *Developer::Dashboard::ProcessSupervision::_pid_namespace_id = sub {
            return '' if $_[1] == $$;
            return 'ns:[other]';
        };
        is( $self->_same_pid_namespace(61002), 1,
            'empty current namespace is conservatively accepted' );
    }
}

# Test the no-content procfs environment shapes without Linux-only devices.
{
    my $root = File::Spec->catdir( $dir, 'proc-empty-environ' );
    my $pid_dir = File::Spec->catdir( $root, '61005' );
    File::Path::make_path($pid_dir);
    my $path = File::Spec->catfile( $pid_dir, 'environ' );
    open my $fh, '>', $path or die "Unable to create $path: $!";
    close $fh or die "Unable to close $path: $!";
    local $Developer::Dashboard::ProcessSupervision::PROCFS_ROOT = $root;
    is( $self->_read_process_env_marker(61005, 'DD_MARK'), undef,
        'empty readable procfs environ file contains no marker' );
    {
        local $FORCE_EMPTY_READ = 1;
        local $EMPTY_READ_PATH = $path;
        is( $self->_read_process_env_marker(61005, 'DD_MARK'), undef,
            'defined but empty procfs environ payload has no marker' );
    }
    {
        local $FORCE_EMPTY_READ = 2;
        local $EMPTY_READ_PATH = $path;
        is( $self->_read_process_env_marker(61005, 'DD_MARK'), undef,
            'undefined procfs environ read is handled without dereferencing' );
    }
}

# A Windows SystemRoot value must be honoured before probing the PowerShell
# default executable, even when neither PATH nor the fallback contains it.
{
    no warnings 'redefine';
    local *Developer::Dashboard::ProcessSupervision::is_windows = sub { 1 };
    local *Developer::Dashboard::ProcessSupervision::command_in_path = sub { return '' };
    local $ENV{SystemRoot} = File::Spec->catdir( $dir, 'nonexistent-winroot' );
    is( Developer::Dashboard::ProcessSupervision::_powershell_command(), '',
        'PowerShell fallback honours an explicit SystemRoot when executable is absent' );
    {
        local %ENV = %ENV;
        delete $ENV{SystemRoot};
        # With SystemRoot unset the resolver guesses the standard
        # C:\Windows root (deliberate since the original resolver in
        # a8a95985, kept by DD-753): on a Windows host that file exists
        # and is returned, off Windows the guess names nothing.
        my $default = File::Spec->catfile( 'C:\\Windows', 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe' );
        my $expected = -f $default ? $default : '';
        is( Developer::Dashboard::ProcessSupervision::_powershell_command(), $expected,
            'PowerShell fallback chooses default Windows root without SystemRoot' );
    }
}

# Helper file support: a read handle whose close reports failure.
{
    my $helper = File::Spec->catfile( $dir, 'helper.pl' );
    open my $fh, '>', $helper or die $!;
    print {$fh} "web-foreground\n";
    close $fh;
    local $OPEN_REDIRECT{$helper} = [ '-|', 'sh', '-c', 'echo web-foreground; exit 3' ];
    is( $self->_helper_file_supports_internal_command( $helper, 'web-foreground' ), 0, 'a helper whose handle fails to close is not supported' );
}

done_testing;

__END__

=pod

=head1 NAME

t/531-processsupervision-failure-injection-coverage.t - failure-injection coverage for Developer::Dashboard::ProcessSupervision

=head1 PURPOSE

This regression test covers ProcessSupervision's in-place overwrite cleanup,
descriptor enumeration, fallback duplication and link-target handling,
child Perl library-path construction,
process-environment reads, and helper-file close failures. A BEGIN-time
C<CORE::GLOBAL::open> override fails or redirects only exact registered paths,
so failure branches are testable without depending on filesystem permissions
that behave differently under root.

=head1 WHY IT EXISTS

It exists because the lib/ coverage gate requires every branch to be genuinely executed with no uncoverable annotations, and chmod-based failures do not work when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change the state-file overwrite, descriptor inspection, process environment marker reader or helper-support check in ProcessSupervision.

=head1 HOW TO USE

Run it directly with C<prove -lv t/531-processsupervision-failure-injection-coverage.t>. Redirect entries substitute the arguments of the real open, so a pipe open whose close fails can stand in for a read handle.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification.

=head1 EXAMPLES

Example 1:

  prove -lv t/531-processsupervision-failure-injection-coverage.t

Run these tests by themselves while editing ProcessSupervision.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/531-processsupervision-failure-injection-coverage.t

Confirm the injected branches are reported as covered.

=cut
