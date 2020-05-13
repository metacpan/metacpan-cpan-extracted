#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2015 -- leonerd@leonerd.org.uk

package IO::Async::Timer::Periodic;

use strict;
use warnings;
use base qw( IO::Async::Timer );

our $VERSION = '0.77';

use Carp;

=head1 NAME

C<IO::Async::Timer::Periodic> - event callback at regular intervals

=head1 SYNOPSIS

 use IO::Async::Timer::Periodic;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $timer = IO::Async::Timer::Periodic->new(
    interval => 60,

    on_tick => sub {
       print "You've had a minute\n";
    },
 );

 $timer->start;

 $loop->add( $timer );

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Timer> implements repeating events at regular
clock intervals. The timing may or may not be subject to how long it takes the
callback to execute. Iterations may be rescheduled runs at fixed regular
intervals beginning at the time the timer was started, or by a fixed delay
after the previous code has finished executing.

For a C<Timer> object that only runs a callback once, after a given delay, see
instead L<IO::Async::Timer::Countdown>. A Countdown timer can also be used to
create repeating events that fire at a fixed delay after the previous event
has finished processing. See als the examples in
C<IO::Async::Timer::Countdown>.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_tick

Invoked on each interval of the timer.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 on_tick => CODE

CODE reference for the C<on_tick> event.

=head2 interval => NUM

The interval in seconds between invocations of the callback or method. Cannot
be changed if the timer is running.

=head2 first_interval => NUM

Optional. If defined, the interval in seconds after calling the C<start>
method before the first invocation of the callback or method. Thereafter, the
regular C<interval> will be used. If not supplied, the first interval will be
the same as the others.

Even if this value is zero, the first invocation will be made asynchronously,
by the containing C<Loop> object, and not synchronously by the C<start> method
itself.

=head2 reschedule => STRING

Optional. Must be one of C<hard>, C<skip> or C<drift>. Defines the algorithm
used to reschedule the next invocation.

C<hard> schedules each iteration at the fixed interval from the previous
iteration's schedule time, ensuring a regular repeating event.

C<skip> schedules similarly to C<hard>, but skips over times that have already
passed. This matters if the duration is particularly short and there's a
possibility that times may be missed, or if the entire process is stopped and
resumed by C<SIGSTOP> or similar.

C<drift> schedules each iteration at the fixed interval from the time that the
previous iteration's event handler returns. This allows it to slowly drift over
time and become desynchronised with other events of the same interval or
multiples/fractions of it.

Once constructed, the timer object will need to be added to the C<Loop> before
it will work. It will also need to be started by the C<start> method.

=cut

sub _init
{
   my $self = shift;
   $self->SUPER::_init( @_ );

   $self->{reschedule} = "hard";
}

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{on_tick} ) {
      my $on_tick = delete $params{on_tick};
      ref $on_tick or croak "Expected 'on_tick' as a reference";

      $self->{on_tick} = $on_tick;
      undef $self->{cb}; # Will be lazily constructed when needed
   }

   if( exists $params{interval} ) {
      $self->is_running and croak "Cannot configure 'interval' of a running timer\n";

      my $interval = delete $params{interval};
      $interval > 0 or croak "Expected a 'interval' as a positive number";

      $self->{interval} = $interval;
   }

   if( exists $params{first_interval} ) {
      $self->is_running and croak "Cannot configure 'first_interval' of a running timer\n";

      my $first_interval = delete $params{first_interval};
      $first_interval >= 0 or croak "Expected a 'first_interval' as a non-negative number";

      $self->{first_interval} = $first_interval;
   }

   if( exists $params{reschedule} ) {
      my $resched = delete $params{reschedule} || "hard";
      grep { $_ eq $resched } qw( hard skip drift ) or
         croak "Expected 'reschedule' to be one of hard, skip, drift";

      $self->{reschedule} = $resched;
   }

   unless( $self->can_event( 'on_tick' ) ) {
      croak 'Expected either a on_tick callback or an ->on_tick method';
   }

   $self->SUPER::configure( %params );
}

sub _reschedule
{
   my $self = shift;

   my $now = $self->loop->time;
   my $resched = $self->{reschedule};

   my $next_interval = $self->{is_first} && defined $self->{first_interval}
      ? $self->{first_interval} : $self->{interval};
   delete $self->{is_first};

   if( !defined $self->{next_time} ) {
      $self->{next_time} = $now + $next_interval;
   }
   elsif( $resched eq "hard" ) {
      $self->{next_time} += $next_interval;
   }
   elsif( $resched eq "skip" ) {
      # How many ticks are needed?
      my $ticks = POSIX::ceil( ( $now - $self->{next_time} ) / $next_interval );
      # $self->{last_ticks} = $ticks;
      $self->{next_time} += $next_interval * $ticks;
   }
   elsif( $resched eq "drift" ) {
      $self->{next_time} = $now + $next_interval;
   }

   $self->SUPER::start;
}

sub start
{
   my $self = shift;

   $self->{is_first} = 1;

   # Only actually define a time if we've got a loop; otherwise it'll just
   # become start-pending. We'll calculate it properly when it gets added to
   # the Loop
   if( $self->loop ) {
      $self->_reschedule;
   }
   else {
      $self->SUPER::start;
   }
}

sub stop
{
   my $self = shift;
   $self->SUPER::stop;

   undef $self->{next_time};
}

sub _make_cb
{
   my $self = shift;

   return $self->_capture_weakself( sub {
      my $self = shift or return;

      undef $self->{id};

      my $ok = eval { $self->invoke_event( on_tick => ); 1 } or
         my $e = $@;

      # detect ->stop
      $self->_reschedule if defined $self->{next_time};

      die $e if !$ok;
   } );
}

sub _make_enqueueargs
{
   my $self = shift;

   return at => $self->{next_time};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
