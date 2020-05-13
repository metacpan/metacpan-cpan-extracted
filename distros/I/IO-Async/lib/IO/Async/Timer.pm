#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2012 -- leonerd@leonerd.org.uk

package IO::Async::Timer;

use strict;
use warnings;
use base qw( IO::Async::Notifier );

our $VERSION = '0.77';

use Carp;

=head1 NAME

C<IO::Async::Timer> - base class for Notifiers that use timed delays

=head1 DESCRIPTION

This module provides a subclass of L<IO::Async::Notifier> for implementing
notifiers that use timed delays. For specific implementations, see one of the
subclasses:

=over 8

=item *

L<IO::Async::Timer::Absolute> - event callback at a fixed future time

=item *

L<IO::Async::Timer::Countdown> - event callback after a fixed delay

=item *

L<IO::Async::Timer::Periodic> - event callback at regular intervals

=back

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $timer = IO::Async::Timer->new( %args )

Constructs a particular subclass of C<IO::Async::Timer> object, and returns
it. This constructor is provided for backward compatibility to older code
which doesn't use the subclasses. New code should directly construct a
subclass instead.

=over 8

=item mode => STRING

The type of timer to create. Currently the only allowed mode is C<countdown>
but more types may be added in the future.

=back

Once constructed, the C<Timer> will need to be added to the C<Loop> before it
will work. It will also need to be started by the C<start> method.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   if( my $mode = delete $args{mode} ) {
      # Might define some other modes later
      $mode eq "countdown" or croak "Expected 'mode' to be 'countdown'";

      require IO::Async::Timer::Countdown;
      return IO::Async::Timer::Countdown->new( %args );
   }

   return $class->SUPER::new( %args );
}

sub _add_to_loop
{
   my $self = shift;
   $self->start if delete $self->{pending};
}

sub _remove_from_loop
{
   my $self = shift;
   $self->stop;
}

=head1 METHODS

=cut

=head2 is_running

   $running = $timer->is_running

Returns true if the Timer has been started, and has not yet expired, or been
stopped.

=cut

sub is_running
{
   my $self = shift;

   defined $self->{id};
}

=head2 start

   $timer->start

Starts the Timer. Throws an error if it was already running.

If the Timer is not yet in a Loop, the actual start will be deferred until it
is added. Once added, it will be running, and will expire at the given
duration after the time it was added.

As a convenience, C<$timer> is returned. This may be useful for starting
timers at construction time:

 $loop->add( IO::Async::Timer->new( ... )->start );

=cut

sub start
{
   my $self = shift;

   my $loop = $self->loop;
   if( !defined $loop ) {
      $self->{pending} = 1;
      return $self;
   }

   defined $self->{id} and croak "Cannot start a Timer that is already running";

   if( !$self->{cb} ) {
      $self->{cb} = $self->_make_cb;
   }

   $self->{id} = $loop->watch_time(
      $self->_make_enqueueargs,
      code => $self->{cb},
   );

   return $self;
}

=head2 stop

   $timer->stop

Stops the Timer if it is running. If it has not yet been added to the C<Loop>
but there is a start pending, this will cancel it.

=cut

sub stop
{
   my $self = shift;

   if( $self->{pending} ) {
      delete $self->{pending};
      return;
   }

   return if !$self->is_running;

   my $loop = $self->loop or croak "Cannot stop a Timer that is not in a Loop";

   defined $self->{id} or return; # nothing to do but no error

   $loop->unwatch_time( $self->{id} );

   undef $self->{id};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
