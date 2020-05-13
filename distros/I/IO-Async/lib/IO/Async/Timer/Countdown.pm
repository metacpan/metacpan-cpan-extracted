#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2012 -- leonerd@leonerd.org.uk

package IO::Async::Timer::Countdown;

use strict;
use warnings;
use base qw( IO::Async::Timer );

our $VERSION = '0.77';

use Carp;

=head1 NAME

C<IO::Async::Timer::Countdown> - event callback after a fixed delay

=head1 SYNOPSIS

 use IO::Async::Timer::Countdown;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $timer = IO::Async::Timer::Countdown->new(
    delay => 10,

    on_expire => sub {
       print "Sorry, your time's up\n";
       $loop->stop;
    },
 );

 $timer->start;

 $loop->add( $timer );

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Timer> implements one-shot fixed delays.
The object implements a countdown timer, which invokes its callback after the
given period from when it was started. After it has expired the Timer may be
started again, when it will wait the same period then invoke the callback
again. A timer that is currently running may be stopped or reset.

For a C<Timer> object that repeatedly runs a callback at regular intervals,
see instead L<IO::Async::Timer::Periodic>. For a C<Timer> that invokes its
callback at a fixed time in the future, see L<IO::Async::Timer::Absolute>.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_expire

Invoked when the timer expires.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 on_expire => CODE

CODE reference for the C<on_expire> event.

=head2 delay => NUM

The delay in seconds after starting the timer until it expires. Cannot be
changed if the timer is running. A timer with a zero delay expires
"immediately".

=head2 remove_on_expire => BOOL

Optional. If true, remove this timer object from its parent notifier or
containing loop when it expires. Defaults to false.

Once constructed, the timer object will need to be added to the C<Loop> before
it will work. It will also need to be started by the C<start> method.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( remove_on_expire )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   if( exists $params{on_expire} ) {
      my $on_expire = delete $params{on_expire};
      ref $on_expire or croak "Expected 'on_expire' as a reference";

      $self->{on_expire} = $on_expire;
      undef $self->{cb}; # Will be lazily constructed when needed
   }

   if( exists $params{delay} ) {
      $self->is_running and croak "Cannot configure 'delay' of a running timer\n";

      my $delay = delete $params{delay};
      $delay >= 0 or croak "Expected a 'delay' as a non-negative number";

      $self->{delay} = $delay;
   }

   unless( $self->can_event( 'on_expire' ) ) {
      croak 'Expected either a on_expire callback or an ->on_expire method';
   }

   $self->SUPER::configure( %params );
}

=head1 METHODS

=cut

=head2 is_expired

   $expired = $timer->is_expired

Returns true if the Timer has already expired.

=cut

sub is_expired
{
   my $self = shift;
   return $self->{expired};
}

sub _make_cb
{
   my $self = shift;

   return $self->_capture_weakself( sub {
      my $self = shift or return;

      undef $self->{id};
      $self->{expired} = 1;

      $self->remove_from_parent if $self->{remove_on_expire};

      $self->invoke_event( "on_expire" );
   } );
}

sub _make_enqueueargs
{
   my $self = shift;

   undef $self->{expired};
   return after => $self->{delay};
}

=head2 reset

   $timer->reset

If the timer is running, restart the countdown period from now. If the timer
is not running, this method has no effect.

=cut

sub reset
{
   my $self = shift;

   my $loop = $self->loop or croak "Cannot reset a Timer that is not in a Loop";

   return if !$self->is_running;

   $self->stop;
   $self->start;
}

=head1 EXAMPLES

=head2 Watchdog Timer

Because the C<reset> method restarts a running countdown timer back to its
full period, it can be used to implement a watchdog timer. This is a timer
which will not expire provided the method is called at least as often as it
is configured. If the method fails to be called, the timer will eventually
expire and run its callback.

For example, to expire an accepted connection after 30 seconds of inactivity:

 ...

 on_accept => sub {
    my ( $newclient ) = @_;

    my $watchdog = IO::Async::Timer::Countdown->new(
       delay => 30,

       on_expire => sub {
          my $self = shift;

          my $stream = $self->parent;
          $stream->close;
       },
    );

    my $stream = IO::Async::Stream->new(
       handle => $newclient,

       on_read => sub {
          my ( $self, $buffref, $eof ) = @_;
          $watchdog->reset;

          ...
       },

       on_closed => sub {
          $watchdog->stop;
       },
    ) );

    $stream->add_child( $watchdog );
    $watchdog->start;

    $loop->add( $watchdog );
 }

Rather than setting up a lexical variable to store the Stream so that the
Timer's C<on_expire> closure can call C<close> on it, the parent/child
relationship between the two Notifier objects is used. At the time the Timer
C<on_expire> closure is invoked, it will have been added as a child notifier
of the Stream; this means the Timer's C<parent> method will return the Stream
Notifier. This enables it to call C<close> without needing to capture a
lexical variable, which would create a cyclic reference.

=head2 Fixed-Delay Repeating Timer

The C<on_expire> event fires a fixed delay after the C<start> method has begun
the countdown. The C<start> method can be invoked again at some point during
the C<on_expire> handling code, to create a timer that invokes its code
regularly a fixed delay after the previous invocation has finished. This
creates an arrangement similar to an L<IO::Async::Timer::Periodic>, except
that it will wait until the previous invocation has indicated it is finished,
before starting the countdown for the next call.

 my $timer = IO::Async::Timer::Countdown->new(
    delay => 60,

    on_expire => sub {
       my $self = shift;

       start_some_operation(
          on_complete => sub { $self->start },
       );
    },
 );

 $timer->start;
 $loop->add( $timer );

This example invokes the C<start_some_operation> function 60 seconds after the
previous iteration has indicated it has finished.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
