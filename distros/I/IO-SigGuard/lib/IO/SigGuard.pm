package IO::SigGuard;

=encoding utf-8

=head1 NAME

IO::SigGuard - SA_RESTART in pure Perl

=head1 SYNOPSIS

    IO::SigGuard::sysread( $fh, $buf, $size );
    IO::SigGuard::sysread( $fh, $buf, $size, $offset );

    IO::SigGuard::syswrite( $fh, $buf );
    IO::SigGuard::syswrite( $fh, $buf, $len );
    IO::SigGuard::syswrite( $fh, $buf, $len, $offset );

    IO::SigGuard::select( $read, $write, $exc, $timeout );

=head1 DESCRIPTION

C<perldoc perlipc> describes how Perl versions from 5.8.0 onward disable
the OS’s SA_RESTART flag when installing Perl signal handlers.

This module imitates that pattern in pure Perl: it does an automatic
restart when a signal interrupts an operation so you can avoid
the generally-useless EINTR error when using
C<sysread()>, C<syswrite()>, and C<select()>.

=head1 ABOUT C<sysread()> and C<syswrite()>

Other than that you’ll never see EINTR and that
there are no function prototypes used (i.e., you need parentheses on
all invocations), C<sysread()> and C<syswrite()>
work exactly the same as Perl’s equivalent built-ins.

=head1 ABOUT C<select()>

To handle EINTR, C<IO::SigGuard::select()> has to subtract the elapsed time
from the given timeout then repeat the internal C<select()>. Because
the C<select()> built-in’s C<$timeleft> return is not reliable across
all platforms, we have to compute the elapsed time ourselves. By default the
only means of doing this is the C<time()> built-in, which can only measure
individual seconds.

This works, but there are two ways to make it more accurate:

=over

=item * Have L<Time::HiRes> loaded, and C<IO::SigGuard::select()> will use that
module rather than the C<time()> built-in.

=item * Set C<$IO::SigGuard::TIME_CR> to a compatible code reference. This is
useful, e.g., if you have your own logic to do the equivalent of
L<Time::HiRes>—for example, in Linux you may prefer to call the C<gettimeofday>
system call directly from Perl to avoid L<Time::HiRes>’s XS overhead.

=back

In scalar contact, C<IO::SigGuard::select()> is a drop-in replacement
for Perl’s 4-argument built-in.

In list context, there may be discrepancies re the C<$timeleft> value
that Perl returns from a call to C<select>. As per Perl’s documentation
this value is generally not reliable anyway, though, so that shouldn’t be a
big deal. In fact, on systems like MacOS where the built-in’s C<$timeleft>
is completely useless, IO::SigGuard’s return is actually B<better> since it
does provide at least a rough estimate of how much of the given timeout value
is left.

See C<perlport> for portability notes for C<select>.

=head1 TODO

This pattern could probably be extended to C<send>, C<recv>, C<flock>, and
other system calls that can receive EINTR. If there’s a desire for that I’ll
consider adding it.

=cut

use strict;
use warnings;

our $VERSION = '0.022';

#Set this in lieu of using Time::HiRes or built-in time().
our $TIME_CR;

#As light as possible …

my $read;

sub sysread {
  READ: {
        $read = ( (@_ == 3) ? CORE::sysread( $_[0], $_[1], $_[2] ) : (@_ == 4) ? CORE::sysread( $_[0], $_[1], $_[2], $_[3] ) : die "Wrong args count! (@_)" ) or do {
            if ($!) {
                redo READ if $!{'EINTR'};
            }
        };
    }

    return $read;
}

my $wrote;

sub syswrite {
    $wrote = 0;

  WRITE: {
        $wrote += ( (@_ == 2) ? CORE::syswrite( $_[0], $_[1], length($_[1]) - $wrote, $wrote ) : (@_ == 3) ? CORE::syswrite( $_[0], $_[1], $_[2] - $wrote, $wrote ) : (@_ == 4) ? CORE::syswrite( $_[0], $_[1], $_[2] - $wrote, $_[3] + $wrote ) : die "Wrong args count! (@_)" ) || do {
            if ($!) {
                redo WRITE if $!{'EINTR'};  #EINTR => file pointer unchanged
                return undef;
            }

            die "empty write without error??";  #unexpected!
        };
    }

    return $wrote;
}

my ($start, $last_loop_time, $os_error, $nfound, $timeleft, $timer_cr);

#pre-5.16 didn’t have \&CORE::time.
sub _time { time }

sub select {
    die( (caller 0)[3] . ' must have 4 arguments!' ) if @_ != 4;

    $os_error = $!;

    $timer_cr = $TIME_CR || Time::HiRes->can('time') || \&_time;

    $start = $timer_cr->();
    $last_loop_time = $start;

  SELECT: {
        ($nfound, $timeleft) = CORE::select( $_[0], $_[1], $_[2], $_[3] - $last_loop_time + $start );
        if ($nfound == -1) {

            #Use of %! will autoload Errno.pm,
            #which can affect the value of $!.
            my $select_error = $!;

            if ($!{'EINTR'}) {
                $last_loop_time = $timer_cr->();
                redo SELECT;
            }

            $! = $select_error;
        }
        else {

            #select() doesn’t set $! on success, so let’s not clobber what
            #value was there before.
            $! = $os_error;
        }

        return wantarray ? ($nfound, $timeleft) : $nfound;
    }
}

=head1 REPOSITORY

L<https://github.com/FGasper/p5-IO-SigGuard>

=head1 AUTHOR

Felipe Gasper (FELIPE)

… with special thanks to Mario Roy (MARIOROY) for extra testing
and a few fixes/improvements.

=head1 COPYRIGHT

Copyright 2017 by L<Gasper Software Consulting|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.

=cut

1;
