package Linux::Event::IO::Sock::Stream;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use parent 'Linux::Event::_Socket::Stream';

1;

__END__

=head1 NAME

Linux::Event::IO::Sock::Stream - Asynchronous connected sockets

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::IO::Sock::Stream;

  my $loop = Linux::Event::Loop->new;

  my $stream = Linux::Event::IO::Sock::Stream->connect(
      loop => $loop,
      host => 'example.com',
      port => 80,

      on_ready => sub ($self) {
          $self->write("GET / HTTP/1.0\r\n\r\n");
      },

      on_data => sub ($self, $bytes) {
          print $bytes;
      },

      on_error => sub ($self, $error) {
          warn "$error\n";
      },

      on_close => sub ($self) {
          $loop->stop;
      },
  );

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::IO::Sock::Stream> represents one connected stream socket.

It is used for:

=over 4

=item *

TCP connections over IPv4

=item *

TCP connections over IPv6

=item *

Unix-domain stream sockets

=item *

outbound client connections

=item *

connections accepted by L<Linux::Event::IO::Sock::Listener>

=item *

already-connected sockets adopted from other code

=back

A Stream handles the connection asynchronously.

Your application supplies callbacks such as C<on_ready>, C<on_data>,
C<on_error>, and C<on_close>, and Linux::Event calls them when something
happens.

The same Stream class also supports framing, TLS, buffering, backpressure,
timeouts, socket configuration, and protocol transitions when those features
are needed.

=head1 CONNECTING TO A SERVER

Use C<connect> to create an outbound connection:

  my $stream = Linux::Event::IO::Sock::Stream->connect(
      loop => $loop,
      host => 'example.com',
      port => 1234,

      on_ready => sub ($self) {
          say "Connected";
      },

      on_data => sub ($self, $bytes) {
          say "Received: $bytes";
      },
  );

Hostname lookup and connection establishment happen asynchronously.

The Stream object exists immediately and keeps the same identity through DNS
resolution, connection establishment, optional TLS negotiation, normal I/O,
and final close.

=head2 loop

  loop => $loop

Attach the Stream to a Loop immediately.

The C<loop> option is optional.

Without it, C<connect> returns a detached Stream:

  my $stream = Linux::Event::IO::Sock::Stream->connect(
      host => 'example.com',
      port => 1234,
      ...
  );

  $loop->add($stream);

=head2 host and port

For a TCP connection:

  host => 'example.com',
  port => 1234,

C<host> may require asynchronous DNS resolution.

=head2 Unix-domain sockets

Use C<unix> instead of C<host> and C<port>:

  my $stream = Linux::Event::IO::Sock::Stream->connect(
      loop => $loop,
      unix => '/run/my-service.sock',
      ...
  );

=head2 timeout

  timeout => 10

Set the connection-establishment timeout in seconds.

The default is 10 seconds.

This timeout covers connection establishment rather than the later
established-connection timeout policy.

=head2 data

  data => $value

Store arbitrary application data with the Stream.

This is useful when a connection needs to carry application-specific state.

=head2 Local address options

Outbound TCP connections may optionally specify:

  local_host => '192.0.2.10',
  local_port => 0,

C<bind_device> may also be used when the connection must be bound to a
particular Linux network device.

These options are normally unnecessary.

=head1 WHEN THE CONNECTION IS READY

=head2 on_ready

  on_ready => sub ($self) {
      ...
  }

C<on_ready> is called once when the connection is ready for application use.

For a normal TCP connection, this is after connection establishment.

For a TLS connection, this is after the TLS handshake and verification have
completed.

This means application protocols can normally begin their work in C<on_ready>
without needing to know whether the underlying connection is plain or TLS.

For example:

  on_ready => sub ($self) {
      $self->write("HELLO\r\n");
  }

=head1 RECEIVING DATA

=head2 on_data

For an unframed Stream, incoming bytes are delivered to C<on_data>:

  on_data => sub ($self, $bytes) {
      print $bytes;
  }

C<$bytes> contains the next available part of the ordered byte stream.

TCP does not preserve application message boundaries.

For example, two writes by the remote peer may arrive in one C<on_data>
callback, or one remote write may arrive across several callbacks.

If your protocol has messages, use L<Linux::Event::Framer> rather than assuming
that one C<on_data> call equals one message.

=head1 SENDING DATA

=head2 write($bytes)

  $stream->write("hello");

C<write> sends raw bytes on the connection.

Linux::Event first attempts to write immediately.

If the socket cannot accept all of the data, the remaining bytes are queued and
written later when the socket becomes writable again.

Data is kept in order.

You do not need to manually watch the socket for writable readiness.

=head2 Writing before on_ready

Data may be queued before the connection becomes ready:

  my $stream = Linux::Event::IO::Sock::Stream->connect(
      loop => $loop,
      host => 'example.com',
      port => 1234,
      ...
  );

  $stream->write("hello");

The bytes remain queued and are sent when the transport becomes usable.

For many protocols it is still clearer to begin application communication from
C<on_ready>.

=head2 send($payload)

  $stream->send($payload);

C<send> is used by framed Stream subclasses.

It applies the subclass's L<Linux::Event::Framer> to the payload before placing
the resulting bytes on the wire.

For an unframed protocol, use C<write>.

=head1 CLOSING A CONNECTION

=head2 close

  $stream->close;

Close the connection immediately.

C<close> is terminal.

Pending output does not need to finish first.

=head2 end

  $stream->end;

Finish queued output and then perform the writable half-close appropriate for
the transport.

Use C<end> when a protocol wants to finish sending data cleanly rather than
aborting the connection immediately.

=head2 on_close

  on_close => sub ($self) {
      ...
  }

Called when the Stream reaches its terminal closed state.

=head2 on_eof

  on_eof => sub ($self) {
      ...
  }

Called when the peer closes its sending side and the Stream reaches input EOF.

EOF and immediate connection destruction are not the same event, so protocols
that care about half-close behavior may handle C<on_eof> separately.

=head1 ERRORS

=head2 on_error

  on_error => sub ($self, $error) {
      warn "Connection error: $error\n";
  }

Called when the Stream encounters an asynchronous connection or I/O error.

C<$error> is a L<Linux::Event::Error> object.

The Stream's C<last_error> method can be used to inspect the most recent stored
error.

=head1 PAUSING INPUT

=head2 pause_read

  $stream->pause_read;

Temporarily stop delivering application input.

=head2 resume_read

  $stream->resume_read;

Resume application input.

This is useful when the application needs to slow consumption without closing
the connection.

Read timeout handling is suspended while input is deliberately paused.

=head1 BACKPRESSURE

A Stream has an output queue for bytes that the kernel cannot accept
immediately.

Linux::Event provides high and low watermarks so applications can react when
that queue becomes large.

C<write> and C<send> still accept the supplied data when the high watermark is
reached, but begin returning false to tell the application that it should slow
down.

When queued output later falls to the low watermark, C<on_drain> is called.

=head2 on_drain

  on_drain => sub ($self) {
      say "Output has drained; producing more data is safe";
  }

A typical producer can therefore stop generating more data when C<write>
returns false and resume from C<on_drain>.

=head1 CALLBACKS

Stream behavior may be supplied with constructor callbacks:

  my $stream = Linux::Event::IO::Sock::Stream->connect(
      loop => $loop,
      host => 'example.com',
      port => 1234,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

or by subclass methods:

  package MyConnection;

  use parent 'Linux::Event::IO::Sock::Stream';

  sub on_data ($self, $bytes) {
      ...
  }

A constructor callback overrides a same-named subclass method for that
particular Stream.

This lets a reusable protocol class define normal behavior while an individual
connection supplies special application state when necessary.

=head2 Available callbacks

The normal Stream callbacks are:

=over 4

=item C<on_ready($stream)>

The connection is ready for application use.

=item C<on_data($stream, $bytes)>

Raw unframed input arrived.

=item C<on_message($stream, $message)>

One complete framed message arrived.

=item C<on_messages($stream, $messages)>

A batch of framed messages arrived when message batching is enabled.

=item C<on_drain($stream)>

Queued output fell back to the low watermark after backpressure.

=item C<on_eof($stream)>

The peer reached input EOF.

=item C<on_error($stream, $error)>

An asynchronous error occurred.

=item C<on_close($stream)>

The Stream closed.

=item C<on_transport_ready($stream)>

The lower-level transport became ready.

This is mainly useful to transport implementations and specialized protocol
code. Normal applications should usually use C<on_ready>.

=back

=head1 ADOPTING AN EXISTING SOCKET

Use C<new> when you already have a connected C<SOCK_STREAM> socket:

  my $stream = Linux::Event::IO::Sock::Stream->new(
      loop => $loop,
      fh   => $socket,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

Linux::Event validates the handle and configures it for nonblocking,
close-on-exec operation.

The connection is already established, so an adopted plain socket does not
later emit C<on_ready>.

If the Stream class declares TLS, an adopted socket must also specify whether
it is acting as the TLS client or server because Linux::Event cannot infer that
from an already-connected handle.

=head1 ACCEPTED CONNECTIONS

L<Linux::Event::IO::Sock::Listener> creates Stream objects for accepted
connections.

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

The Listener may also specify a Stream subclass, framing, TLS, tuning, and
callbacks for all accepted connections.

See L<Linux::Event::IO::Sock::Listener>.

=head1 FRAMED PROTOCOLS

Raw TCP carries bytes, not messages.

Linux::Event can perform message framing before your Perl callback runs.

For example, a line-oriented protocol can define:

  package LineConnection;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      say "Received complete line: $message";
  }

Incoming bytes are accumulated until the framer finds a complete message.

Your application then receives C<on_message> instead of having to maintain its
own partial-input buffer.

To send a framed message:

  $stream->send("hello");

The framer converts the payload to its wire representation.

See L<Linux::Event::Framer> for the available framing methods.

=head1 SUBCLASSING

Subclassing is optional.

For a simple connection, constructor callbacks are often all that is needed:

  my $stream = Linux::Event::IO::Sock::Stream->connect(
      ...
      on_data => sub ($self, $bytes) {
          ...
      },
  );

Subclassing is useful when many connections share a protocol or configuration.

A subclass can define:

=over 4

=item *

callback methods

=item *

framing

=item *

TLS defaults

=item *

socket options

=item *

Stream tuning

=item *

its own ordinary Perl instance state

=back

For example:

  package ChatConnection;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      ...
  }

=head2 Subclass instance data

A Stream subclass is an ordinary Perl class.

It may store its own fields:

  package StatefulConnection;

  use parent 'Linux::Event::IO::Sock::Stream';

  sub new ($class, %option) {
      my $self = $class->SUPER::new(%option);
      $self->{message_count} = 0;
      return $self;
  }

  sub on_data ($self, $bytes) {
      $self->{message_count}++;
      ...
  }

Linux::Event leaves unrelated subclass-owned fields alone.

A subclass constructor should remove or handle its own constructor arguments
and pass only Linux::Event options to C<SUPER::new>.

=head1 TLS

TLS is a capability of a Stream connection, not a separate public Stream type.

This means application code can generally treat plain and encrypted
connections the same way.

For accepted connections, TLS is commonly selected by the Listener:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 9443,

      stream => {
          class => 'ServerConnection',

          tls => {
              cert_file => $cert_file,
              key_file  => $key_file,
              alpn      => ['my-protocol/1'],
          },
      },
  );

The same Stream subclass can be used by another Listener without TLS.

Framing and application callbacks always see plaintext.

C<on_ready> occurs after TLS negotiation is complete.

See L<Linux::Event::TLS> for TLS configuration.

=head1 SOCKET OPTIONS

A Stream subclass may define C<socket_options> when every connection of that
class should use the same socket settings.

For example:

  package LowLatencyConnection;

  use parent 'Linux::Event::IO::Sock::Stream';

  sub socket_options ($class) {
      return (
          tcp_nodelay => 1,
          keepalive   => 1,
      );
  }

Constructor options may override class socket policy for one connection.

Supported socket options are described below.

=head2 tcp_nodelay

Boolean C<0> or C<1> controlling C<TCP_NODELAY>.

TCP only.

=head2 keepalive

Boolean C<0> or C<1> controlling C<SO_KEEPALIVE>.

TCP only.

=head2 keepalive_idle

Positive integer number of seconds before the first TCP keepalive probe.

=head2 keepalive_interval

Positive integer number of seconds between TCP keepalive probes.

=head2 keepalive_count

Positive integer number of failed TCP keepalive probes allowed.

=head2 tcp_user_timeout

Non-negative number of seconds for Linux C<TCP_USER_TIMEOUT>.

Fractional seconds are accepted and rounded up to milliseconds.

TCP only.

=head2 send_buffer

Positive integer requested C<SO_SNDBUF> size.

=head2 receive_buffer

Positive integer requested C<SO_RCVBUF> size.

=head2 Other socket configuration

C<bind_device> is a constructor option rather than a C<socket_options> key.

Advanced subclasses may use C<configure_socket> for Linux socket options not
covered by the normal policy.

See F<docs/SOCKET-CONFIGURATION.md> for the detailed application order and
failure behavior.

=head1 STREAM TUNING

Most applications should use the defaults.

Linux::Event's Stream defaults are intended to provide good performance and
fairness without application tuning.

When measurements show that a particular protocol needs different behavior, a
subclass may define C<stream_tuning>:

  package TunedConnection;

  use parent 'Linux::Event::IO::Sock::Stream';

  sub stream_tuning ($class) {
      return (
          read_size         => 131_072,
          read_budget_bytes => 524_288,
          high_watermark    => 2_097_152,
          low_watermark     => 524_288,
          idle_timeout      => 60,
      );
  }

The method may return key/value pairs or one hash reference.

=head2 read_size

Default: 65,536 bytes.

Maximum number of bytes requested by one native read.

It must be a positive integer.

=head2 read_budget_bytes

Default: 65,536 bytes.

Maximum amount of data one readiness turn may read before yielding to other
Loop resources.

This limit exists for fairness.

Without a limit, a socket that is continuously receiving data could keep one
read callback busy while timers or other sockets are already ready.

A value of zero explicitly requests unlimited draining until the socket would
block.

=head2 read_batch_bytes

Default: 0.

For an unframed Stream, successful reads may be combined before C<on_data> is
called.

A value of zero preserves normal read callback boundaries.

This option cannot be used with framing.

=head2 message_batch_size

Default: 0.

For framed Streams, deliver up to this many complete messages together through
C<on_messages>.

A value of zero uses normal C<on_message> delivery.

A positive value requires framing and an C<on_messages> callback.

=head2 max_buffer

Default: 8,388,608 bytes.

Hard maximum for retained input, incomplete framing data, and data retained for
one message batch.

=head2 high_watermark

Default: 1,048,576 bytes.

When pending output reaches this level, C<write> and C<send> begin returning
false to signal backpressure.

The supplied data is still accepted unless a hard pending-output limit prevents
it.

=head2 low_watermark

Default: 262,144 bytes.

After backpressure has occurred, C<on_drain> fires when queued output falls to
or below this level.

The low watermark cannot be greater than the high watermark.

=head2 max_pending_bytes

Default: 0.

Hard limit on pending output bytes.

Zero means there is no hard limit.

=head2 idle_timeout

Default: 0.

Maximum number of seconds without successful established input or output
progress.

Zero disables the timeout.

=head2 read_timeout

Default: 0.

Maximum number of seconds without inbound progress while reading is active.

A deliberate C<pause_read> suspends this timeout.

Zero disables it.

=head2 write_timeout

Default: 0.

Maximum number of seconds without output progress while data remains queued.

Zero disables it.

=head1 CHANGING TUNING AT RUNTIME

=head2 tune

A live Stream can change its mutable tuning policy:

  $stream->tune(
      high_watermark => 2_097_152,
      low_watermark  => 524_288,
      idle_timeout   => 30,
  );

C<tune> accepts these settings:

  read_size
  read_budget_bytes
  read_batch_bytes
  message_batch_size
  high_watermark
  low_watermark
  max_pending_bytes
  max_buffer
  idle_timeout
  read_timeout
  write_timeout

C<tune> returns the Stream.

It cannot change the Stream's framer, callback structure, native protocol
consumer, or transport type.

Changing watermarks immediately recalculates backpressure state.

Reducing a hard limit does not discard data that is already buffered or queued,
but future growth must obey the new limit.

C<tune> cannot be used after the Stream has closed.

=head1 DEADLINES

Established Streams may also use an explicit C<deadline> in addition to the
idle, read, and write timeout policy.

Connection establishment, TLS handshake, TLS shutdown, and established I/O use
their own lifecycle deadlines rather than one ambiguous timeout covering every
phase.

=head1 ADDRESSES

=head2 local

  my $address = $stream->local;

Return the local L<Linux::Event::Address> when available.

=head2 peer

  my $address = $stream->peer;

Return the peer L<Linux::Event::Address> when available.

The Address object represents IPv4, IPv6, or Unix-domain addresses as
appropriate.

=head1 CONNECTION INFORMATION

=head2 fd

Return the underlying integer file descriptor when available.

=head2 fh

Return the Stream's Perl socket handle when available.

=head2 state

Return the current connection state.

=head2 pending_bytes

Return the number of output bytes currently waiting to be written.

=head2 last_error

Return the Stream's most recently stored error, when one exists.

=head1 DETACHING A SOCKET

=head2 detach

C<detach> transfers an established plain socket out of Linux::Event.

Detachment is allowed only when it can be done without losing queued output or
transport state.

In particular, a plain connection must have no pending output.

Encrypted transports cannot be safely detached because the TLS state is part of
the connection.

=head1 PROTOCOL TRANSITIONS

=head2 transition_to

C<transition_to> allows a live connection to change protocol handling without
replacing the socket itself.

The Stream keeps its live transport, queued output, and unread input while the
new protocol policy takes over according to the transition rules.

This is useful for protocols that intentionally change modes during one
connection, such as an HTTP connection upgrading to WebSocket.

Linux::Event also supports native protocol consumers that operate directly on
the Stream's native input buffer.

A native consumer may hand the connection to another native consumer, or retire
into an ordinary Perl input callback, while preserving unread bytes.

Adding a native consumer after ordinary Perl input has already been active is
not supported.

These are advanced protocol-engine facilities.

See F<docs/FRAMING.md> for the complete transition contract.

=head1 PERFORMANCE MODEL

Linux::Event resolves Stream callbacks and reusable class policy when the
connection is constructed.

Normal input delivery does not repeatedly search the object's Perl hash for a
callback or decide between a method and constructor callback for every event.

Framing, buffering, output queuing, and readiness handling are implemented by
the native ordered-byte engine.

These details normally require no application action; they explain why
subclass policy and constructor callbacks can be combined without forcing the
application into one style.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::IO::Sock::Listener>,
L<Linux::Event::IO::Sock::Dgram>,
L<Linux::Event::Framer>,
L<Linux::Event::TLS>,
L<Linux::Event::Address>,
L<Linux::Event::Error>,
F<docs/SOCKET-CONNECTIONS.md>,
F<docs/ORDERED-BYTE-IO-DESIGN.md>,
F<docs/FIRST-CLASS-STREAM-CALLBACKS.md>,
F<docs/FRAMING.md>.

=cut
