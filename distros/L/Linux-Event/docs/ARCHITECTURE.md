# Linux::Event architecture

This document describes the production architecture of Linux::Event. Public
names describe completed Linux resources. Private implementation layers may be
shared across those resources without becoming public base classes.

## Public semantic model

```text
Linux::Event
|-- Loop
|-- IO
|   |-- Pipe
|   |-- TTY
|   `-- Sock
|       |-- Stream
|       |-- Listener
|       `-- Dgram
`-- Kernel
    |-- Timer
    |-- Signal
    |-- Event
    `-- Process
```

`Linux::Event::IO` and `Linux::Event::Kernel` are category namespaces, not
constructible objects. The tree is a semantic taxonomy, not a literal Perl
inheritance diagram.

The public leaves are deliberately concrete:

- `IO::Pipe` means ordered bytes over pipe/FIFO descriptors.
- `IO::TTY` means ordered bytes over terminal or PTY descriptors.
- `IO::Sock::Stream` means a connected Linux `SOCK_STREAM` socket.
- `IO::Sock::Listener` means a listening `SOCK_STREAM` socket.
- `IO::Sock::Dgram` means a Linux `SOCK_DGRAM` socket.
- `Kernel::Timer` exposes timer scheduling semantics.
- `Kernel::Signal` exposes signalfd signal semantics.
- `Kernel::Event` exposes eventfd notification semantics.
- `Kernel::Process` exposes pidfd/process lifecycle semantics.

Address family is orthogonal to socket type. IPv4, IPv6, and Unix-domain
stream sockets all use `IO::Sock::Stream`; UDP and Unix-domain datagrams use
`IO::Sock::Dgram`.

## Private implementation boundaries

Private implementation packages include:

```text
Linux::Event::_IO
Linux::Event::_ByteStream
Linux::Event::_ByteStream::Descriptor
Linux::Event::_Socket
Linux::Event::_Socket::Stream
Linux::Event::_Socket::Listener
Linux::Event::_Socket::Dgram
Linux::Event::_Socket::Descriptor
```

These are implementation boundaries only. Applications must not construct or
subclass them.

Private behavioral hierarchies use single inheritance. A connected stream
socket fundamentally specializes the ordered-byte engine, so
`Linux::Event::_Socket::Stream` inherits only `Linux::Event::_ByteStream` and
composes its socket descriptor, connection, configuration, address, and
transport facilities. Private inheritance does not encode every conceptual
category relationship.

Private implementation and XS ABI surfaces use the same coherent taxonomy:
leading-underscore packages for shared IO/socket mechanics and `Kernel::*` for
kernel resources. They are not advertised as public modules.

## Reactor hot path

The steady-state readiness path is intentionally short:

```text
epoll_wait()
   |
   v
epoll_event.data.ptr
   |
   v
le_watcher_t *
   |
   v
XS dispatch
   |
   v
semantic callback
```

There is no fd-to-Perl-hash lookup after `epoll_wait()` returns.
`epoll_event.data.ptr` identifies the native watcher directly. The fd-indexed
registry remains for registration, replacement, cancellation, ownership, and
introspection.

A plain coderef callback is retained as its CV rather than through an
additional RV wrapper. The dispatcher uses bounded temporary scopes and
rechecks watcher state after each callback so cancellation or replacement takes
effect inside the current epoll batch.

Terminal readiness is dispatched in this order:

```text
EPOLLERR / EPOLLHUP / EPOLLRDHUP
EPOLLIN
EPOLLOUT
```

A replacement registration updates epoll to the new native record and makes
the old opaque handle inert. Cancelling a stale handle cannot remove a newer
registration for a reused fd.

## Loop ownership

`Linux::Event::Loop` owns:

- the epoll fd;
- the reusable epoll event array;
- native watcher records and fd registry;
- stop and callback-scope state;
- timer scheduler state;
- private service registrations such as signalfd and resolver eventfd;
- cheap counters and optional profiling timing.

High-level objects attach directly to a Loop. There is no public generic
Watcher object between a semantic resource and epoll. Raw `watch()` and
`watch_fd()` return opaque native registration handles.

One logical application object may own several kernel descriptors. For example,
a pending stream-socket connection can own connection-attempt and deadline
resources before the final connected socket is attached. Introspection reports
the logical object and can separately report its backing native resources.

## Ordered-byte engine

`IO::Pipe`, `IO::TTY`, and `IO::Sock::Stream` share one private ordered-byte
engine. The sharing is an implementation fact, not a public generic Stream
class.

The engine owns:

- shared or split read/write descriptors;
- nonblocking and close-on-exec preparation;
- native read draining;
- immediate writes and segmented queued output;
- high/low watermark backpressure;
- hard pending-output limits;
- raw callback batching;
- framed input storage and parsers;
- framed message batching;
- pause/resume state;
- independent read and write lifecycle;
- established idle/read/write deadlines;
- explicit operation deadlines;
- native consumer integration;
- in-place protocol transitions.

One immutable descriptor is cached for each concrete subclass. It contains the
resolved named callback CVs, tuning policy, framing definition, optional native
consumer definition, and native descriptor object. Per-instance state contains
changing transport, fd, parser, queue, deadline, and lifecycle data plus any
constructor-supplied effective callback CVs.

This preserves the performance reason Linux::Event uses class-defined policy:
repeated method/configuration lookup is not added to each readiness event. A
constructor closure replaces the corresponding class CV once in per-object
state and then uses the same direct native invocation path.

### Native implementation

The XS ordered-byte implementation is built from focused translation units:

```text
Stream.xs
stream_state.c
stream_transport.c
stream_callbacks.c
stream_input.c
stream_delivery.c
stream_consumer.c
stream_read.c
stream_write.c
stream_transition.c
framer_*.c
```

These files link into one XS extension. Splitting source files does not create
additional dynamic-loading or Perl dispatch boundaries.

The XS packages under `Linux::Event::_ByteStream::*` are private native ABI
details. They do not define the public class hierarchy.

## Framing

Framing is an ordered-byte capability, not a socket capability. A delimiter,
length-prefix, fixed-size, netstring, varint, or decimal-length parser is just as
valid over a pipe or terminal input as over a stream socket.

A raw native state caches one effective `on_data` CV. A framed state caches one
effective `on_message` CV, or `on_messages` when message batching is enabled.
The CV comes from the class descriptor or a constructor callback; dispatch does
not branch on its origin. Native parsing crosses into Perl only at complete
semantic delivery boundaries or errors.

Serialization remains one layer above framing:

```text
bytes -> buffering -> framing -> message bytes -> codec -> Perl value
```

The codec layer is intentionally not conflated with kernel I/O or framing.

## Protocol transitions

`transition_to()` swaps the immutable ordered-byte descriptor while preserving
the live native state, descriptors, unread input, queued output, backpressure,
pause state, deadlines, and application data.

The native transition validates the new descriptor before callbacks are
allowed to continue. Buffered unread input is then interpreted using the new
parser. The transition cannot change the underlying resource category or
native consumer provider.

A connected stream socket therefore remains a connected stream socket across a
protocol transition; only its application protocol/framing class changes.

## Stream-socket layer

`Linux::Event::IO::Sock::Stream` adds socket-specific semantics around the
private ordered-byte engine:

- socket type validation;
- outbound nonblocking connection acquisition;
- local and peer addresses;
- socket option policy;
- kernel `shutdown()` semantics;
- optional TLS transport lifecycle.

Socket type and address family remain separate axes. A Unix-domain
`SOCK_STREAM` and an Internet `SOCK_STREAM` use the same public leaf.

### Outbound acquisition

The private connection engine validates address modes, resolves hostnames when
needed, creates nonblocking close-on-exec sockets, applies policy, and checks
`SO_ERROR` after writable readiness.

`MyConnection->connect()` creates the one application-visible stream-socket
object before acquisition begins. The object is not replaced after success.
Immediate success and immediate operational failure are still delivered through
the Loop rather than reentrantly from the constructor.

Hostname resolution uses a private native resolver service. Numeric, packed,
and Unix addresses bypass DNS.

## TLS transport

TLS is transport policy for `IO::Sock::Stream` subclasses. It does not create a
second public socket hierarchy.

The native transport table lets the same buffering, framing, backpressure, and
lifecycle machinery operate on plaintext while OpenSSL owns handshake,
cryptography, verification, ALPN, retry direction, and close notification.

The plain transport retains a specialized direct syscall path; ordinary socket
I/O does not pay a Perl callback or generic transport-object dispatch cost.

## Listener layer

`Linux::Event::IO::Sock::Listener` is a separate public leaf because a listening
socket has accept-oriented semantics rather than connected byte-stream
semantics.

The listener owns:

- socket creation or adoption;
- bind/listen configuration;
- one read registration for the listening descriptor;
- bounded `accept4()` draining;
- accepted connection construction;
- optional `on_accept` policy;
- listener-specific error and cleanup behavior.

Accepted descriptors are created with `SOCK_NONBLOCK | SOCK_CLOEXEC`. The
listener constructs the configured `IO::Sock::Stream` subclass directly; it
does not create a temporary accepted-socket watcher first.

TLS server policy is validated before accepting traffic and each accepted
connection receives independent OpenSSL connection state.

## Datagram layer

`Linux::Event::IO::Sock::Dgram` uses a separate packet engine because datagram
boundaries are semantic and must not be flattened into an ordered byte stream.

Receive readiness drains `recvmsg(MSG_DONTWAIT | MSG_TRUNC)` into packet
records containing payload, peer address, and truncation information. Output
queues retain whole packets with independent byte and packet accounting.

Connected hostname mode can reuse the resolver service with `SOCK_DGRAM` hints,
but datagrams do not reuse the ordered-byte parser or stream connection race.

## Pipe and TTY leaves

`IO::Pipe` and `IO::TTY` use the ordered-byte engine but validate their actual
resources at construction.

`IO::Pipe` accepts pipe/FIFO descriptors. `IO::TTY` accepts terminal or PTY
descriptors. Both may be read-only, write-only, or use distinct read and write
descriptors when the logical facility supports that shape.

This validation is deliberate: public leaf names should tell the truth about
the underlying resource rather than act as arbitrary buffer-engine selectors.

## Timer scheduler

Every Loop lazily creates one nonblocking close-on-exec timerfd when its first
scheduled timer is attached. Active timers share an indexed native minimum
heap ordered by monotonic deadline.

Each concrete `Kernel::Timer` subclass contributes one cached callback
descriptor. A constructor `on_timer` closure creates one effective per-object
descriptor and overrides the class method without changing dispatch. Instances
contain mutable schedule, heap position, application data, lifecycle, and
expiration count.

Equal deadlines preserve schedule order. Fixed-rate repeating timers advance
from their prior deadline and coalesce missed intervals. Dispatch uses a bound
so timer floods cannot monopolize a Loop turn.

Established ordered-byte deadlines reuse the timer scheduler through a private
timer object. Activity timestamps are enabled only when inactivity policy is
active, so ordinary byte streams do not pay activity-clock overhead.

## Signal layer

`Kernel::Signal` uses one private nonblocking signalfd per Loop with a native
fan-out registry. Several objects may subscribe to the same signal number and
one object may subscribe to several numbers.

The native service drains complete signalfd batches, aggregates counts, and
then enters Perl at semantic callbacks. Subscriber snapshots permit safe
self-cancellation or cross-cancellation during dispatch.

Linux::Event records signal-mask state and restores only mask entries it
changed when the last relevant subscription is removed.

## Event layer

`Kernel::Event` is backed by eventfd. The public callback is
`on_event($event, $count)` and the public signaling operation retains eventfd
counter semantics.

The owning Loop and callback state remain interpreter-local. Supported foreign
threads, forked children, or native code can signal the eventfd, while payloads
remain in an explicit thread-safe queue or IPC mechanism owned by the
application.

`Linux::Event::Kernel::Event` directly hosts this eventfd machinery.

## Process layer

`Kernel::Process` uses native process spawning and pidfd lifecycle tracking.
No Perl executes in a post-fork child path.

A Process can own pidfd, stdin, stdout, and stderr resources while remaining one
logical application object. Output pipes use dedicated native draining,
queued stdin uses SIGPIPE-safe writes, and signals use `pidfd_send_signal` so
numeric PID reuse cannot target an unrelated process.

Setup failure after spawn tears down the exact child before returning the
failure.

## Introspection

Introspection queries authoritative native and service state only when asked.
It does not maintain a duplicate public-object registry in readiness dispatch.

Object, resource, liveness, census, and pressure queries derive their answers
from existing Loop, timer, signal, resolver, and resource ownership state.
Optional profiling adds timing instrumentation only when explicitly enabled.

Public introspection types follow the IO/Kernel taxonomy: `pipe`, `tty`,
`stream`, `listener`, `dgram`, `timer`, `signal`, `event`, and `process`.
Here `stream` means `IO::Sock::Stream`; Pipe and TTY remain distinct public
resource types even though they share the ordered-byte engine.

## Performance constraints on architecture

The architecture is intentionally constrained by measured performance:

- no public generic dispatcher in the readiness hot path;
- no constructor closure required for each semantic callback;
- named subclass CVs are cached once per concrete type and optional constructor
  CVs once per object;
- no fd-to-Perl-hash lookup after `epoll_wait()`;
- framing and queue work stays native until semantic delivery;
- the plain transport uses direct syscalls;
- optional diagnostics and timing do not add ordinary hot-path bookkeeping;
- source-code modularity must not create extra Perl or dynamic-loading layers.

Public semantic correctness and implementation performance are therefore
separate concerns: Linux::Event can present precise resource leaves while
sharing aggressively optimized private machinery underneath them.
