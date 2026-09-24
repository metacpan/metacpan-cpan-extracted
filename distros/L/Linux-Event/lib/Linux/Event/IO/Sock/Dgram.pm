package Linux::Event::IO::Sock::Dgram;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use parent 'Linux::Event::_Socket::Dgram';

1;

__END__

=head1 NAME

Linux::Event::IO::Sock::Dgram - Asynchronous UDP and Unix datagram sockets

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::IO::Sock::Dgram;

  my $loop = Linux::Event::Loop->new;

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      loop => $loop,
      host => '127.0.0.1',
      port => 9999,

      on_datagram => sub ($self, $payload, $peer) {
          say "Received: $payload";

          $self->send(
              "reply",
              to => $peer,
          );
      },
  );

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::IO::Sock::Dgram> represents a datagram socket.

It supports:

=over 4

=item *

UDP over IPv4

=item *

UDP over IPv6

=item *

Unix-domain datagram sockets

=item *

bound sockets that communicate with many peers

=item *

connected datagram sockets with one default peer

=item *

already-created datagram sockets adopted from other code

=back

Unlike a Stream, a Datagram preserves packet boundaries.

One received datagram produces one C<on_datagram> callback.

One C<send> call sends one datagram.

Linux::Event does not combine separate packets into a byte stream and does not
split one accepted packet into smaller application messages.

=head1 DATAGRAMS ARE NOT STREAMS

This distinction is important.

TCP gives an ordered stream of bytes. UDP gives individual packets.

With a Stream, application message boundaries may need to be reconstructed with
a L<Linux::Event::Framer>.

With a Datagram, the kernel already preserves the packet boundary:

  packet 1
  packet 2
  packet 3

Each arrives separately.

For that reason, Stream framing and TLS policy do not apply to Datagram
objects.

=head1 CREATING A BOUND UDP SOCKET

Use C<new> to create a UDP socket that can receive packets from many peers:

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 9999,

      on_datagram => sub ($self, $payload, $peer) {
          ...
      },
  );

=head2 host

  host => '0.0.0.0'

The local address to bind.

For example:

  127.0.0.1

binds only to the local IPv4 loopback interface, while:

  0.0.0.0

requests all IPv4 interfaces.

IPv6 addresses may also be used.

=head2 port

  port => 9999

The local UDP port.

A value of zero asks the kernel to select an available port.

The selected local address can be inspected through C<local>.

=head2 loop

  loop => $loop

Attach the Datagram to a Loop immediately.

The option is optional.

A detached Datagram may instead be added later:

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      host => '127.0.0.1',
      port => 9999,
      on_datagram => sub ($self, $payload, $peer) {
          ...
      },
  );

  $loop->add($socket);

=head1 RECEIVING DATAGRAMS

=head2 on_datagram

Every Datagram requires an effective C<on_datagram> callback.

It may be supplied directly:

  on_datagram => sub ($self, $payload, $peer) {
      ...
  }

or implemented by a subclass.

The callback receives:

=over 4

=item C<$socket>

The Datagram object.

=item C<$payload>

The complete packet payload.

=item C<$peer>

A L<Linux::Event::Address> describing the sender.

=back

For example:

  on_datagram => sub ($self, $payload, $peer) {
      say "Received " . length($payload) . " bytes";
      say "From: $peer";
  }

Zero-length datagrams are valid and are delivered normally.

=head1 REPLYING TO THE SENDER

For an unconnected Datagram, specify the destination with C<to>:

  on_datagram => sub ($self, $payload, $peer) {
      $self->send(
          "Thanks",
          to => $peer,
      );
  }

The C<to> value must be a L<Linux::Event::Address>.

This makes simple request/reply UDP services straightforward because the peer
address received with a packet can be used directly for the reply.

=head1 CONNECTED DATAGRAM SOCKETS

Use C<connect> when a Datagram should have one default peer:

  my $socket = Linux::Event::IO::Sock::Dgram->connect(
      loop => $loop,
      host => 'collector.example.com',
      port => 9000,

      on_ready => sub ($self) {
          $self->send("hello");
      },

      on_datagram => sub ($self, $payload, $peer) {
          say "Received: $payload";
      },
  );

For a connected Datagram:

  $socket->send("hello");

does not require C<to>.

=head2 What connect means for UDP

UDP C<connect> is not the same kind of connection as TCP C<connect>.

It does not create a reliable byte stream, perform a handshake, or guarantee
delivery.

It tells the kernel which peer this datagram socket normally communicates with.

That gives the socket a default destination and allows:

  $socket->send($payload);

instead of:

  $socket->send($payload, to => $peer);

A connected Datagram rejects C<to> because its destination is already defined.

=head2 Hostname resolution

For connected UDP sockets, hostnames are resolved asynchronously.

For example:

  host => 'collector.example.com'

may require DNS resolution before the socket becomes ready.

Numeric IP addresses do not require hostname resolution.

=head2 on_ready

A connected Datagram may use:

  on_ready => sub ($self) {
      $self->send("hello");
  }

C<on_ready> is called when the Datagram is active and ready for application
use.

This is especially useful when C<connect> required asynchronous hostname
resolution.

=head1 UNIX-DOMAIN DATAGRAMS

A bound Unix-domain datagram socket uses C<unix>:

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      loop => $loop,
      unix => '/run/my-service.sock',

      on_datagram => sub ($self, $payload, $peer) {
          ...
      },
  );

A connected Unix-domain Datagram also uses C<unix> for its peer:

  my $socket = Linux::Event::IO::Sock::Dgram->connect(
      loop => $loop,
      unix => '/run/my-service.sock',

      on_datagram => sub ($self, $payload, $peer) {
          ...
      },
  );

A connected Unix-domain Datagram may use C<local_unix> when it needs its own
local filesystem path for replies.

=head1 SENDING DATAGRAMS

=head2 send

For a connected Datagram:

  $socket->send($payload);

For an unconnected Datagram:

  $socket->send(
      $payload,
      to => $peer,
  );

One call to C<send> represents one complete packet.

Linux::Event never intentionally breaks one accepted datagram into several
packets.

=head2 When the socket would block

If the kernel cannot send the packet immediately, Linux::Event queues the
complete datagram and retries it later.

The packet remains a packet.

It is not partially delivered to the application as though it were Stream
output.

=head2 Return value and backpressure

C<send> normally returns true while output pressure remains below the high
watermark.

When queued output grows past the high watermark, the datagram is still
accepted, but C<send> begins returning false.

That tells the application to slow down.

When the queue later drains to the low watermark, C<on_drain> is called.

=head1 OUTPUT BACKPRESSURE

For example:

  my $ok = $socket->send(
      $payload,
      to => $peer,
  );

  if (!$ok) {
      # Stop producing more packets until on_drain.
  }

Then:

  on_drain => sub ($self) {
      # Producing more output is safe again.
  }

Hard queue limits may also be configured.

If sending another datagram would exceed a hard queue limit, that datagram is
not accepted and the error is reported through C<on_error>.

=head1 CALLBACKS

C<new> and C<connect> accept these callbacks:

=over 4

=item C<on_datagram($socket, $payload, $peer)>

One complete datagram was received.

This callback is required.

=item C<on_ready($socket)>

The Datagram became active and ready for application use.

=item C<on_drain($socket)>

Queued output fell to the low watermark after backpressure.

=item C<on_error($socket, $error)>

An asynchronous socket, receive, send, size, or queue-limit error occurred.

=item C<on_close($socket)>

The Datagram closed.

=back

Callbacks may also be implemented as subclass methods.

A constructor callback overrides a same-named subclass method for that object.

=head1 ERRORS

=head2 on_error

  on_error => sub ($self, $error) {
      warn "$error\n";
  }

C<$error> is a L<Linux::Event::Error> object.

Datagram errors do not invent Stream concepts such as EOF.

A failed packet does not mean there is a byte stream that has ended.

=head2 last_error

  my $error = $socket->last_error;

Return the most recently stored error, when one exists.

=head1 PAUSING INPUT

=head2 pause_read

  $socket->pause_read;

Temporarily stop receiving application datagrams.

=head2 resume_read

  $socket->resume_read;

Resume receiving datagrams.

=head2 is_read_paused

  if ($socket->is_read_paused) {
      ...
  }

Return true when Datagram input is currently paused.

=head1 SUBCLASSING

Subclassing is optional.

A simple UDP service can use constructor callbacks directly:

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      ...
      on_datagram => sub ($self, $payload, $peer) {
          ...
      },
  );

Subclassing is useful when many Datagram objects should share the same
callbacks or socket policy.

For example:

  package DiscoverySocket;

  use parent 'Linux::Event::IO::Sock::Dgram';

  sub on_datagram ($self, $payload, $peer) {
      ...
  }

  sub datagram_options ($class) {
      return (
          max_datagram_size      => 32_768,
          max_datagrams_per_tick => 128,
      );
  }

=head1 DATAGRAM OPTIONS

Reusable Datagram policy can be declared in a subclass with
C<datagram_options>.

For example:

  package ServiceDgram;

  use parent 'Linux::Event::IO::Sock::Dgram';

  sub datagram_options ($class) {
      return (
          max_datagram_size      => 32_768,
          max_datagrams_per_tick => 128,
          receive_buffer         => 1_048_576,
      );
  }

Constructor values may override these defaults for one Datagram.

The same options can therefore also be supplied directly at the top level of
C<new> or C<connect>:

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 9999,

      max_datagram_size      => 32_768,
      max_datagrams_per_tick => 128,
      receive_buffer         => 1_048_576,

      on_datagram => sub ($self, $payload, $peer) {
          ...
      },
  );

There is no separate C<tuning> hash for Datagram constructor options.

=head1 INPUT SIZE AND FAIRNESS

=head2 max_datagram_size

Default: 65,535 bytes.

  max_datagram_size => 32_768

Largest packet Linux::Event will accept.

The allowed range is 1 through 16,777,216 bytes.

If a received packet is larger than this limit, Linux::Event rejects the whole
packet and reports an error.

It does not deliver a misleading truncated prefix to C<on_datagram>.

The same limit also applies to packets supplied to C<send>.

=head2 max_datagrams_per_tick

Default: 256.

  max_datagrams_per_tick => 128

Maximum number of received datagrams processed during one readiness turn.

This is a fairness control.

A socket receiving packets continuously should not indefinitely prevent timers,
Streams, or other resources from getting a turn.

A value of zero means continue receiving until the socket would block.

=head2 edge_triggered

Default: false.

  edge_triggered => 1

Use edge-triggered receive readiness.

This is an advanced option.

When enabled, C<max_datagrams_per_tick> must be zero because the socket must be
drained until C<EAGAIN>.

=head1 OUTPUT QUEUE LIMITS

=head2 high_watermark

Default: 1,048,576 bytes.

When queued datagram payload reaches this level, C<send> begins returning false
to signal backpressure.

=head2 low_watermark

Default: 262,144 bytes.

After high-watermark backpressure has occurred, C<on_drain> fires when queued
payload falls to or below this level.

The low watermark cannot exceed the high watermark.

=head2 max_pending_bytes

Default: 0.

Hard limit on the total queued datagram payload bytes.

Zero means no hard byte limit.

=head2 max_pending_datagrams

Default: 0.

Hard limit on the number of queued datagrams.

Zero means no hard packet-count limit.

=head1 COMMON SOCKET OPTIONS

The following settings may be placed in C<datagram_options> or supplied
directly to the constructor.

=head2 reuseaddr

Default: false.

  reuseaddr => 1

Controls C<SO_REUSEADDR>.

=head2 reuseport

Default: false.

  reuseport => 1

Controls C<SO_REUSEPORT>.

=head2 broadcast

Default: false.

  broadcast => 1

Controls C<SO_BROADCAST>.

This is used with IPv4 UDP broadcast.

=head2 v6only

For IPv6 sockets:

  v6only => 1

controls C<IPV6_V6ONLY>.

When unspecified, the operating-system default is used.

=head2 send_buffer

  send_buffer => 1_048_576

Request a C<SO_SNDBUF> size.

=head2 receive_buffer

  receive_buffer => 1_048_576

Request a C<SO_RCVBUF> size.

=head1 TOP-LEVEL PER-SOCKET CONSTRUCTOR OPTIONS

The options in this section are supplied B<directly to C<new()> or
C<connect()>>.

They do not go inside C<datagram_options>, and they do not go inside a nested
C<tuning> or C<socket> hash.

For example, a connected UDP socket with an explicit local address and network
interface can be written as:

  my $socket = Linux::Event::IO::Sock::Dgram->connect(
      loop => $loop,

      host => '192.0.2.20',
      port => 9000,

      local_host  => '192.0.2.10',
      local_port  => 0,
      bind_device => 'eth0',

      max_datagram_size => 32_768,

      on_datagram => sub ($self, $payload, $peer) {
          ...
      },
  );

Here:

  local_host
  local_port
  bind_device

are per-socket constructor options.

C<max_datagram_size> is also a top-level constructor option in this example,
but unlike the three options above it may alternatively be supplied through a
subclass's C<datagram_options> policy.

A Unix-domain Datagram provides another example:

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      loop => $loop,

      unix            => '/run/my-service.sock',
      unlink          => 1,
      unlink_on_close => 1,
      permissions     => 0660,

      on_datagram => sub ($self, $payload, $peer) {
          ...
      },
  );

C<unlink>, C<unlink_on_close>, and C<permissions> apply only to that particular
Unix-domain Datagram.

The per-socket options include:

  bind_device
  unlink
  unlink_on_close
  permissions
  owns_socket
  local_host
  local_port
  local_unix

Not every option is valid for every socket source. For example, Unix filesystem
options do not apply to an ordinary UDP socket, and C<local_host> does not apply
to a Unix-domain Datagram.

=head2 bind_device

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      host        => '0.0.0.0',
      port        => 9999,
      bind_device => 'eth0',
      ...
  );

Bind an Internet datagram socket to a particular Linux interface using
C<SO_BINDTODEVICE>.

=head2 local_host and local_port

A connected UDP Datagram may request a particular local address or port:

  my $socket = Linux::Event::IO::Sock::Dgram->connect(
      host       => '192.0.2.20',
      port       => 9000,
      local_host => '192.0.2.10',
      local_port => 0,
      ...
  );

=head2 local_unix

A connected Unix-domain Datagram may give itself a local filesystem path:

  my $socket = Linux::Event::IO::Sock::Dgram->connect(
      unix       => '/run/server.sock',
      local_unix => '/run/client.sock',
      ...
  );

This is useful when the peer needs a filesystem address to which it can send
replies.

=head2 owns_socket

C<owns_socket> applies when adopting an existing socket with C<fh>:

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      fh          => $fh,
      owns_socket => 1,
      ...
  );

When true, Linux::Event owns and closes the supplied socket.

=head1 UNIX SOCKET PATH OPTIONS

Unix-domain Datagram sockets may use filesystem ownership options.

These are top-level constructor options.

For example:

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      unix            => '/run/service.sock',
      unlink          => 1,
      unlink_on_close => 1,
      permissions     => 0660,
      ...
  );

=head2 unlink

Allow an existing Unix socket path to be removed during setup.

=head2 unlink_on_close

Control whether an owned Unix socket path is removed when the Datagram closes.

The default is true.

=head2 permissions

Set filesystem permissions for a newly created Unix-domain socket path.

=head1 ADOPTING AN EXISTING DATAGRAM SOCKET

C<new> can adopt an existing datagram socket:

  my $socket = Linux::Event::IO::Sock::Dgram->new(
      loop => $loop,
      fh   => $fh,

      on_datagram => sub ($self, $payload, $peer) {
          ...
      },
  );

The handle must be an IPv4, IPv6, or Unix C<SOCK_DGRAM> socket.

Linux::Event configures adopted handles for nonblocking and close-on-exec use.

By default an adopted socket remains caller-owned.

Use:

  owns_socket => 1

when the Datagram object should own and close the supplied socket.

=head1 RUNTIME SOCKET SETTINGS

Some socket settings can also be inspected or changed after the Datagram is
active.

=head2 send_buffer

  my $size = $socket->send_buffer;

  $socket->send_buffer(1_048_576);

Read or request the active socket's send-buffer size.

=head2 receive_buffer

  my $size = $socket->receive_buffer;

  $socket->receive_buffer(1_048_576);

Read or request the active socket's receive-buffer size.

=head2 broadcast

  my $enabled = $socket->broadcast;

  $socket->broadcast(1);

Read or change IPv4 broadcast permission on the active socket.

=head1 ADDRESS INFORMATION

=head2 local

  my $address = $socket->local;

Return the local L<Linux::Event::Address> when available.

=head2 peer

  my $address = $socket->peer;

Return the default peer for a connected Datagram.

For an unconnected Datagram there may be no single peer because packets can
arrive from many different addresses.

=head2 is_connected

  if ($socket->is_connected) {
      ...
  }

Return true when the Datagram has a default connected peer.

=head1 QUEUE INFORMATION

=head2 pending_bytes

  my $bytes = $socket->pending_bytes;

Return the number of datagram payload bytes currently queued for output.

=head2 pending_datagrams

  my $count = $socket->pending_datagrams;

Return the number of complete datagrams currently queued for output.

=head1 OTHER INFORMATION METHODS

=head2 fd

Return the active socket's integer file descriptor when available.

=head2 fh

Return the active Perl socket handle when available.

=head2 loop

Return the owning L<Linux::Event::Loop> while attached.

=head2 state

Return the current lifecycle state.

=head2 data

Store or retrieve arbitrary application state:

  $socket->data($value);

  my $value = $socket->data;

=head2 is_active

Return true while the Datagram is active.

=head1 CLOSING AND DETACHING

=head2 close

  $socket->close;

Close the Datagram and release resources it owns.

C<close> is terminal.

=head2 on_close

  on_close => sub ($self) {
      ...
  }

Called when the Datagram closes through its normal lifecycle.

=head2 detach

  my $fh = $socket->detach;

Remove the socket from Linux::Event and return the still-open handle.

Detachment is terminal for the Datagram object.

Linux::Event gives up ownership of the handle and suppresses removal of an
owned Unix socket path.

=head1 PERFORMANCE MODEL

Datagram policy and callbacks are resolved when the object is constructed.

Normal packet delivery does not repeatedly perform method lookup or rebuild
socket policy.

Packet receiving is handled natively, including detection of oversized packets
without passing truncated data to Perl.

These details normally require no application action.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::Address>,
L<Linux::Event::Error>,
F<docs/DGRAM-DESIGN.md>,
F<docs/SOCKET-CONFIGURATION.md>.

=cut
