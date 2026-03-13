#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2026 -- leonerd@leonerd.org.uk

package Future::IO::ImplBase 0.23;

use v5.14;
use warnings;

use Future::IO qw( POLLIN POLLOUT POLLPRI );

use Errno qw( EAGAIN EWOULDBLOCK EINPROGRESS );
use Socket qw( SOL_SOCKET SO_ERROR );
use Struct::Dumb qw( readonly_struct );
use Time::HiRes qw( time );

# connect() yields EWOULDBLOCK on MSWin32
use constant CONNECT_EWOULDBLOCK => ( $^O eq "MSWin32" );

use constant HAVE_MULTIPLE_FILEHANDLES => 1;

=head1 NAME

C<Future::IO::ImplBase> - base class for C<Future::IO> implementations

=head1 DESCRIPTION

This package provides a few utility methods that may help writing actual
L<Future::IO> implementation classes. It is entirely optional; implementations
are not required to use it.

=cut

=head1 CLASS METHODS

=cut

=head2 APPLY

   __PACKAGE__->APPLY;

Attempts to set the value of the C<$Future::IO::IMPL> variable to the name of
the calling package.

=cut

sub APPLY
{
   my $pkg = shift;

   no warnings 'once';
   ( $Future::IO::IMPL //= $pkg ) eq $pkg or
      warn "Unable to set Future::IO implementation to $pkg".
         " as it is already $Future::IO::IMPL\n";
}

=head1 DEFAULT METHODS

These methods are provided based on lower-level functionallity that the
implementing class should provide.

=cut

=head2 accept

Implemented by wrapping C<poll(POLLIN)>, as L</sysread> uses.

=cut

sub accept
{
   my $self = shift;
   my ( $fh ) = @_;

   return $self->poll( $fh, POLLIN )->then( sub {
      my $accepted = $fh->accept;
      if( $accepted ) {
         return Future->done( $accepted );
      }
      else {
         return Future->fail( "accept: $!\n", accept => $fh, $! );
      }
   } );
}

=head2 alarm

Implemented by wrapping C<sleep>.

=cut

sub alarm
{
   my $self = shift;
   my ( $time ) = @_;

   return $self->sleep( $time - time() );
}

=head2 connect

Implemented by wrapping C<poll(POLLOUT)>, as L</syswrite> uses.

=cut

sub connect
{
   my $self = shift;
   my ( $fh, $name ) = @_;

   # We can't use IO::Socket->connect here because
   #   https://github.com/Perl/perl5/issues/19326

   my $ret = CORE::connect( $fh, $name );
   my $errno = $!;

   return Future->done if $ret;

   unless( $errno == EINPROGRESS or
         ( CONNECT_EWOULDBLOCK and $errno == EWOULDBLOCK ) ) {
      return Future->fail( "connect: $errno\n", connect => $fh, $errno );
   }

   # not synchronous result

   return $self->poll( $fh, POLLOUT|POLLPRI )->then( sub {
      $errno = $fh->getsockopt( SOL_SOCKET, SO_ERROR );

      if( $errno ) {
         $! = $errno;
         return Future->fail( "connect: $!\n", connect => $fh, $! );
      }

      return Future->done;
   } );
}

=head2 recv

=head2 recvfrom

Implemented by wrapping C<poll(POLLIN)>, as L</sysread> uses.

=cut

sub _recv1
{
   my $self = shift;
   my ( $f, $with_fromaddr, $fh, $length, $flags ) = @_;

   my $waitf = $self->poll( $fh, POLLIN )->on_done( sub {
      my $fromaddr = $fh->recv( my $buf, $length, $flags );
      if( defined $fromaddr and length $buf ) {
         $f->done( $buf, $with_fromaddr ? ( $fromaddr ) : () );
      }
      elsif( defined $fromaddr ) {
         $f->done(); # fromaddr is not interesting at EOF
      }
      elsif( $! == EAGAIN or $! == EWOULDBLOCK ) {
         # Try again
         $self->_recv1( $f, $with_fromaddr, $fh, $length, $flags );
      }
      else {
         my $name = $with_fromaddr ? "recvfrom" : "recv";
         $f->fail( "$name: $!\n", $name => $fh, $! );
      }
   });

   $f //= $waitf->new;

   $f->on_cancel( $waitf );

   return $f;
}

sub recv
{
   my $self = shift;
   return $self->_recv1( undef, 0, @_ );
}

sub recvfrom
{
   my $self = shift;
   return $self->_recv1( undef, 1, @_ );
}

=head2 send

Implemented by wrapping C<poll(POLLOUT)>, as L</syswrite> uses.

=cut

sub _send1
{
   my $self = shift;
   my ( $f, $fh, $data, $flags, $to ) = @_;

   my $waitf = $self->poll( $fh, POLLOUT )->on_done( sub {
      my $len;
      # IO::Socket->send itself might die
      my $e = eval { $len = $fh->send( $data, $flags, $to ); 1 } ? undef : $@;

      if( defined $e ) {
         $f->fail( "send: $e\n", send => $fh, $! );
      }
      elsif( defined $len ) {
         $f->done( $len );
      }
      elsif( $! == EAGAIN or $! == EWOULDBLOCK ) {
         # Try again
         $self->_send1( $f, $fh, $data, $flags, $to );
      }
      else {
         $f->fail( "send: $!\n", send => $fh, $! );
      }
   } );

   $f //= $waitf->new;

   $f->on_cancel( $waitf );

   return $f;
}

sub send
{
   my $self = shift;
   return $self->_send1( undef, @_ );
}

=head2 sysread

Requires a lower-level method

   $f = $class->poll( $fh, POLLIN );

which should return a Future that completes when the given filehandle may be
ready for reading.

=cut

sub _sysread1
{
   my $self = shift;
   my ( $f, $fh, $length ) = @_;

   my $waitf = $self->poll( $fh, POLLIN )->on_done( sub {
      my $ret = $fh->sysread( my $buf, $length );
      if( $ret ) {
         $f->done( $buf );
      }
      elsif( defined $ret ) {
         # EOF
         $f->done();
      }
      elsif( $! == EAGAIN or $! == EWOULDBLOCK ) {
         # Try again
         $self->_sysread1( $f, $fh, $length );
      }
      else {
         $f->fail( "sysread: $!\n", sysread => $fh, $! );
      }
   });

   $f //= $waitf->new;

   $f->on_cancel( $waitf );

   return $f;
}

sub sysread
{
   my $self = shift;
   return $self->_sysread1( undef, @_ );
}

=head2 syswrite

Requires a lower-level method

   $f = $class->poll( $fh, POLLOUT );

which should return a Future that completes when the given filehandle may be
ready for writing.

=cut

sub _syswrite1
{
   my $self = shift;
   my ( $f, $fh, $data ) = @_;

   my $waitf = $self->poll( $fh, POLLOUT )->on_done( sub {
      my $len = $fh->syswrite( $data );
      if( defined $len ) {
         $f->done( $len );
      }
      elsif( $! == EAGAIN or $! == EWOULDBLOCK ) {
         # Try again
         $self->_syswrite1( $f, $fh, $data );
      }
      else {
         $f->fail( "syswrite: $!\n", syswrite => $fh, $! );
      }
   });

   $f //= $waitf->new;

   $f->on_cancel( $waitf );

   return $f;
}

sub syswrite
{
   my $self = shift;
   return $self->_syswrite1( undef, @_ );
}

=head1 OPTIONAL METHODS

The following methods may be directly provided by an implementation, or they
may be emulated by this base class by other means. It is usually better to
provide these methods in an implementation if it can do so more efficiently or
better in those modules; these emulations are provided as a worst-case
fallback and may not be ideal.

These methods will require a helper method provided by the implementation
class to construct new C<Future> instances of its chosen type.

   $f = $class->_new_future;

=cut

=head2 sleep

I<Since version 0.22.>

Emulated by maintaining a queue of C<sleep> and C<alarm> timers. Two helper
methods are provided for the implementation to manage this queue.

   $timeout = $class->_timeout;

   $class->_manage_timers;

The C<_timeout> method returns a value in seconds to the delay until when the
next timer will expire. This may be C<undef> if there are none waiting. The
C<_manage_timers> method may be called at any time to invoke any of the timers
that have now expired.

=cut

readonly_struct Alarm => [qw( time f )];
my @alarms;
my $cancelled_alarms;

sub _timeout
{
   shift;

   my $timeout;

   ( shift @alarms, $cancelled_alarms-- )
      while @alarms and $alarms[0]->f->is_cancelled;

   if( @alarms ) {
      # These are sorted by time order, so head is soonest
      $timeout = $alarms[0]->time - time();
      $timeout = 0 if $timeout < 0;
   }

   return $timeout;
}

sub _manage_timers
{
   shift;
   my $now = time();

   while( @alarms ) {
      last if $alarms[0]->time > $now;

      my $f = ( shift @alarms )->f;

      $cancelled_alarms--, next if $f->is_cancelled;
      $f->done;
   }
}

sub _compact_alarms
{
   @alarms = grep { !$_->f->is_cancelled } @alarms;
   $cancelled_alarms = 0;
}

sub sleep
{
   my $class = shift;
   my ( $secs ) = @_;

   my $time = time() + $secs;

   my $f = $class->_new_future;
   my $alarm = Alarm( $time, $f );

   if( !@alarms or $time >= $alarms[-1]->time ) {
      # Quick path, just push it on the end
      push @alarms, $alarm;
   }
   else {
      # Need to find the right point to splice() it into. It's more likely
      # that the new alarm goes at the end of the queue so start our search
      # there.
      # This isn't a full binary search but a good compromise between fast
      # performance and simple to write.
      my $idx = $#alarms;
      $idx = int( $idx/2 ) while $idx > 0 and $alarms[$idx]->time > $time;
      $idx++ while $idx < @alarms and $alarms[$idx]->time < $time;

      splice @alarms, $idx, 0, $alarm;
   }

   $f->on_cancel( sub {
      $cancelled_alarms++;

       _compact_alarms
         if $cancelled_alarms >= 5 and $cancelled_alarms > @alarms/2;
   } );

   return $f;
}

=head1 LEGACY METHODS

The following methods are not considered part of the official C<Future::IO>
implementation API, and should not be relied upon when writing new code.
However, existing code may still exist that uses them so for now they are
provided as wrappers.

Later versions of this module may start printing deprecation warnings on these
methods, so existing code ought to be updated to use the newer forms now.

=cut

=head2 ready_for_read

=head2 ready_for_write

   $f = $class->ready_for_read( $fh );

   $f = $class->ready_for_write( $fh );

Implemented by wrapping C<poll> by passing in the C<POLLIN> or C<POLLOUT>
flags respectively.

=cut

sub ready_for_read
{
   my $self = shift;
   my ( $fh ) = @_;

   return $self->poll( $fh, POLLIN );
   # TODO: should we check the result before yielding?
}

sub ready_for_write
{
   my $self = shift;
   my ( $fh ) = @_;

   return $self->poll( $fh, POLLOUT );
   # TODO: should we check the result before yielding?
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
