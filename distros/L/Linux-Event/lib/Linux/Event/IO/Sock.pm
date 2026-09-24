package Linux::Event::IO::Sock;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

1;

__END__

=head1 NAME

Linux::Event::IO::Sock - Socket resources in Linux::Event

=head1 SYNOPSIS

Choose the socket object that matches the job:

  use Linux::Event::IO::Sock::Stream;
  use Linux::Event::IO::Sock::Listener;
  use Linux::Event::IO::Sock::Dgram;

=head1 DESCRIPTION

C<Linux::Event::IO::Sock> is the namespace for Linux::Event socket resources.

It is a category, not a socket object itself.

Applications normally use one of three concrete classes:

  Stream
  Listener
  Dgram

The choice describes the socket's I/O semantics.

IPv4, IPv6, and Unix-domain sockets do not require separate Linux::Event
classes.

=head1 STREAM

L<Linux::Event::IO::Sock::Stream> represents one connected C<SOCK_STREAM>
socket.

Use it for:

  TCP client connections
  TCP connections accepted by a Listener
  Unix-domain stream connections
  already-connected stream sockets adopted from other code

For example:

  my $stream = Linux::Event::IO::Sock::Stream->connect(
      loop => $loop,
      host => 'example.com',
      port => 1234,

      on_ready => sub ($self) {
          $self->write("hello");
      },

      on_data => sub ($self, $bytes) {
          ...
      },
  );

A Stream presents ordered bytes.

TCP packet boundaries and individual peer C<write> calls do not become
application message boundaries.

Protocols that need messages can use L<Linux::Event::Framer>.

=head1 LISTENER

L<Linux::Event::IO::Sock::Listener> represents a listening C<SOCK_STREAM>
socket.

Its job is to accept incoming connections and create Stream objects for them.

For example:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 5000,

      stream => {
          on_data => sub ($self, $bytes) {
              $self->write($bytes);
          },
      },
  );

The Listener manages accepting connections.

The accepted Stream manages the actual connection I/O.

This separation keeps listening-socket policy and per-connection protocol state
distinct.

=head1 DATAGRAM

L<Linux::Event::IO::Sock::Dgram> represents a C<SOCK_DGRAM> socket.

Use it for:

  UDP
  Unix-domain datagram sockets

For example:

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 9999,

      on_datagram => sub ($self, $payload, $peer) {
          $self->send(
              "reply",
              to => $peer,
          );
      },
  );

Unlike a Stream, a Datagram preserves packet boundaries.

One received packet becomes one C<on_datagram> callback.

One accepted C<send> represents one complete outbound datagram.

=head1 STREAM AND DATAGRAM ARE DIFFERENT MODELS

The distinction between Stream and Datagram is fundamental.

A Stream provides:

  ordered bytes
  connection lifecycle
  EOF and half-close behavior
  optional framing
  optional TLS

A Datagram provides:

  individual packets
  sender addresses
  no ordered-byte EOF model
  no Stream framing layer
  no Stream TLS transport

Do not choose between them based only on whether the address is IPv4, IPv6, or
Unix-domain.

Choose based on the socket semantics required by the protocol.

=head1 ADDRESS FAMILY IS CONFIGURATION

Linux::Event does not define separate public classes such as:

  IPv4Stream
  IPv6Stream
  UnixStream

Instead, one Stream class can connect using:

  host => '192.0.2.10',
  port => 1234

or:

  host => '2001:db8::10',
  port => 1234

or:

  unix => '/run/service.sock'

Likewise, Listener and Datagram support the address families appropriate to
their socket type.

This keeps the Perl class hierarchy focused on behavior rather than duplicating
the same I/O model for each address family.

=head1 ADDRESSES

Socket APIs use L<Linux::Event::Address> when an already-resolved socket address
needs to be represented as a value.

For example, Datagram receive callbacks provide the sender:

  on_datagram => sub ($self, $payload, $peer) {
      if ($peer->family eq 'inet') {
          say $peer->host . ':' . $peer->port;
      }
  }

Listener accept handling also has peer-address information available for the
new connection.

Address objects preserve the native packed socket address and decode textual
fields only when requested.

=head1 CONNECTED DOES NOT ALWAYS MEAN STREAM

Both Stream and Datagram can have a C<connect> operation, but the meaning is
different.

For a Stream, connecting establishes a stream connection such as TCP.

For a Datagram, connecting tells the kernel which peer is the socket's default
destination.

A connected UDP Datagram is still packet-oriented UDP.

It does not become a reliable ordered byte stream.

=head1 TLS

TLS belongs to L<Linux::Event::IO::Sock::Stream> transport.

A Stream may therefore use TLS without becoming a separate public socket class.

For accepted server connections, TLS is normally configured in the Listener's
Stream recipe.

For example:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 443,

      stream => {
          tls => {
              cert_file => $cert_file,
              key_file  => $key_file,
          },

          on_data => sub ($self, $bytes) {
              ...
          },
      },
  );

Application Stream callbacks receive plaintext.

See L<Linux::Event::TLS> for the transport policy.

=head1 FRAMING

Framing applies to Stream because a Stream provides ordered bytes without
application message boundaries.

For example:

  package LineConnection;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $line) {
      ...
  }

Datagram does not need this framing layer because the kernel already preserves
each datagram as one packet.

=head1 ADOPTING EXISTING SOCKETS

The concrete socket classes can adopt appropriate sockets created elsewhere.

For example, a connected C<SOCK_STREAM> handle can be wrapped by:

  my $stream = Linux::Event::IO::Sock::Stream->new(
      loop => $loop,
      fh   => $socket,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

Datagram can similarly adopt an existing C<SOCK_DGRAM> socket.

Ownership rules are documented by each concrete class and should be checked
when passing handles created by other code.

=head1 LOOP ATTACHMENT

Socket resources follow the normal Linux::Event resource model.

They may commonly be created already attached:

  loop => $loop

or created detached and added later:

  my $stream = MyStream->connect(
      host => 'example.com',
      port => 1234,
      ...
  );

  $loop->add($stream);

The same object continues through its asynchronous lifecycle after attachment.

=head1 THERE IS NO GENERIC SOCK OBJECT

This is not a public construction API:

  Linux::Event::IO::Sock->new(...);

Choose the concrete socket class instead.

Use:

  Linux::Event::IO::Sock::Stream

for one connected ordered-byte socket.

Use:

  Linux::Event::IO::Sock::Listener

for accepting incoming Stream connections.

Use:

  Linux::Event::IO::Sock::Dgram

for packet-oriented datagram sockets.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::Address>,
L<Linux::Event::IO>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Sock::Listener>,
L<Linux::Event::IO::Sock::Dgram>,
L<Linux::Event::Framer>,
L<Linux::Event::TLS>.

=cut
