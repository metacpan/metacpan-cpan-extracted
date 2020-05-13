#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package IO::Async::Protocol;

use strict;
use warnings;

our $VERSION = '0.77';

use base qw( IO::Async::Notifier );

use Carp;

=head1 NAME

C<IO::Async::Protocol> - base class for transport-based protocols

=head1 DESCRIPTION

This subclass of L<IO::Async:Notifier> provides storage for a 
L<IO::Async::Handle> object, to act as a transport for some protocol. It
contains an instance of the transport object, which it adds as a child
notifier, allowing a level of independence from the actual transport being
used. For example, a stream may actually be an L<IO::Async::SSLStream> to
allow the protocol to be used over SSL.

This class is not intended to be used directly, instead, see one of the
subclasses

=over 4

=item L<IO::Async::Protocol::Stream> - base class for stream-based protocols

=back

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_closed

Optional. Invoked when the transport handle becomes closed.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 transport => IO::Async::Handle

The L<IO::Async::Handle> to delegate communications to.

=head2 on_closed => CODE

CODE reference for the C<on_closed> event.

When a new C<transport> object is given, it will be configured by calling the
C<setup_transport> method, then added as a child notifier. If a different
transport object was already configured, this will first be removed and
deconfigured using the C<teardown_transport>.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   for (qw( on_closed )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   if( exists $params{transport} ) {
      my $transport = delete $params{transport};

      if( $self->{transport} ) {
         $self->remove_child( $self->transport );

         $self->teardown_transport( $self->transport );
      }

      $self->{transport} = $transport;

      if( $transport ) {
         $self->setup_transport( $self->transport );

         $self->add_child( $self->transport );
      }
   }

   $self->SUPER::configure( %params );
}

=head1 METHODS

=cut

=head2 transport

   $transport = $protocol->transport

Returns the stored transport object

=cut

sub transport
{
   my $self = shift;
   return $self->{transport};
}

=head2 connect

   $protocol->connect( %args )

Sets up a connection to a peer, and configures the underlying C<transport> for
the Protocol.

Takes the following named arguments:

=over 8

=item socktype => STRING or INT

Required. Identifies the socket type, and the type of continuation that will
be used. If this value is C<"stream"> or C<SOCK_STREAM> then C<on_stream>
continuation will be used; otherwise C<on_socket> will be used.

=item on_connected => CODE

Optional. If supplied, will be invoked once the connection has been
established.

 $on_connected->( $protocol )

=item transport => IO::Async::Handle

Optional. If this is provided, it will immediately be configured as the
transport (by calling C<configure>), and the C<on_connected> callback will be
invoked. This is provided as a convenient shortcut.

=back

Other arguments will be passed to the underlying L<IO::Async::Loop> C<connect>
call.

=cut

sub connect
{
   my $self = shift;
   my %args = @_;

   my $on_connected = delete $args{on_connected};

   if( my $transport = $args{transport} ) {
      $self->configure( transport => $transport );

      $on_connected->( $self ) if $on_connected;

      return;
   }

   my $socktype = $args{socktype} or croak "Expected socktype";

   my $on_transport = do {
      no warnings 'numeric';
      $socktype eq "stream" || $socktype == Socket::SOCK_STREAM()
   } ? "on_stream" : "on_socket";

   my $loop = $self->loop or croak "Cannot ->connect a ".ref($self)." that is not in a Loop";

   $loop->connect(
      %args,
      socktype => "stream",

      $on_transport => sub {
         my ( $transport ) = @_;

         $self->configure( transport => $transport );

         $on_connected->( $self ) if $on_connected;
      },
   );
}

=head1 TRANSPORT DELEGATION

The following methods are delegated to the transport object

 close

=cut

sub close { shift->transport->close }

=head1 SUBCLASS METHODS

C<IO::Async::Protocol> is a base class provided so that specific subclasses of
it provide more specific behaviour. The base class provides a number of
methods that subclasses may wish to override.

If a subclass implements any of these, be sure to invoke the superclass method
at some point within the code.

=cut

=head2 setup_transport

   $protocol->setup_transport( $transport )

Called by C<configure> when a new C<transport> object is given, this method
should perform whatever setup is required to wire the new transport object
into the protocol object; typically by setting up event handlers.

=cut

sub setup_transport
{
   my $self = shift;
   my ( $transport ) = @_;

   $transport->configure( 
      on_closed => $self->_capture_weakself( sub {
         my $self = shift or return;
         my ( $transport ) = @_;

         $self->maybe_invoke_event( on_closed => );

         $self->configure( transport => undef );
      } ),
   );
}

=head2 teardown_transport

   $protocol->teardown_transport( $transport )

The reverse of C<setup_transport>; called by C<configure> when a previously
set-up transport object is about to be replaced.

=cut

sub teardown_transport
{
   my $self = shift;
   my ( $transport ) = @_;

   $transport->configure(
      on_closed => undef,
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
