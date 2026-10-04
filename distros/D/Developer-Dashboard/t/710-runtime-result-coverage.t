#!/usr/bin/env perl

use strict;
use warnings;

# Failure injection for Developer::Dashboard::Runtime::Result. The CORE::GLOBAL
# overrides must be installed before the module compiles. Each one fails only
# when its flag in %FAIL is armed so the error branches run for any uid, root included.
our %FAIL;

BEGIN {
    require Symbol;
    *CORE::GLOBAL::chmod = sub (@) {
        if ( $FAIL{chmod} && @_ == 2 && ref $_[1] ) {
            $! = 1;
            return 0;
        }
        return CORE::chmod(@_);
    };
    *CORE::GLOBAL::fcntl = sub (*$$) {
        my $fh = ref $_[0] ? $_[0] : Symbol::qualify_to_ref( $_[0], scalar caller );
        if ( $FAIL{fcntl_get} && $_[1] == 1 ) {
            return undef;
        }
        if ( $FAIL{fcntl_set} && $_[1] == 2 ) {
            $! = 9;
            return undef;
        }
        return CORE::fcntl( $fh, $_[1], $_[2] );
    };
    *CORE::GLOBAL::truncate = sub ($$) {
        if ( ref $_[0] && ref $_[0] ne 'SCALAR' && tied( *{ $_[0] } ) && tied( *{ $_[0] } )->isa('ScriptedHandle') ) {
            $! = 5;
            return tied( *{ $_[0] } )->{truncate_ok} ? 1 : 0;
        }
        return CORE::truncate( $_[0], $_[1] );
    };
}

# A tied handle whose close/seek/truncate outcomes the test scripts.
{
    package ScriptedHandle;
    sub TIEHANDLE { my ( $class, %args ) = @_; return bless { content => '', read => 0, %args }, $class }
    sub PRINT     { my $self = shift; $self->{content} .= join( '', @_ ); return 1 }
    sub TELL      { return length $_[0]{content} }
    sub SEEK      { $! = 29; return $_[0]{seek_ok} ? 1 : 0 }
    sub CLOSE     { $! = 9; return $_[0]{close_ok} ? 1 : 0 }
    sub BINMODE   { return 1 }
    sub READLINE  { my $self = shift; return if $self->{read}++; return $self->{content} }
}

use Fcntl qw(F_GETFD F_SETFD);
use File::Basename ();
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use JSON::XS qw(encode_json);

use lib 'lib';

use Developer::Dashboard::Runtime::Result;

my $P    = 'Developer::Dashboard::Runtime::Result';
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{RESULT};
delete local $ENV{RESULT_FILE};
delete local $ENV{LAST_RESULT};
delete local $ENV{LAST_RESULT_FILE};

sub scripted {
    my (%args) = @_;
    my $fh = Symbol::gensym();
    tie *{$fh}, 'ScriptedHandle', %args;
    return $fh;
}

# A RESULT_FILE that names a directory opens but fails to close after the
# read error, so the close failure is reported; an empty file is no payload.
{
    local $ENV{RESULT_FILE} = $home;
    my $err = eval { Developer::Dashboard::Runtime::Result::current(); 1 } ? '' : $@;
    like( $err, qr/Unable to close RESULT file/, 'a RESULT_FILE that cannot be read cleanly is fatal' );

    my $empty = File::Spec->catfile( $home, 'empty-result' );
    open my $fh, '>', $empty or die "Unable to write $empty: $!";
    close $fh or die "Unable to close $empty: $!";
    local $ENV{RESULT_FILE}      = $empty;
    local $ENV{LAST_RESULT_FILE} = $empty;
    is_deeply( Developer::Dashboard::Runtime::Result::current(), {}, 'an empty RESULT_FILE yields an empty result' );
    is( Developer::Dashboard::Runtime::Result::last_result(), undef, 'an empty LAST_RESULT_FILE yields undef' );
}

# Tempfile hardening failures.
{
    my $real = \&File::Temp::tempfile;
    no warnings 'redefine';
    local *Developer::Dashboard::Runtime::Result::tempfile = sub { return $real->(@_) };

    for my $case ( [ chmod => qr/Unable to chmod RESULT tempfile/ ], [ fcntl_get => qr/Unable to inspect RESULT file descriptor flags/ ], [ fcntl_set => qr/Unable to clear close-on-exec/ ] ) {
        my ( $flag, $re ) = @{$case};
        local $FAIL{$flag} = 1;
        my $err = eval { Developer::Dashboard::Runtime::Result::_open_channel_file(); 1 } ? '' : $@;
        like( $err, $re, "_open_channel_file reports a $flag failure" );
    }

    my ( $fh, $path ) = Developer::Dashboard::Runtime::Result::_open_channel_file();
    like( $path, qr{\A/(?:dev|proc/self)/fd/\d+\z}, 'the default channel path is fd-backed' );
    close $fh;

    local $Developer::Dashboard::Runtime::Result::DEV_FD_DIR = '/nonexistent-dev-fd';
    ( $fh, $path ) = Developer::Dashboard::Runtime::Result::_open_channel_file();
    like( $path, qr{\A/proc/self/fd/\d+\z}, 'without a /dev/fd directory the channel path falls back to /proc/self/fd' );
    close $fh;
}

# Truncate, rewind, and close failures on the file-backed channel.
{
    no warnings 'redefine';
    my $handle;
    local *Developer::Dashboard::Runtime::Result::_open_channel_file = sub { return ( $handle, '/virtual/fd/9' ) };

    $handle = scripted( truncate_ok => 0, seek_ok => 1, close_ok => 1 );
    my $err = eval { Developer::Dashboard::Runtime::Result::set_current( { a => 1 }, max_inline_bytes => 1 ); 1 } ? '' : $@;
    like( $err, qr/Unable to truncate RESULT file/, 'set_current reports a truncate failure' );

    $handle = scripted( truncate_ok => 1, seek_ok => 0, close_ok => 1 );
    $err = eval { Developer::Dashboard::Runtime::Result::set_current( { a => 1 }, max_inline_bytes => 1 ); 1 } ? '' : $@;
    like( $err, qr/Unable to rewind RESULT file/, 'set_current reports a rewind failure' );

    $handle = scripted( truncate_ok => 1, seek_ok => 1, close_ok => 0 );
    is( Developer::Dashboard::Runtime::Result::set_current( { a => 1 }, max_inline_bytes => 1 ), 'file', 'a scripted handle is accepted as the file-backed channel' );
    $err = eval { Developer::Dashboard::Runtime::Result::clear_current(); 1 } ? '' : $@;
    like( $err, qr/Unable to close result file handle for \/virtual\/fd\/9/, 'releasing a handle whose close fails is fatal' );
    tied( *{$handle} )->{close_ok} = 1;
    is( Developer::Dashboard::Runtime::Result::clear_current(), '', 'once close works the channel clears' );
}

# report() and last_result() accept being called as a class method or function.
{
    local $ENV{RESULT} = encode_json( { '00-a.pl' => { exit_code => 0 } } );
    local $0 = '/usr/bin/dashboard';
    like( $P->report(), qr/dashboard Run Report/, 'report as a class method strips the package name' );
    like( Developer::Dashboard::Runtime::Result::report( command => 'x' ), qr/x Run Report/, 'report as a function honours the command override' );
    like( Developer::Dashboard::Runtime::Result::report(), qr/dashboard Run Report/, 'report with no arguments works' );
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        like( Developer::Dashboard::Runtime::Result::report(undef), qr/dashboard Run Report/, 'report tolerates an undef leading argument' );
        like( Developer::Dashboard::Runtime::Result::report( [1] ), qr/dashboard Run Report/, 'report ignores a reference leading argument' );
    }
    like( join( '', @warnings ), qr/Odd number of elements in hash assignment/, 'a malformed argument list is reported as an odd-elements warning' );
    like( join( '', @warnings ), qr/Reference found where even-sized list expected/, 'a reference argument is reported as a reference-found warning' );
}

# _command_name() with a root parent.
{
    my $old = File::Basename::fileparse_set_fstype('MSWin32');
    local $ENV{DEVELOPER_DASHBOARD_COMMAND} = 'fallback-cmd';
    for my $script ( '\\run', '/run' ) {
        local $0 = $script;
        is( Developer::Dashboard::Runtime::Result::_command_name(), 'fallback-cmd', "a run wrapper $script whose parent is a root falls back to the environment name" );
    }
    File::Basename::fileparse_set_fstype($old);
}

done_testing;

__END__

=pod

=head1 NAME

t/710-runtime-result-coverage.t - failure-injection coverage for Developer::Dashboard::Runtime::Result

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It drives the RESULT channel error branches (chmod, fcntl, truncate, rewind and close failures, unreadable RESULT files, the /proc fd fallback and the drive-root command name) through BEGIN-time CORE::GLOBAL overrides, tied handles and stubs.

=head1 WHY IT EXISTS

It exists because lib/ must reach 100 percent Devel::Cover coverage with no uncoverable annotations, and these branches only run when a system call fails, which cannot be forced with file permissions when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change the RESULT channel helpers in Runtime::Result, or when a coverage run reports one of their error branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/710-runtime-result-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/710-runtime-result-coverage.t

Run this coverage-gap test by itself while editing Runtime::Result.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/710-runtime-result-coverage.t

Confirm the failure branches are reported as covered.

=cut
