#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package IO::Async::Loop::UV;

use strict;
use warnings;

use Carp;

our $VERSION = '0.01';
use constant API_VERSION => '0.49';

use base qw( IO::Async::Loop );
IO::Async::Loop->VERSION( '0.49' );

use UV;

=head1 NAME

C<IO::Async::Loop::UV> - use C<IO::Async> with C<UV>

=head1 SYNOPSIS

 use IO::Async::Loop::UV;

 my $loop = IO::Async::Loop::UV->new();

 $loop->add( ... );

 $loop->add( IO::Async::Signal->new(
       name => 'HUP',
       on_receipt => sub { ... },
 ) );

 $loop->loop_forever();

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses L<UV> to perform its work.

As both C<UV> and the underlying F<libuv> are quite new, this module currently
has a few shortcomings and limitations. See the L</BUGS> section.

=cut

sub new
{
   my $class = shift;
   my $self = $class->SUPER::__new( @_ );

   return $self;
}

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   $timeout = 0 if keys %{ $self->{idles} };

   my $timer;
   if( defined $timeout ) {
      $timer = UV::timer_init();
      UV::timer_start( $timer, $timeout * 1000, 0, sub {} );
   }

   UV::run( UV::RUN_ONCE );

   UV::timer_stop( $timer ) if $timer;
}

sub watch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";
   my $state = $self->{fh}{$handle} ||= {
      mask => 0,
   };

   # UV has a thing it calls "handles". They're not filehandles, they're
   # something else
   my $uvh = $state->{uvh} ||= UV::poll_init( $handle->fileno );

   if( my $on_read_ready = $params{on_read_ready} ) {
      $state->{on_read_ready} = $on_read_ready;
      $state->{mask} |= UV::READABLE;
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      $state->{on_write_ready} = $on_write_ready;
      $state->{mask} |= UV::WRITABLE;
   }

   my $cb = $self->{fh_cb}{$handle} ||= sub {
      my ( $status, $events ) = @_;
      if( my $cb = $state->{on_read_ready} ) {
         $cb->() if $events & UV::READABLE or $status == -1;
      }
      if( my $cb = $state->{on_write_ready} ) {
         $cb->() if $events & UV::WRITABLE or $status == -1;
      }
   };

   UV::poll_start( $uvh, $state->{mask}, $cb );
}

sub unwatch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";
   my $state = $self->{fh}{$handle} or return;
   my $uvh = $state->{uvh};

   if( $params{on_read_ready} ) {
      $state->{mask} &= ~UV::READABLE;
      undef $state->{on_read_ready};
   }

   if( $params{on_write_ready} ) {
      $state->{mask} &= ~UV::WRITABLE;
      undef $state->{on_write_ready};
   }

   if( $state->{mask} ) {
      UV::poll_start( $uvh, $state->{mask}, $self->{fh_cb}{$handle} );
   }
   else {
      delete $self->{fh}{$handle};
      delete $self->{fh_cb}{$handle};
      UV::close( $uvh );
   }
}

sub watch_time
{
   my $self = shift;
   my %params = @_;

   my $code = $params{code} or croak "Expected 'code' as CODE ref";
   my $now = $params{now} || $self->time;
   my $delay = $params{after} || ( $params{at} - $now );

   $delay = 0 if $delay < 0;

   my $timer = UV::timer_init;
   UV::timer_start( $timer, $delay * 1000, 0, $code );

   return $timer;
}

sub unwatch_time
{
   my $self = shift;
   my ( $timer ) = @_;

   UV::close( $timer );
}

sub watch_idle
{
   my $self = shift;
   my %params = @_;

   my $when = delete $params{when} or croak "Expected 'when'";

   my $code = delete $params{code} or croak "Expected 'code' as a CODE ref";

   $when eq "later" or croak "Expected 'when' to be 'later'";

   my $idles = $self->{idles} ||= {};
   my $idle = UV::idle_init();
   $idles->{$idle}++;
   UV::idle_start( $idle, sub {
      UV::close( $idle );
      delete $idles->{$idle};
      $code->();
   } );

   return $idle;
}

sub unwatch_idle
{
   my $self = shift;
   my ( $idle ) = @_;

   UV::close( $idle );
   delete $self->{idles}{$idle};
}

=head1 BUGS

=over 2

=item *

F<libuv> does not provide a way to inspect the C<POLLUP> status bit, so some
types of file descriptor cannot provide EOF condition. This causes a unit-test
failure.

=item *

F<libuv> attempts to invoke a close callback when closing watch handles, even
if one is not defined. This causes the next C<UV::run_once()> call after a
handle has been closed to always return immediately. This should not cause a
problem in practice, but does cause a unit-test failure.

=item *

L<UV> does not wrap signal or child-process watch abilities of F<libuv>, so
these are currently emulated by the Loop's built-in signal-pipe mechanism.
Because of this, signal or child-process watching cannot be shared by both
C<IO::Async> and C<UV>-using code at the same time.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
