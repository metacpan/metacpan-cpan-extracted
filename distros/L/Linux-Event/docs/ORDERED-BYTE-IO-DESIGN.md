# Ordered byte I/O design

Linux::Event shares one high-performance ordered-byte engine across several
concrete public resources:

```text
Linux::Event::IO::Pipe
Linux::Event::IO::TTY
Linux::Event::IO::Sock::Stream
```

There is deliberately no public generic ByteStream or Stream class in this
semantic model. The common engine is private implementation machinery because
applications should choose the leaf that describes the actual Linux resource.

## Why these resources share machinery

Pipes, terminals, and `SOCK_STREAM` sockets all present an ordered sequence of
bytes to the application. They differ in acquisition and kernel lifecycle
semantics, but the expensive steady-state mechanics are the same:

- nonblocking reads;
- immediate and queued writes;
- partial-write handling;
- backpressure;
- input buffering;
- framing;
- callback batching;
- parser state;
- established deadlines;
- protocol transitions.

Sharing that native machinery preserves performance without forcing the public
API to pretend that a pipe is a socket or that every form of I/O is a stream.

## Handle shapes

The private ordered-byte engine supports these directional forms:

```perl
MyType->new(fh => $duplex_handle);
MyType->new(read_fh => $input, write_fh => $output);
MyType->new(read_fh => $input);
MyType->new(write_fh => $output);
```

A concrete public leaf decides which forms make semantic sense and validates
its handles.

`IO::Pipe` can represent one pipe direction or a logical pair of pipe handles.
`IO::TTY` can use terminal input, terminal output, or both. A connected
`IO::Sock::Stream` uses one shared socket descriptor.

`fh` means one descriptor supplies both directions and cannot be combined with
`read_fh` or `write_fh`. For split objects, `fh()` is undefined while
`read_fh`, `write_fh`, `read_fd`, and `write_fd` remain unambiguous.

Every unique descriptor is made nonblocking and close-on-exec. One shared
descriptor uses one Loop registration. Split read/write descriptors use two
registrations that point at the same native ordered-byte state.

## Native state

The native state contains independent read and write descriptor numbers, which
may be equal or absent for one direction. It still owns exactly one copy of the
expensive mutable mechanisms:

- immutable cached class descriptor reference;
- reusable raw read buffer or framed input storage;
- native parser state;
- optional native consumer context;
- segmented output queue;
- backpressure watermarks;
- optional activity timestamps;
- instrumentation counters.

The ordinary plain path calls `read`, `write`, and `writev` directly. No
reader/writer object pair, engine-generated closure, duplicate output queue,
or extra Perl dispatch layer is introduced.

## Cached class policy

Each concrete subclass receives one immutable descriptor containing:

- resolved named callback CVs;
- `stream_tuning()` values;
- optional framer definition;
- optional native consumer definition;
- native descriptor configuration.

Per-object state retains changing fd, parser, queue, deadline, transport, and
lifecycle data plus any constructor-supplied effective callback CVs.

This is a performance-critical design choice. Method lookup and tuning-policy
assembly occur at the class descriptor boundary. Constructor callbacks are
validated and installed once per object, not selected for every readiness
event or message.

The method name `stream_tuning()` is retained as the public ordered-byte
tuning hook. It describes shared engine policy; it does not imply a public
generic `Linux::Event::Stream` object.

The complete cached option contract is:

| Option | Default | Contract |
| --- | ---: | --- |
| `read_size` | 65,536 | Positive maximum bytes requested by one read |
| `read_budget_bytes` | 0 | Bytes per readiness drain; zero drains to blocking |
| `read_batch_bytes` | 0 | Raw `on_data` batching target; zero disables |
| `message_batch_size` | 0 | Framed `on_messages` batch count; zero disables |
| `max_buffer` | 8,388,608 | Positive retained-input and message-batch byte bound |
| `high_watermark` | 1,048,576 | Cooperative output-backpressure level |
| `low_watermark` | 262,144 | Drain level; no greater than high watermark |
| `max_pending_bytes` | 0 | Hard output-queue limit; zero is unbounded |
| `idle_timeout` | 0 | Seconds without read or write progress; zero disables |
| `read_timeout` | 0 | Seconds without active read progress; zero disables |
| `write_timeout` | 0 | Seconds without queued-write progress; zero disables |

Byte settings are non-negative integers except positive `read_size` and
`max_buffer`. Timeouts are finite non-negative seconds and may be fractional.
`read_batch_bytes` is raw-only; `message_batch_size` is framed-only and
requires `on_messages`.

## Read sink rules

A write-only object does not need an input callback.

A readable raw ordered-byte object requires an `on_data` method or constructor
callback:

```perl
sub on_data ($self, $bytes) {
    ...
}
```

A readable framed class normally defines an `on_message` method, which an
instance may override with a constructor callback:

```perl
sub on_message ($self, $message) {
    ...
}
```

With explicit `message_batch_size`, the corresponding sink is `on_messages`.
A framed class can also bind a supported native consumer. A constructor
callback may supply the required sink even when the class defines no method.

Class contradictions are rejected when the descriptor is built; instance
callback types and mode compatibility are validated during construction.

## Directional lifecycle

Read and write termination are independent normal states.

- Peer/input EOF ends the readable direction and invokes `on_eof`.
- EOF does not end an independent writable direction.
- `end($final_bytes)` accepts optional final output, drains queued bytes, then
  ends the writable direction gracefully.
- `close_read` and `close_write` stop one direction immediately.
- `close` stops the complete object and may discard queued output.
- `on_close` runs once when the complete configured resource becomes terminal.
- `pause_read` and `resume_read` affect only input.

For distinct pipe or terminal handles, ending a direction can close that
specific descriptor.

A shared non-socket descriptor has no universal half-close syscall. The
ordered-byte engine therefore records logical write completion without
inventing kernel semantics that may not exist.

`IO::Sock::Stream` adds the socket-specific mapping to `shutdown()` where
appropriate.

## Detach

Plain ordered-byte resources can transfer descriptor ownership only when the
resource-specific contract permits it and pending output has drained.

The private engine can represent the returned directional handles as:

```perl
{
    read_fh  => $read_handle_or_undef,
    write_fh => $write_handle_or_undef,
}
```

A stream socket has one shared descriptor and its public socket layer can expose
the appropriate socket-shaped detach result.

Non-plain transports such as TLS cannot detach a bare descriptor while native
provider state is still coupled to it.

## Writes and backpressure

`write()` first attempts a native write immediately. EPOLLOUT interest is
enabled only after partial output or EAGAIN and disabled again when the queue
empties.

`high_watermark` and `low_watermark` implement cooperative backpressure.
`max_pending_bytes` is an optional hard limit.

The same queue and watermark behavior applies during outbound stream-socket
connection acquisition so applications do not need a second preconnection
output API.

## Framing

Framing is a property of ordered bytes, not of sockets. The same native framing
families can therefore be declared by pipe, terminal, and stream-socket
subclasses.

`send()` applies the declared outbound framing rule and then enters the same
native write engine.

Serialization remains above framing:

```text
bytes -> framing -> message bytes -> codec -> Perl value
```

See `FRAMING.md` for wire contracts and parser behavior.

## Raw and framed batching

A raw class can set `read_batch_bytes` to combine successful reads before
`on_data`. A framed class can set `message_batch_size` to deliver a bounded
array through `on_messages`.

Partial batches flush when the current native drain ends. Linux::Event does not
wait for future readiness merely to fill the configured batch size.

The zero defaults preserve ordinary callback boundaries without array creation.

## Deadlines

Idle, read, write, and explicit operation deadlines are ordered-byte policy and
therefore can apply to any appropriate public leaf using this engine.

Deadline candidates exist only for configured and active directions. Activity
timestamps are enabled only when inactivity policy is active, so ordinary
objects do not pay clock-reading overhead.

Connection acquisition deadlines and TLS handshake/shutdown deadlines belong
to the stream-socket acquisition/transport layers rather than this established
ordered-byte layer.

## Protocol transitions

`transition_to()` changes the cached protocol descriptor while retaining the
same native ordered-byte state, descriptors, buffered input, output queue,
backpressure state, deadlines, and application data.

The target must represent the same underlying resource category. Protocol
transition must not silently turn a pipe into a socket or a connected socket
into a TTY.

Unread native input is interpreted by the target framing policy after the
transition. Existing queued output is not reframed.

## Socket specialization

`IO::Sock::Stream` adds semantics that do not belong to generic ordered bytes:

- connected `SOCK_STREAM` validation;
- outbound connection acquisition;
- socket addresses;
- socket option policy;
- `configure_socket` hook;
- kernel `shutdown()` behavior;
- TLS transport declaration and negotiated-state accessors.

TCP, Unix-domain stream sockets, and socketpairs share this leaf because they
share `SOCK_STREAM` semantics. Address family remains configuration.

## Private implementation boundaries

The public API is `IO::Pipe`, `IO::TTY`, and `IO::Sock::Stream`. Their shared
implementation and socket specialization live beneath:

```text
Linux::Event::_ByteStream
Linux::Event::_ByteStream::Descriptor
Linux::Event::_Socket::Stream
Linux::Event::_Socket::Descriptor
```

Those internal names are `no_index`, are excluded from META
`provides`, and are not the public subclassing contract.

The coherent private names are used directly by the native hot path without
adding dynamic-loading boundaries or Perl indirection.

## Native consumer ABI

The framed-message native consumer ABI belongs to the private ordered-byte
engine and remains independent of Linux::Event::Async. Stream-socket subclasses
use the same consumer mechanism; there is no socket-specific duplicate path.

ABI versioning, borrowed message ownership, pause/resume semantics, and
terminal-event contracts are stable private native contracts. External
consumers declare through the public `Linux::Event::Framer` boundary rather
than depending on the historical Stream application name.

## Performance invariant

The current architecture preserves the performance properties that drove the
existing implementation:

- one native mutable state per logical ordered-byte object;
- one cached immutable descriptor per concrete class;
- direct cached CV callback invocation;
- direct plain `read`/`write`/`writev` syscalls;
- no per-message framer objects;
- constructor closures and subclass methods share one native callback path;
- no generic public dispatch layer;
- one watcher for the common single-fd stream-socket path.

Any future physical source or XS package rename should be benchmarked as an
implementation refactor, not assumed to be free merely because public semantics
would remain unchanged.
