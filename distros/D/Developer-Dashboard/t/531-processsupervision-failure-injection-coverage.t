#!/usr/bin/env perl

use strict;
use warnings;

# BEGIN-time CORE::GLOBAL::open override: it fails or redirects only for exact
# registered paths, so these branches run the same for root and non-root users.
our ( %OPEN_FAIL, %OPEN_REDIRECT );

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] ) {
            my $path = $_[2];
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
}

use Test::More;
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
        is( $self->_read_process_env_marker( $real, 'DD_MARK' ), 'found', 'the marker is read from the process environment' );
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
        local $SIG{__WARN__} = sub { };
        is( $self->_read_process_env_marker( $real, 'DD_MARK' ), undef, 'an unreadable environ slurp reads as undef' );
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

Test file in the Developer Dashboard codebase. It drives the in-place overwrite cleanup, descriptor listing, environ reads and helper close-failure branches of ProcessSupervision with a BEGIN-time CORE::GLOBAL::open override that fails or redirects only registered paths.

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
