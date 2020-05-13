#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2015 -- leonerd@leonerd.org.uk

package IO::Async::Socket;

use strict;
use warnings;

our $VERSION = '0.77';

use base qw( IO::Async::Handle );

use Errno qw( EAGAIN EWOULDBLOCK EINTR );

use Carp;

=head1 NAME

C<IO::Async::Socket> - event callbacks and send buffering for a socket
filehandle

=head1 SYNOPSIS

 use IO::Async::Socket;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $socket = IO::Async::Socket->new(
    on_recv => sub {
       my ( $self, $dgram, $addr ) = @_;

       print "Received reply: $dgram\n",
       $loop->stop;
    },
    on_recv_error => sub {
       my ( $self, $errno ) = @_;
       die "Cannot recv - $errno\n";
    },
 );
 $loop->add( $socket );

 $socket->connect(
    host     => "some.host.here",
    service  => "echo",
    socktype => 'dgram',
 )->get;

 $socket->send( "A TEST DATAGRAM" );

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Handle> contains a socket filehandle. It
provides a queue of outgoing data. It invokes the C<on_recv> handler when new
data is received from the filehandle. Data may be sent to the filehandle by
calling the C<send> method.

It is primarily intended for C<SOCK_DGRAM> or C<SOCK_RAW> sockets (such as UDP
or packet-capture); for C<SOCK_STREAM> sockets (such as TCP) an instance of
L<IO::Async::Stream> is more appropriate.

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_recv $data, $addr

Invoke on receipt of a packet, datagram, or stream segment.

The C<on_recv> handler is invoked once for each packet, datagram, or stream
segment that is received. It is passed the data itself, and the sender's
address.

=head2 on_recv_error $errno

Optional. Invoked when the C<recv> method on the receiving handle fails.

=head2 on_send_error $errno

Optional. Invoked when the C<send> method on the sending handle fails.

The C<on_recv_error> and C<on_send_error> handlers are passed the value of
C<$!> at the time the error occurred. (The C<$!> variable itself, by its
nature, may have changed from the original error by the time this handler
runs so it should always use the value passed in).

If an error occurs when the corresponding error callback is not supplied, and
there is not a subclass method for it, then the C<close> method is
called instead.

=head2 on_outgoing_empty

Optional. Invoked when the sending data buffer becomes empty.

=cut

sub _init
{
   my $self = shift;

   $self->{recv_len} = 65536;

   $self->SUPER::_init( @_ );
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 read_handle => IO

The IO handle to receive from. Must implement C<fileno> and C<recv> methods.

=head2 write_handle => IO

The IO handle to send to. Must implement C<fileno> and C<send> methods.

=head2 handle => IO

Shortcut to specifying the same IO handle for both of the above.

=head2 on_recv => CODE

=head2 on_recv_error => CODE

=head2 on_outgoing_empty => CODE

=head2 on_send_error => CODE

=head2 autoflush => BOOL

Optional. If true, the C<send> method will atempt to send data to the
operating system immediately, without waiting for the loop to indicate the
filehandle is write-ready.

=head2 recv_len => INT

Optional. Sets the buffer size for C<recv> calls. Defaults to 64 KiB.

=head2 recv_all => BOOL

Optional. If true, repeatedly call C<recv> when the receiving handle first
becomes read-ready. By default this is turned off, meaning at most one
fixed-size buffer is received. If there is still more data in the kernel's
buffer, the handle will stil be readable, and will be received from again.

This behaviour allows multiple streams and sockets to be multiplexed
simultaneously, meaning that a large bulk transfer on one cannot starve other
filehandles of processing time. Turning this option on may improve bulk data
transfer rate, at the risk of delaying or stalling processing on other
filehandles.

=head2 send_all => INT

Optional. Analogous to the C<recv_all> option, but for sending. When
C<autoflush> is enabled, this option only affects deferred sending if the
initial attempt failed.

The condition requiring an C<on_recv> handler is checked at the time the
object is added to a Loop; it is allowed to create a C<IO::Async::Socket>
object with a read handle but without a C<on_recv> handler, provided that
one is later given using C<configure> before the stream is added to its
containing Loop, either directly or by being a child of another Notifier
already in a Loop, or added to one.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   for (qw( on_recv on_outgoing_empty on_recv_error on_send_error
            recv_len recv_all send_all autoflush )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   $self->SUPER::configure( %params );

   if( $self->loop and defined $self->read_handle ) {
      $self->can_event( "on_recv" ) or
         croak 'Expected either an on_recv callback or to be able to ->on_recv';
   }
}

sub _add_to_loop
{
   my $self = shift;

   if( defined $self->read_handle ) {
      $self->can_event( "on_recv" ) or
         croak 'Expected either an on_recv callback or to be able to ->on_recv';
   }

   $self->SUPER::_add_to_loop( @_ );
}

=head1 METHODS

=cut

=head2 send

   $socket->send( $data, $flags, $addr )

This method adds a segment of data to be sent, or sends it immediately,
according to the C<autoflush> parameter. C<$flags> and C<$addr> are optional.

If the C<autoflush> option is set, this method will try immediately to send
the data to the underlying filehandle, optionally using the given flags and
destination address. If this completes successfully then it will have been
sent by the time this method returns. If it fails to send, then the data is
queued as if C<autoflush> were not set, and will be flushed as normal.

=cut

sub send
{
   my $self = shift;
   my ( $data, $flags, $addr ) = @_;

   croak "Cannot send data to a Socket with no write_handle" unless my $handle = $self->write_handle;

   my $sendqueue = $self->{sendqueue} ||= [];
   push @$sendqueue, [ $data, $flags, $addr ];

   if( $self->{autoflush} ) {
      while( @$sendqueue ) {
         my ( $data, $flags, $addr ) = @{ $sendqueue->[0] };
         my $len = $handle->send( $data, $flags, $addr );

         last if !$len; # stop on any errors and defer back to the non-autoflush path

         shift @$sendqueue;
      }

      if( !@$sendqueue ) {
         $self->want_writeready( 0 );
         return;
      }
   }

   $self->want_writeready( 1 );
}

sub on_read_ready
{
   my $self = shift;

   my $handle = $self->read_handle;

   while(1) {
      my $addr = $handle->recv( my $data, $self->{recv_len} );

      if( !defined $addr ) {
         return if $! == EAGAIN || $! == EWOULDBLOCK || $! == EINTR;

         my $errno = $!;

         $self->maybe_invoke_event( on_recv_error => $errno )
            or $self->close;

         return;
      }

      if( !length $data ) {
         $self->close;
         return;
      }

      $self->invoke_event( on_recv => $data, $addr );

      last unless $self->{recv_all};
   }
}

sub on_write_ready
{
   my $self = shift;

   my $handle = $self->write_handle;

   my $sendqueue = $self->{sendqueue};

   while( $sendqueue and @$sendqueue ) {
      my ( $data, $flags, $addr ) = @{ shift @$sendqueue };
      my $len = $handle->send( $data, $flags, $addr );

      if( !defined $len ) {
         return if $! == EAGAIN || $! == EWOULDBLOCK || $! == EINTR;

         my $errno = $!;

         $self->maybe_invoke_event( on_send_error => $errno )
            or $self->close;

         return;
      }

      if( $len == 0 ) {
         $self->close;
         return;
      }

      last unless $self->{send_all};
   }

   if( !$sendqueue or !@$sendqueue ) {
      $self->want_writeready( 0 );

      $self->maybe_invoke_event( on_outgoing_empty => );
   }
}

=head1 EXAMPLES

=head2 Send-first on a UDP Socket

C<UDP> is carried by the C<SOCK_DGRAM> socket type, for which the string
C<'dgram'> is a convenient shortcut:

 $socket->connect(
    host     => $hostname,
    service  => $service,
    socktype => 'dgram',
    ...
 )

=head2 Receive-first on a UDP Socket

A typical server pattern with C<UDP> involves binding a well-known port
number instead of connecting to one, and waiting on incoming packets.

 $socket->bind(
    service  => 12345,
    socktype => 'dgram',
 )->get;

=head1 SEE ALSO

=over 4

=item *

L<IO::Handle> - Supply object methods for I/O handles

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
