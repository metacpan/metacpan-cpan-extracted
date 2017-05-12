#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package IO::Async::Loop::AnyEvent;

use strict;
use warnings;

our $VERSION = '0.03';
use constant API_VERSION => '0.33';

# Force AnyEvent to detect a suitable model now, before we load
# IO::Async::Loop. Otherwise, AnyEvent will use AnyEvent::Impl::IOAsync
# which causes a circular dependency at runtime, leading to such problems as:
#
#   Deep recursion on subroutine "AnyEvent::Impl::IOAsync::io" at ...

use AnyEvent;
BEGIN { AnyEvent::detect() }

use parent qw( IO::Async::Loop );

use Carp;

use constant ANYEVENT_6 => $AnyEvent::VERSION >= 6;

=head1 NAME

C<IO::Async::Loop::AnyEvent> - use C<IO::Async> with C<AnyEvent>

=head1 SYNOPSIS

 use IO::Async::Loop::AnyEvent;

 my $loop = IO::Async::Loop::AnyEvent->new();

 $loop->add( ... );

 $loop->add( IO::Async::Signal->new(
       name => 'HUP',
       on_receipt => sub { ... },
 ) );

 $loop->loop_forever();

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses L<AnyEvent> to perform its work.

=head1 CONSTRUCTOR

=cut

=head2 $loop = IO::Async::Loop::AnyEvent->new

This function returns a new instance of a C<IO::Async::Loop::AnyEvent> object.

=cut

sub new
{
   my $class = shift;
   my ( %args ) = @_;

   my $self = $class->SUPER::__new( %args );

   $self->{$_} = {} for qw( watch_r watch_w watch_time watch_signal watch_idle watch_child);

   return $self;
}

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   my $cv = AnyEvent->condvar;
   my $w;

   if( defined $timeout ) {
      $w = AnyEvent->timer( after => $timeout, cb => sub { $cv->send } );
   }

   if( ANYEVENT_6 ) {
      # This method isn't technically documented by AnyEvent
      AnyEvent->_poll;
   }
   else {
      # This method isn't technically documented by AnyEvent
      AnyEvent->one_event;
   }
}

sub loop_forever
{
   my $self = shift;

   ( local $self->{loop_forever_cv} = AnyEvent->condvar )->recv;
}

sub loop_stop
{
   my $self = shift;

   $self->{loop_forever_cv}->send;
}

sub watch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";

   if( my $on_read_ready = $params{on_read_ready} ) {
      $self->{watch_r}{$handle} = AnyEvent->io(
         fh   => $handle,
         poll => "r",
         cb   => $on_read_ready,
      );
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      $self->{watch_w}{$handle} = AnyEvent->io(
         fh   => $handle,
         poll => "w",
         cb   => $on_write_ready,
      );
   }
}

sub unwatch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";

   if( $params{on_read_ready} ) {
      delete $self->{watch_r}{$handle};
   }

   if( $params{on_write_ready} ) {
      delete $self->{watch_w}{$handle};
   }
}

sub enqueue_timer
{
   my $self = shift;
   my %params = @_;

   my $now = $self->time;
   my $delay = $self->_build_time( %params, now => $now ) - $now;

   my $code = $params{code} or croak "Expected 'code' as CODE ref";

   my $w = AnyEvent->timer( after => $delay, cb => $code );

   $self->{watch_time}{$w} = [ $w, $code ];
   return $w;
}

sub cancel_timer
{
   my $self = shift;
   my ( $id ) = @_;

   delete $self->{watch_time}{$id};
}

sub requeue_timer
{
   my $self = shift;
   my ( $id, %params ) = @_;

   my $code = ( delete $self->{watch_time}{$id} )->[1];
   return $self->enqueue_timer( %params, code => $code );
}

sub watch_signal
{
   my $self = shift;
   my ( $signal, $code ) = @_;

   $self->{watch_signal}{$signal} = AnyEvent->signal(
      signal => $signal,
      cb     => $code,
   );
}

sub unwatch_signal
{
   my $self = shift;
   my ( $signal ) = @_;

   delete $self->{watch_signal}{$signal};
}

sub watch_idle
{
   my $self = shift;
   my %params = @_;

   my $when = delete $params{when} or croak "Expected 'when'";

   my $code = delete $params{code} or croak "Expected 'code' as a CODE ref";

   $when eq "later" or croak "Expected 'when' to be 'later'";

   my $key;
   my $w = AnyEvent->timer(
      after => 0,
      cb    => sub {
         delete $self->{watch_idle}{$key};
         goto &$code;
      },
   );

   $key = "$w";
   $self->{watch_idle}{$key} = $w;
   return $key;
}

sub unwatch_idle
{
   my $self = shift;
   my ( $id ) = @_;

   delete $self->{watch_idle}{$id};
}

sub watch_child
{
   my $self = shift;
   my ( $pid, $code ) = @_;

   $self->{watch_child}{$pid} = AnyEvent->child( pid => $pid, cb => $code );
}

sub unwatch_child
{
   my $self = shift;
   my ( $pid ) = @_;

   delete $self->{watch_child}{$pid};
}

=head1 BUGS

=over 4

=item *

C<watch_idle> and C<unwatch_idle> don't work properly against
C<AnyEvent::Impl::IOAsync>. At least, the unit tests fail, and some scheduled
CODErefs never get executed, and sit in the internal queue of the inner-nested
C<IO::Async::Loop> that C<AnyEvent::Impl::IOAsync> itself constructed. An easy
workaround here is simply to pick another AnyEvent model, by using the
C<PERL_ANYEVENT_MODEL> environment variable.

That all said, I am honestly surprised this is the only thing that breaks,
when C<IO::Async> is nested upon C<AnyEvent> itself running atop another
C<IO::Async>.

=item *

The implementation of the C<loop_once> method requires the use of an
undocumented C<AnyEvent> method (C<one_event> before version 6, C<_poll>
thereafter). This happens to work at the time of writing, but as it is
undocumented it may be subject to change.

The C<loop_forever> method does not rely on this undocumented method, so
should be safe from upstream changes. Furthremore, if C<AnyEvent> rather than
C<IO::Async> remains ultimately in control of the runtime, by waiting on
condvars, this should not be problematic.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
