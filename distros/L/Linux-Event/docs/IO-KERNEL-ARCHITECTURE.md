# Linux::Event IO and Kernel Architecture

## Status

This document describes the public architecture introduced in Linux::Event
0.110. The IO and Kernel namespaces are the supported application model. The
private implementation and native ABI names now follow that same taxonomy and
are not application subclassing or construction surfaces.

## Public namespace model

Linux::Event separates application data I/O from kernel event/state
abstractions.

```text
Linux::Event
|-- IO
|   |-- Pipe
|   |-- TTY
|   `-- Sock
|       |-- Stream
|       |-- Listener
|       |-- Dgram
|       `-- SeqPacket       future
|
|-- Kernel
|   |-- Timer
|   |-- Signal
|   |-- Event
|   `-- Process
|
|-- Loop
|-- Error
|-- Address
|-- Framer
`-- TLS
```

The namespace is semantic rather than an inheritance declaration. Public leaf
classes name concrete facilities that applications use. Shared implementation
behavior lives behind private classes or helpers and does not define the public
taxonomy.

## IO branch

`Linux::Event::IO` is a namespace category, not an instantiable generic I/O
object.

### IO::Pipe

Represents pipe-like ordered-byte I/O. It may have a readable handle, a
writable handle, or both. Two handles need not be the same descriptor.
Anonymous pipes and FIFOs are the primary direct use cases; process stdio uses
the same Linux pipe semantics through `Kernel::Process`.

### IO::TTY

Represents terminal and pseudo-terminal ordered-byte I/O. It may have a
readable handle, a writable handle, or both. Terminal configuration remains a
terminal concern rather than a reason to duplicate the common ordered-byte
engine.

### IO::Sock::Stream

Represents `SOCK_STREAM` socket I/O. IPv4, IPv6, and Unix-domain addressing
are socket-family configuration rather than different stream classes.
Connected stream sockets use the common ordered-byte engine plus socket
semantics.

### IO::Sock::Listener

Represents a listening `SOCK_STREAM` socket. It is a separate Linux::Event
public object because its useful interface is bind/listen/accept rather than
connected-byte processing. Namespace placement states that it is a socket
role; it does not imply inheritance from `IO::Sock::Stream`.

### IO::Sock::Dgram

Represents `SOCK_DGRAM` sockets. Datagram boundaries are kernel-provided, so
ordered-byte framing is not part of this class.

### IO::Sock::SeqPacket

Reserved for future `SOCK_SEQPACKET` support. Kernel message boundaries make
ordered-byte framing inappropriate there as well.

## Kernel branch

The Kernel branch exposes Linux::Event abstractions over Linux kernel
notification/state facilities. The public names describe the abstraction,
while the backing fd mechanism remains an implementation fact.

- `Kernel::Timer` uses timerfd-backed scheduling machinery.
- `Kernel::Signal` uses signalfd-backed signal delivery.
- `Kernel::Event` uses eventfd-backed counter/notification semantics.
- `Kernel::Process` uses pidfd lifecycle observation and also owns Linux::Event
  process spawning and asynchronous stdio behavior.

`Process` is intentionally richer than a pidfd wrapper.

## Private behavior layers

The private behavioral inheritance paths are:

```text
Linux::Event::_IO
|-- Linux::Event::_ByteStream
|   `-- Linux::Event::_Socket::Stream
`-- Linux::Event::_Socket
    |-- Linux::Event::_Socket::Listener
    `-- Linux::Event::_Socket::Dgram
```

This is an implementation taxonomy only.

### _IO

Shared descriptor/reactor/lifecycle mechanics for application I/O facilities.
It is not a public catch-all object.

### _ByteStream

Shared ordered-byte behavior used where message boundaries are not supplied by
the kernel:

- readable and writable directions;
- one shared handle or split directional handles;
- nonblocking read/write machinery;
- input buffering;
- output queues and drain notification;
- high/low watermarks and output limits;
- pause/resume;
- framing;
- message batching;
- established deadlines;
- EOF and directional lifecycle.

`IO::Pipe`, `IO::TTY`, and `IO::Sock::Stream` all use this behavior without
claiming that one public facility is a subtype of another.

Their effective application callbacks can come from cached subclass methods or
constructor coderefs. Constructor callbacks replace the corresponding method
once per object and use the same native dispatch slot; see
`FIRST-CLASS-STREAM-CALLBACKS.md`.

### _Socket

Shared behavior that exists because a descriptor is a socket:

- socket type validation;
- socket family and address handling;
- socket creation/configuration;
- socket options;
- common ownership/lifecycle support.

Connected stream sockets do not inherit this branch. Their fundamental
behavior is ordered-byte processing, so `Linux::Event::_Socket::Stream`
single-inherits `Linux::Event::_ByteStream` and composes the socket descriptor,
connection, configuration, address, and transport facilities it needs.

Private inheritance represents behavioral specialization rather than every
conceptual "is a" relationship. Orthogonal capabilities are composed.

Connection acquisition, listen/accept, stream-byte processing, and datagram
processing stay in their specialized private layers.

## Private implementation boundaries

Private packages use leading-underscore names such as `_ByteStream` and
`_Socket`; kernel implementations live under their public `Kernel::*` class.
They are `no_index`, are excluded from META `provides`, and must not be used as
the application API. The public contract is defined by the IO and Kernel leaves
above, not by private XS package names.

## Architecture invariants

Changes to this architecture must preserve these rules:

1. Public classes name concrete Linux resources or lifecycle roles.
2. Socket type and socket address family remain separate axes.
3. Shared implementation belongs behind private boundaries, not generic public
   base objects.
4. Behavioral implementation hierarchies use single inheritance; orthogonal
   facilities use explicit composition.
5. Public subclasses may own ordinary instance state; the core does not
   interpret or manage that state.
6. Public examples, POD, design documents, benchmarks, and diagnostics use the
   IO/Kernel taxonomy.
7. Private implementation and native ABI names follow the coherent taxonomy.
8. API changes that can affect hot paths require the full test matrix,
   distribution checks, and performance-regression suite.
