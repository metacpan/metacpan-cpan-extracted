#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2013 -- leonerd@leonerd.org.uk

package IO::Async::Protocol::Stream;

use strict;
use warnings;

our $VERSION = '0.77';

use base qw( IO::Async::Protocol );

use Carp;

=head1 NAME

C<IO::Async::Protocol::Stream> - base class for stream-based protocols

=head1 SYNOPSIS

Most likely this class will be subclassed to implement a particular network
protocol.

 package Net::Async::HelloWorld;

 use strict;
 use warnings;
 use base qw( IO::Async::Protocol::Stream );

 sub on_read
 {
    my $self = shift;
    my ( $buffref, $eof ) = @_;

    return 0 unless $$buffref =~ s/^(.*)\n//;
    my $line = $1;

    if( $line =~ m/^HELLO (.*)/ ) {
       my $name = $1;

       $self->invoke_event( on_hello => $name );
    }

    return 1;
 }

 sub send_hello
 {
    my $self = shift;
    my ( $name ) = @_;

    $self->write( "HELLO $name\n" );
 }

This small example elides such details as error handling, which a real
protocol implementation would be likely to contain.

=head1 DESCRIPTION

This subclass of L<IO::Async::Protocol> is intended to stand as a base class
for implementing stream-based protocols. It provides an interface similar to
L<IO::Async::Stream>, primarily, a C<write> method and an C<on_read> event
handler.

It contains an instance of an L<IO::Async::Stream> object which it uses for
actual communication, rather than being a subclass of it, allowing a level of
independence from the actual stream being used. For example, the stream may
actually be an L<IO::Async::SSLStream> to allow the protocol to be used over
SSL.

As with L<IO::Async::Stream>, it is required that by the time the protocol
object is added to a Loop, that it either has an C<on_read> method, or has
been configured with an C<on_read> callback handler.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 $ret = on_read \$buffer, $eof

=head2 on_read_eof

=head2 on_write_eof

The event handlers are invoked identically to L<IO::Async::Stream>.

=head2 on_closed

The C<on_closed> handler is optional, but if provided, will be invoked after
the stream is closed by either side (either because the C<close()> method has
been invoked on it, or on an incoming EOF).

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 on_read => CODE

=head2 on_read_eof => CODE

=head2 on_write_eof => CODE

CODE references for the events.

=head2 handle => IO

A shortcut for the common case where the transport only needs to be a plain
L<IO::Async::Stream> object. If this argument is provided without a
C<transport> object, a new L<IO::Async::Stream> object will be built around
the given IO handle, and used as the transport.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   for (qw( on_read on_read_eof on_write_eof )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   if( !exists $params{transport} and my $handle = delete $params{handle} ) {
      require IO::Async::Stream;
      $params{transport} = IO::Async::Stream->new( handle => $handle );
   }

   $self->SUPER::configure( %params );

   if( $self->loop ) {
      $self->can_event( "on_read" ) or
         croak 'Expected either an on_read callback or to be able to ->on_read';
   }
}

sub _add_to_loop
{
   my $self = shift;

   $self->can_event( "on_read" ) or
      croak 'Expected either an on_read callback or to be able to ->on_read';
}

sub setup_transport
{
   my $self = shift;
   my ( $transport ) = @_;

   $self->SUPER::setup_transport( $transport );

   $transport->configure( 
      on_read => $self->_replace_weakself( sub {
         my $self = shift or return;
         $self->invoke_event( on_read => @_ );
      } ),
      on_read_eof => $self->_replace_weakself( sub {
         my $self = shift or return;
         $self->maybe_invoke_event( on_read_eof => @_ );
      } ),
      on_write_eof => $self->_replace_weakself( sub {
         my $self = shift or return;
         $self->maybe_invoke_event( on_write_eof => @_ );
      } ),
   );
}

sub teardown_transport
{
   my $self = shift;
   my ( $transport ) = @_;

   $transport->configure(
      on_read => undef,
   );

   $self->SUPER::teardown_transport( $transport );
}

=head1 METHODS

=cut

=head2 write

   $protocol->write( $data )

Writes the given data by calling the C<write> method on the contained
transport stream.

=cut

sub write
{
   my $self = shift;
   my ( $data, %args ) = @_;

   if( ref $data eq "CODE" ) {
      $data = $self->_replace_weakself( $data );
   }

   if( $args{on_flush} ) {
      $args{on_flush} = $self->_replace_weakself( $args{on_flush} );
   }

   my $transport = $self->transport or croak "Attempted to ->write to a ".ref($self)." with no transport";
   $transport->write( $data, %args );
}

=head2 connect

   $protocol->connect( %args )

Sets up a connection to a peer, and configures the underlying C<transport> for
the Protocol. Calls L<IO::Async::Protocol> C<connect> with C<socktype> set to
C<"stream">.

=cut

sub connect
{
   my $self = shift;
   $self->SUPER::connect(
      @_,
      socktype => "stream",
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
