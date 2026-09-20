package Linux::Event::IO::Sock::Stream;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use parent 'Linux::Event::_Socket::Stream';

1;

__END__

=head1 NAME

Linux::Event::IO::Sock::Stream - asynchronous Linux C<SOCK_STREAM> connections

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::IO::Sock::Listener;
  use Linux::Event::IO::Sock::Stream;

  my $loop = Linux::Event::Loop->new;
  my $server = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '127.0.0.1',
      port => 0,
      stream => {
          on_data => sub ($stream, $bytes) {
              $stream->write($bytes);
          },
      },
  );

  my $prefix = 'received';
  my $client = Linux::Event::IO::Sock::Stream->connect(
      loop    => $loop,
      host    => '127.0.0.1',
      port    => $server->port,
      on_ready => sub ($stream) {
          $stream->write('hello');
      },
      on_data => sub ($stream, $bytes) {
          say "$prefix: $bytes";
          $stream->close;
          $server->close;
          $loop->stop;
      },
      on_error => sub ($stream, $error) {
          die "connection failed: $error\n";
      },
  );

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::IO::Sock::Stream> is the public class for connected Linux
C<SOCK_STREAM> sockets. TCP over IPv4 or IPv6 and Unix-domain stream sockets
use the same class; address family is connection configuration rather than a
separate type hierarchy.

The class combines the common ordered-byte engine with socket acquisition,
addresses, socket policy, kernel half-close semantics, and optional TLS. A
concrete protocol subclass can supply named callbacks and declare class policy;
constructor callbacks are an equally supported way to provide application
behavior with normal Perl lexical scope.

=head1 CALLBACKS, SUBCLASSING, AND TUNING

Constructor callbacks make the public Stream leaf directly useful and preserve
ordinary lexical scope. Subclassing remains one of Linux::Event's important
distinguishing features because a protocol class can declare, once:

=over 4

=item * a native L<Linux::Event::Framer> and its wire format;

=item * reusable TLS defaults such as ALPN and transport timeouts, without
making TLS part of the Stream class identity;

=item * C<stream_tuning> tuning for reads, fairness, batching, buffers,
watermarks, limits, and established deadlines; and

=item * socket policy and named, reusable callbacks.

=back

Class policy and method callbacks are validated and cached once per subclass.
A constructor callback overrides a same-named method for one connection and is
retained once in that object's effective descriptor. This makes it natural to
combine reusable high-performance protocol policy with per-connection lexical
state without adding event-time method lookup or callback-style selection.

A Stream subclass is also an ordinary Perl class and may initialize and expose
its own instance variables. Linux::Event does not interpret or manage
subclass-owned state, and no separate state or initialization hook is required:

  package StatefulConnection;
  use parent 'Linux::Event::IO::Sock::Stream';

  sub new ($class, %option) {
      my $self = $class->SUPER::new(%option);
      $self->{message_count} = 0;
      return $self;
  }

  sub message_count ($self, @value) {
      $self->{message_count} = $value[0] if @value;
      return $self->{message_count};
  }

  sub on_data ($self, $bytes) {
      $self->{message_count}++;
      ...;
  }

Core operations leave unrelated subclass-owned entries alone. Subclass
constructors remain responsible for their own state and should pass only
Linux::Event constructor options to C<SUPER::new>.

=head2 stream_tuning

Define C<stream_tuning> as a class method on the Stream subclass. It returns
key/value pairs, or one hash reference:

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

These options also apply to Pipe and TTY subclasses. The complete Stream option
set is:

=over 4

=item * C<read_size> (default 65,536)

Maximum bytes requested by one native read; a positive integer.

=item * C<read_budget_bytes> (default 65_536)

Maximum bytes read during one readiness drain. The default bounds one
readiness callback to 65,536 bytes so other Loop resources can run. Zero is an
explicit opt-in to drain until the socket would block.

=item * C<read_batch_bytes> (default 0)

For an unframed class, combine successful reads before C<on_data> up to this
non-negative byte target. Partial batches flush when the current drain ends;
zero preserves normal read callback boundaries. It is invalid with framing.

=item * C<message_batch_size> (default 0)

For a framed class, deliver arrays of at most this many messages to
C<on_messages>. Partial batches flush when the current drain ends; zero uses
C<on_message>. A positive value requires C<on_messages> and framing.

=item * C<max_buffer> (default 8,388,608)

Positive hard byte bound for retained input, an incomplete frame, and the
aggregate payload retained for one message batch.

=item * C<high_watermark> (default 1,048,576)

Non-negative pending-output byte level at which C<write> or C<send> begins
returning false while still accepting the data.

=item * C<low_watermark> (default 262,144)

Non-negative pending-output byte level at or below which C<on_drain> fires
after high-watermark backpressure. It must not exceed C<high_watermark>.

=item * C<max_pending_bytes> (default 0)

Hard non-negative pending-output byte limit. Zero means unbounded.

=item * C<idle_timeout> (default 0 seconds)

Maximum inactivity interval since successful established input or output
progress. Zero disables it.

=item * C<read_timeout> (default 0 seconds)

Maximum interval without inbound progress while reading is active. Pausing
input suspends it; zero disables it.

=item * C<write_timeout> (default 0 seconds)

Maximum interval without output progress while data is queued. Zero disables
it.

=back

Byte counts are integers. Timeout values are finite non-negative seconds and
may be fractional.

=head2 tune

C<tune> changes the mutable ordered-byte policy of an existing Stream without
reconstructing it:

  $stream->tune(
      read_size         => 131_072,
      read_budget_bytes => 524_288,
      high_watermark    => 2_097_152,
      low_watermark     => 524_288,
      idle_timeout      => 30,
  );

The supported keys are the same eleven values documented by C<stream_tuning>:
C<read_size>, C<read_budget_bytes>, C<read_batch_bytes>,
C<message_batch_size>, C<high_watermark>, C<low_watermark>,
C<max_pending_bytes>, C<max_buffer>, C<idle_timeout>, C<read_timeout>, and
C<write_timeout>.

Effective precedence is class C<stream_tuning()> defaults, then Listener
C<stream =E<gt> { tuning =E<gt> {...} }> deployment overrides for accepted
connections, then C<tune()> on the live object.

Mutable values are copied into native per-Stream state when policy changes.
Ordinary reads and writes do not consult Perl hashes or perform class-versus-
instance resolution. Changing message batching settles work owned by the old
batch policy first. Watermark changes immediately reconcile backpressure.
Lowering C<max_pending_bytes> or C<max_buffer> does not discard bytes already
queued or buffered; later growth must satisfy the new limit. Timeout changes
re-arm or cancel established deadline state as needed.

Framer identity, callback structure, native-consumer identity, and transport
kind are not C<tune()> values. C<tune()> returns the Stream and rejects calls
on a closed Stream.

=head2 socket_options

Define C<socket_options> as another class method on a Stream subclass. It also
returns key/value pairs or one hash reference:

  sub socket_options ($class) {
      return (
          tcp_nodelay      => 1,
          keepalive        => 1,
          tcp_user_timeout => 15,
      );
  }

Unspecified options retain kernel defaults. The complete set is:

=over 4

=item * C<tcp_nodelay>

Boolean C<0> or C<1> controlling C<TCP_NODELAY>; TCP only.

=item * C<keepalive>

Boolean C<0> or C<1> controlling C<SO_KEEPALIVE>; TCP only.

=item * C<keepalive_idle>

Positive integer seconds before the first TCP keepalive probe.

=item * C<keepalive_interval>

Positive integer seconds between TCP keepalive probes.

=item * C<keepalive_count>

Positive integer number of failed TCP keepalive probes allowed.

=item * C<tcp_user_timeout>

Finite non-negative seconds for C<TCP_USER_TIMEOUT>; fractional values are
rounded up to milliseconds. TCP only.

=item * C<send_buffer>

Positive integer requested C<SO_SNDBUF> size.

=item * C<receive_buffer>

Positive integer requested C<SO_RCVBUF> size.

=back

Positive socket integers are at most 2,147,483,647. Constructor values override
class policy for one connection. C<bind_device> is a constructor option, not a
C<socket_options> key. C<configure_socket> is the cached cold-path hook for
Linux options not covered above.

=head1 OUTBOUND CONNECTIONS

C<connect> constructs one connection object whose identity is retained through
resolution, connection, optional TLS handshake, established I/O, and close:

  my $stream = Client->connect(
      loop    => $loop,          # optional immediate attachment
      host    => 'example.com',  # TCP remote host
      port    => 443,            # TCP remote port
      timeout => 10,             # connection deadline; default 10
      data    => $state,         # optional application state
  );

Use C<unix =E<gt> $path> for a filesystem Unix-domain stream socket. Advanced
callers may supply a packed C<sockaddr> with its numeric C<family>.

C<loop> is optional. Without it, C<connect> returns a detached object that may
later be passed to C<< $loop->add($stream) >>. Writes submitted before readiness
use the normal bounded output queue and are delivered in order after the
transport becomes usable.

Optional source-side controls include numeric C<local_host>, C<local_port>, and
C<bind_device>. Hostname resolution is asynchronous and uses the Loop's private
native resolver service.

=head1 ADOPTED CONNECTED SOCKETS

C<new(fh =E<gt> $socket)> adopts an already connected C<SOCK_STREAM> handle.
The handle is validated, made nonblocking and close-on-exec, and uses the same
established I/O path as an accepted or outbound connection. A TLS-declared
class must also specify C<tls_role> for an adopted handle because acquisition
cannot infer client versus server role.

=head1 CALLBACKS

Callbacks may be methods, constructor coderefs, or a mixture:

  my $database = ...;
  my $stream = RawConnection->new(
      fh      => $socket,
      on_data => sub ($stream, $bytes) {
          process_bytes($database, $stream, $bytes);
      },
  );

A constructor callback overrides the corresponding class method for that
object. Supported names and signatures are C<on_data($stream, $bytes)>,
C<on_message($stream, $message)>, C<on_messages($stream, $messages)>,
C<on_ready($stream)>, C<on_transport_ready($stream)>, C<on_drain($stream)>,
C<on_eof($stream)>, C<on_error($stream, $error)>, and C<on_close($stream)>.
C<connect> accepts the same callback options as C<new>.

C<on_ready($stream)> runs once when an outbound or accepted connection becomes
application-ready. For TLS that means after handshake and verification, not
merely after TCP connect. C<new(fh =E<gt> ...)> adopts a connection that is
already ready and does not emit a later readiness callback.

C<on_transport_ready($stream)> is the lower transport notification used by TLS
or another native transport and runs immediately before C<on_ready>. Plain
connections have no separate transport phase.

A raw object requires C<on_data($stream, $bytes)> as a method or constructor
callback. The public Stream leaf can therefore be constructed directly for raw
I/O. A framed class uses L<Linux::Event::Framer> and requires C<on_message> or,
with explicit batching, C<on_messages>; either may be supplied by the class or
constructor.

Optional lifecycle callbacks include C<on_drain>, C<on_eof>, C<on_error>,
C<on_close>, and C<on_transport_ready> for transport-specific observation.
Method defaults are resolved into an immutable class descriptor. Constructor
input callbacks are retained once in native Stream state, producing one
effective cached CV with no event-time lookup or method-versus-coderef branch.
Lifecycle callbacks are likewise resolved once during construction. Closing or
detaching the Stream releases its retained constructor callbacks.

=head1 FRAMING AND OUTPUT

C<write($bytes)> sends raw ordered bytes. C<send($payload)> applies the
subclass's native framer. The native write engine attempts immediate output,
queues only unsent bytes, enables writable readiness only while necessary, and
uses high/low watermarks plus optional C<max_pending_bytes> protection.

C<pause_read> and C<resume_read> control application reads. C<transition_to>
changes protocol callback/framing descriptors in place while retaining the live
socket, transport, output queue, and unread native input according to the
transition rules in F<docs/FRAMING.md>. Native protocol extensions may also
hand off from one native consumer provider to another without copying the
retained input through Perl; adding or removing native-consumer mode during a
live transition remains invalid.

=head1 SOCKET POLICY

A subclass may define C<socket_options> for acquisition-time socket policy.
The method shape and complete option contract appear near the top of this
document. See
F<docs/SOCKET-CONFIGURATION.md> for application order and failure behavior.

=head1 ORDERED-BYTE POLICY AND DEADLINES

C<stream_tuning> has the complete option contract listed near the top of this
document. One explicit operation C<deadline> may also be set or changed at
runtime. Established timeout policy begins when the application transport is
usable; DNS, connect, TLS handshake, and TLS shutdown retain separate lifecycle
deadlines.

=head1 TLS

TLS is acquisition policy for a Stream socket rather than a separate Stream
class identity. For accepted connections a Listener selects TLS in its generated
Stream recipe:

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

The same C<ServerConnection> class may be used by another Listener without a
C<tls> recipe and is then plain. A subclass may define C<tls_defaults()> for
reusable policy such as ALPN and handshake/shutdown timeouts, but those defaults
do not activate TLS. The Listener prepares one reusable server context and each
accepted TLS Stream receives independent connection state.

Existing class-level L<Linux::Event::TLS> declarations remain available for
explicit outbound client policy and adopted-handle compatibility. Outbound
C<connect> derives the default server name from C<host>. Framing and callbacks
always receive plaintext. See L<Linux::Event::TLS>.

=head1 ADDRESSES AND LIFECYCLE

C<local> and C<peer> return lazy L<Linux::Event::Address> values when available.
C<fd>, C<fh>, C<state>, C<pending_bytes>, and C<last_error> expose connection
state without changing ownership.

C<end> drains accepted output then performs the transport's writable half-close.
C<close> is immediate and terminal. C<detach> transfers a plain connected socket
only when no output is pending; encrypted transports cannot be detached safely.

=head1 SEE ALSO

L<Linux::Event::IO::Sock::Listener>, L<Linux::Event::IO::Sock::Dgram>,
L<Linux::Event::Framer>, L<Linux::Event::TLS>,
F<docs/SOCKET-CONNECTIONS.md>, F<docs/ORDERED-BYTE-IO-DESIGN.md>,
F<docs/FIRST-CLASS-STREAM-CALLBACKS.md>.

=cut
