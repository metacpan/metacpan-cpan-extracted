package HealthCheck::Parallel;

use v5.10;
use strict;
use warnings;

use parent 'HealthCheck';

use Carp;
use Parallel::ForkManager;
use Scalar::Util qw( weaken );

# ABSTRACT: A HealthCheck that uses parallelization for running checks
use version;
our $VERSION = 'v0.2.0'; # VERSION

sub new {
    my ( $class, %params ) = @_;

    $params{max_procs} //= 4;
    $params{timeout}   //= 120;

    my $self = $class->SUPER::new( %params );

    $self->_validate_max_procs( $params{max_procs} );
    $self->_validate_child_init( $params{child_init} );
    $self->_validate_timeout( $params{timeout} );

    return $self;
}

sub _run_checks {
    my ( $self, $checks, $params ) = @_;

    my $child_init = $params->{child_init} // $self->{child_init};
    my $tempdir    = $params->{tempdir}    // $self->{tempdir};

    $self->_validate_child_init( $child_init ) if defined $child_init;

    my $max_procs = $self->_validate_max_procs( $params->{max_procs} );
    my $timeout   = $self->_validate_timeout( $params->{timeout} );

    my @results;
    my $forker;
    my $start_time;
    my $timed_out = 0;
    my %killed_idents;
    my %pid_to_ident;
    my $last_dispatched_ident = -1;

    if ( $max_procs > 1 ) {
        $forker = Parallel::ForkManager->new(
            $max_procs,
            $tempdir ? $tempdir : (),
        );

        $forker->run_on_finish(sub {
            my ( $pid, $exit_code, $ident, $exit_sig, $core_dump, $ret ) = @_;

            delete $pid_to_ident{ $pid };

            # Child process had some error.
            if ( $exit_code != 0 ) {
                $results[ $ident ] = {
                    status => 'CRITICAL',
                    info   => "Child process exited with code $exit_code.",
                };
            }
            else {
                # Keep results in the same order that they were provided.
                $results[ $ident ] = $ret->[0];
            }
        });

        # Set up on_wait callback to check timeout during dispatch.
        # This is called periodically when start() is in its wait loop.
        $start_time = time;

        # Use weak reference to avoid circular reference between
        # $forker and the callback closure.
        my $weak_forker = $forker;
        weaken $weak_forker;

        $forker->run_on_wait(sub {
            my $elapsed = time - $start_time;

            # Check if we've exceeded timeout.
            if ( $elapsed > $timeout ) {
                $timed_out = 1;

                # Kill all children and make start() exit its wait loop.
                # Capture the idents of processes being killed so we can
                # report timeout results for them.
                my @running_pids = $weak_forker->running_procs;
                for my $pid ( @running_pids ) {
                    $killed_idents{ $pid_to_ident{ $pid } } = 1;
                }
                kill 'TERM', @running_pids;
            }
        }, 1);  # Check every 1 second
    }

    my $i = 0;
    for my $check ( @$checks ) {
        # Stop dispatching if timeout occurred.
        last if $timed_out;

        my $ident = $last_dispatched_ident = $i++;

        if ( $forker ) {
            my $pid = $forker->start( $ident );

            if ( $pid ) {
                # In parent - track this PID.
                $pid_to_ident{ $pid } = $ident;
                next;
            }

            # Need to at least call the init callback before exiting so that we
            # make sure to deal with things like FCGI cleanup.
            $child_init->() if $child_init;

            # In child - if timeout occurred while waiting to start, exit
            # immediately without running the check (start() forked before we
            # could prevent it).
            $forker->finish if $timed_out;
        }

        my @r = $self->_run_check( $check, $params );

        $forker->finish( 0, \@r ) if $forker;

        # Non-forked process.
        push @results, @r;
    }

    $forker->wait_all_children if $forker;

    # If timeout occurred, fill in timeout results for killed processes
    # and checks that never started.
    if ( $timed_out ) {
        # Add timeout results for killed processes.
        for my $ident ( keys %killed_idents ) {
            $results[ $ident ] = {
                status => 'CRITICAL',
                info   => sprintf(
                    'Check killed due to global timeout of %d seconds.',
                    $timeout,
                ),
            };
        }

        # Add timeout results for checks that were never dispatched.
        # Only fill in idents greater than the last one we actually dispatched.
        for my $ident ( $last_dispatched_ident + 1 .. @$checks - 1 ) {
            $results[ $ident ] = {
                status => 'CRITICAL',
                info   => sprintf(
                    'Check not started due to global timeout of %d seconds.',
                    $timeout,
                ),
            };
        }
    }

    return @results;
}

sub _resolve_value {
    my ( $self, $value ) = @_;

    return ref $value eq 'CODE' ? $value->() : $value;
}

sub _validate_max_procs {
    my ( $self, $max_procs ) = @_;

    $max_procs = $self->{max_procs} unless defined $max_procs;

    my $value = $self->_resolve_value( $max_procs );

    croak "max_procs must be a zero or positive integer!"
        unless defined $value && $value =~ /^\d+$/;

    return $value;
}

sub _validate_child_init {
    my ( $self, $child_init ) = @_;

    croak "child_init must be a code reference!"
        if defined $child_init && ref( $child_init ) ne 'CODE';
}

sub _validate_timeout {
    my ( $self, $timeout ) = @_;

    $timeout = $self->{timeout} unless defined $timeout;

    my $value = $self->_resolve_value( $timeout );

    croak "timeout must be a positive integer!"
        unless defined $value && $value =~ /^\d+$/ && $value > 0;

    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Parallel - A HealthCheck that uses parallelization for running checks

=head1 VERSION

version v0.2.0

=head1 SYNOPSIS

    use HealthCheck::Parallel;

    my $hc = HealthCheck::Parallel->new(
        max_procs  => 4,      # default
        timeout    => 120,    # default, global timeout in seconds
        tempdir    => '/tmp', # override Parallel::ForkManager default
        child_init => sub { warn "Will run at start of child process check" },
        checks     => [
            sub { sleep 5; return { id => 'slow1', status => 'OK' } },
            sub { sleep 5; return { id => 'slow2', status => 'OK' } },
        ],
    );

    # Takes 5 seconds to run both checks instead of 10.
    my $res = $hc->check;

    # These checks will not use parallelization.
    $res = $hc->check( max_procs => 0 );

    # Neither will these.
    $res = $hc->check( max_procs => 1 );

    # Override timeout for specific check.
    $res = $hc->check( timeout => 60 );

=head1 DESCRIPTION

This library inherits L<HealthCheck> so that the provided checks are run in
parallel.

=head1 METHODS

=head2 new

Overrides the L<HealthCheck/new> constructor to additionally allow
L</max_procs> and L</timeout> arguments for controlling parallelization
and global timeout behavior.

=head1 ATTRIBUTES

=head2 max_procs

A positive integer (or coderef returning one) specifying the maximum number of
processes that should be run in parallel when executing the checks.
No parallelization will be used unless given a value that is greater than 1.
Defaults to 4.

If provided as a coderef, it will be called at runtime to determine the value,
allowing dynamic adjustment:

    my $hc = HealthCheck::Parallel->new(
        max_procs => sub { int(rand(10)) },
        checks    => [ ... ],
    );

=head2 child_init

An optional coderef which will be run when the child process of a check is
created.
A possible important use case is making sure child processes don't try to make
use of STDOUT if these checks are running under FastCGI envrionment:

    my $hc = HealthCheck::Parallel->new(
        child_init => sub {
            untie *STDOUT;
            { no warnings; *FCGI::DESTROY = sub {}; }
        },
    );

=head2 tempdir

Sets the C<tempdir> value to use in L<Parallel::ForkManager> for IPC.

=head2 timeout

A positive integer (or coderef returning one) specifying the maximum number of
seconds to wait for all parallelized checks to complete.
If the timeout is exceeded, all running child processes will be terminated
and CRITICAL results will be returned for affected checks.
Defaults to 120 seconds.

If provided as a coderef, it will be called at runtime to determine the value,
allowing dynamic adjustment:

    my $hc = HealthCheck::Parallel->new(
        timeout => sub { int(rand(10)) },
        checks  => [ ... ],
    );

B<Note:> The timeout only applies when parallelization is enabled
(C<max_procs E<gt> 1>). When C<max_procs> is 0 or 1, checks run in the parent
process and the timeout is not used.

The timeout is implemented using a non-blocking polling loop instead of using
any signal-based timeouts to potentially avoiding conflicting with others.

=head1 DEPENDENCIES

=over 4

=item *

Perl 5.10 or higher.

=item *

L<HealthCheck>

=item *

L<Parallel::ForkManager>

=back

=head1 SEE ALSO

=over 4

=item *

L<HealthCheck::Diagnostic>

=item *

The GSG
L<Health Check Standard|https://grantstreetgroup.github.io/HealthCheck.html>.

=back

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 - 2025 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
