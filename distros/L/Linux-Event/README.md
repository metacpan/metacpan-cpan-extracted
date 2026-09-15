# Linux::Event

[![CPAN version](https://badge.fury.io/pl/Linux-Event.svg)](https://metacpan.org/dist/Linux-Event)
[![CPANTS Kwalitee](https://cpants.cpanauthors.org/dist/Linux-Event.svg)](https://cpants.cpanauthors.org/dist/Linux-Event)
[![CI](https://github.com/haxmeister/perl-linux-event/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-linux-event/actions/workflows/ci.yml)
[![License](https://img.shields.io/cpan/l/Linux-Event.svg)](https://github.com/haxmeister/perl-linux-event/blob/main/LICENSE)
[![Perl](https://img.shields.io/badge/perl-5.36%2B-blue.svg)](https://www.perl.org/)

Linux::Event is a Linux-only asynchronous I/O foundation for Perl. It combines
an XS-first `epoll` reactor with native buffered byte I/O, stream and datagram
sockets, listeners, framing, OpenSSL TLS, timerfd scheduling, signalfd signal
delivery, eventfd notification, and pidfd process lifecycle support.

The public API names the Linux resource the application is actually using.
Shared buffering, framing, descriptor, and socket machinery remains private.

## Public architecture

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
|-- Kernel
|   |-- Timer
|   |-- Signal
|   |-- Event
|   `-- Process
|-- Framer
|-- TLS
|-- Error
`-- Address
```

`Linux::Event::IO` and `Linux::Event::Kernel` are namespace categories, not
constructible base classes. The namespace tree describes the public semantic
model; it does not imply that every level is a Perl inheritance layer.

The principal public classes are:

- `Linux::Event::Loop` - XS-first epoll reactor and object attachment.
- `Linux::Event::IO::Pipe` - ordered byte I/O over anonymous pipes and FIFOs.
- `Linux::Event::IO::TTY` - ordered byte I/O over terminals and PTYs.
- `Linux::Event::IO::Sock::Stream` - connected `SOCK_STREAM` sockets.
- `Linux::Event::IO::Sock::Listener` - listening `SOCK_STREAM` sockets.
- `Linux::Event::IO::Sock::Dgram` - `SOCK_DGRAM` sockets preserving packets.
- `Linux::Event::Kernel::Timer` - monotonic timer behavior.
- `Linux::Event::Kernel::Signal` - synchronous signalfd subscriptions.
- `Linux::Event::Kernel::Event` - eventfd notifications.
- `Linux::Event::Kernel::Process` - pidfd lifecycle and native process spawning.
- `Linux::Event::Framer` - native framing declarations for ordered byte I/O.
- `Linux::Event::TLS` - OpenSSL TLS policy for stream-socket subclasses.
- `Linux::Event::Error` - structured failure values.
- `Linux::Event::Address` - lazy IPv4, IPv6, and Unix socket addresses.

Implementation packages beginning with `_`, plus the historical internal
`Stream`, `Socket`, `Listener`, `Datagram`, `Timer`, `Signal`, `Wakeup`, and
`Process` package names, are not the public application API.

## Constructor callbacks and subclass policy

Public Event, Timer, Signal, Process, Datagram, Pipe, TTY, and connected Stream
objects accept application callbacks as constructor coderefs. Closures retain
ordinary lexical scope and override same-named subclass methods for that one
object. Linux::Event resolves the effective callback during construction; it
does not add method lookup or a method-versus-closure decision to delivery.

Subclassing remains a prominent Linux::Event feature. A reusable subclass can
declare native framing, TLS, socket policy, and Stream, Datagram, or Process
tuning once. That class policy and its named callbacks are validated and cached
once per subclass. A common design is therefore class-level protocol and tuning
plus constructor closures for per-instance application state.

## Installation

```sh
cpanm Linux::Event
```

Building requires Linux, a C compiler, and OpenSSL development files. The
distribution requires Perl 5.36 or newer.

## The reactor

`Linux::Event::Loop` owns epoll registrations and scheduled activity. High
level objects can be attached at construction:

```perl
my $object = MyType->new(
    loop => $loop,
    # ...
);
```

or constructed first and attached later:

```perl
my $object = MyType->new(...);
$loop->add($object);
```

`add()` returns the same object. Low-level applications can also use
`$loop->watch(...)` or `$loop->watch_fd(...)` directly. Those methods return
opaque native registrations rather than public watcher objects.

## Stream socket server

A connected socket protocol can subclass the concrete stream-socket leaf when
framing, tuning, socket policy, or shared method callbacks belong to a reusable
protocol type:

```perl
use v5.36;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;

{
    package EchoConnection;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";

    sub on_message ($self, $message) {
        $self->send($message);
    }
}

my $loop = Linux::Event::Loop->new;

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 9999,
    stream => {
        class => 'EchoConnection',
    },
);

$loop->run;
```

Raw callbacks and lifecycle callbacks may also be supplied directly. They are
ordinary Perl closures, so application lexicals remain in scope without
requiring a connection subclass just to carry callback state:

```perl
my $database = connect_database();

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 9999,
    stream => {
        on_data => sub ($stream, $bytes) {
            store_bytes($database, $stream, $bytes);
            $stream->write($bytes);
        },
    },
);
```

Constructor callbacks override the corresponding subclass methods for that
object. The effective `on_data`, `on_message`, or `on_messages` CV is retained
once in native per-connection state and invoked directly; steady-state input
does not perform callback lookup or method-versus-closure branching. A Listener
retains one supplied callback and shares that CV with its accepted Streams.

The ordered-byte constructor callback surface is `on_data`, `on_message`,
`on_messages`, `on_drain`, `on_eof`, `on_error`, and `on_close`.
`IO::Sock::Stream` additionally supports `on_ready` and
`on_transport_ready`. Raw mode uses `on_data`; framed mode uses `on_message`,
or `on_messages` when `message_batch_size` is enabled. These modes are
validated during construction.

Kernel resources use the same complementary model: Event accepts `on_event`,
Timer accepts `on_timer`, Signal accepts `on_signal`, and Process accepts
`on_exit`, `on_error`, and, for spawned children, its optional stdio callbacks.
Datagram accepts `on_datagram`, `on_ready`, `on_drain`, `on_error`, and
`on_close`.

`examples/first-class-line-echo-server.pl` is a complete framed server whose
Listener reuses one lexical `on_message` closure for every accepted Stream.

`Linux::Event::IO::Sock::Stream` represents the socket type, not its address
family. TCP over IPv4 or IPv6 and Unix-domain `SOCK_STREAM` sockets share the
same leaf. Address family is selected by construction options.

The same stream-socket subclass is used for outbound connections:

```perl
my $client = EchoConnection->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => 9999,
);
```

The object exists before, during, and after nonblocking connection acquisition.
There is no separate public Connector object.

## Interactive STDIN and STDOUT

Interactive terminal I/O uses the TTY leaf. Read and write handles may be
different descriptors while still forming one logical ordered-byte object:

```perl
use v5.36;
use Linux::Event::Loop;
use Linux::Event::IO::TTY;

{
    package Console;
    use parent 'Linux::Event::IO::TTY';
    use Linux::Event::Framer 'Delimiter', "\n";

    sub on_message ($self, $line) {
        $self->write("You typed: $line\n");
    }
}

my $loop = Linux::Event::Loop->new;
my $console = Console->new(
    loop     => $loop,
    read_fh  => \*STDIN,
    write_fh => \*STDOUT,
);

$loop->run;
```

`IO::TTY` validates that every supplied handle is a terminal. If input is an
anonymous pipe or FIFO, use `IO::Pipe` instead. Public leaf names are intended
to describe the actual underlying Linux resource rather than merely select a
buffer implementation.

## Pipes and FIFOs

`Linux::Event::IO::Pipe` supports read-only, write-only, or paired pipe handles:

```perl
{
    package PipeReader;
    use parent 'Linux::Event::IO::Pipe';

    sub on_data ($self, $bytes) {
        print "received $bytes";
    }
}

pipe(my $read_fh, my $write_fh) or die "pipe: $!";

my $reader = PipeReader->new(
    loop    => $loop,
    read_fh => $read_fh,
);

syswrite($write_fh, "hello\n");
$loop->run_for(0.1);
```

The same native ordered-byte machinery backs pipes, TTYs, and stream sockets,
but that implementation sharing is intentionally not exposed as a generic
public `Stream` class.

## Framing

Framing belongs to ordered byte I/O, not specifically to networking. The same
framer declaration can therefore be used by `IO::Pipe`, `IO::TTY`, or
`IO::Sock::Stream` subclasses.

Built-in framers include:

- `Delimiter`
- `Fixed`
- `LengthPrefix`
- `U32BE`
- `Netstring`
- `Varint`
- `DecimalLength`

Example:

```perl
{
    package Messages;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'LengthPrefix',
        bytes     => 4,
        endian    => 'big',
        max_frame => 16 * 1024 * 1024;

    sub on_message ($self, $message) {
        process_message($message);
    }
}
```

A framed type can call `$self->send($payload)` to apply its outbound framing
rule. Serialization and application codecs remain a separate layer above
framing.

Class-level `stream_tuning()` remains the tuning hook for ordered-byte
behavior. Tuning and method defaults are resolved once per subclass; optional
constructor callbacks select an instance's effective cached CVs.

```perl
sub stream_tuning ($class) {
    return (
        read_size          => 65_536,
        read_budget_bytes  => 0,
        read_batch_bytes   => 0,
        message_batch_size => 0,
        high_watermark     => 1_048_576,
        low_watermark      => 262_144,
        max_pending_bytes  => 0,
        max_buffer         => 8_388_608,
        idle_timeout       => 0,
        read_timeout       => 0,
        write_timeout      => 0,
    );
}
```

`read_batch_bytes` coalesces raw input callbacks. `message_batch_size` switches
a framed type from `on_message` to `on_messages`. Partial batches flush at the
end of the current native read drain; Linux::Event does not wait for a later
readiness event merely to fill the configured batch size.

## TLS

TLS is acquisition policy for stream sockets. A server enables it in the
Listener's generated-Stream recipe, so the same connection class can be used by
both plain and TLS listeners:

```perl
my $secure = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '0.0.0.0',
    port => 9443,
    stream => {
        class => 'EchoConnection',
        tls => {
            cert_file => $cert_file,
            key_file  => $key_file,
            alpn      => ['my-protocol/1'],
        },
    },
);
```

The Listener validates TLS policy and prepares reusable server context once;
accepted connections allocate only their independent connection state. Plain
Listeners allocate no TLS connection state. A Stream subclass may provide
`tls_defaults()` for reusable policy such as ALPN or timeout defaults, but those
defaults do not activate TLS. Outbound TLS remains selected by client
acquisition policy. Framing operates on plaintext after the TLS transport layer.

## Datagram sockets

Datagram sockets use a different public leaf because packet boundaries are
part of their semantics:

```perl
{
    package EchoDatagram;
    use parent 'Linux::Event::IO::Sock::Dgram';

    sub on_datagram ($self, $payload, $peer) {
        $self->send($payload, to => $peer);
    }
}

my $udp = EchoDatagram->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 9000,
);
```

UDP and Unix-domain datagrams share `IO::Sock::Dgram`; address family is again
configuration rather than a separate class axis.

## Kernel facilities

Kernel event and state objects live below `Linux::Event::Kernel`.

A timer subclass defines `on_timer`:

```perl
{
    package Heartbeat;
    use parent 'Linux::Event::Kernel::Timer';

    sub on_timer ($self) {
        say "tick";
    }
}

my $heartbeat = Heartbeat->new(
    loop  => $loop,
    every => 1,
);
```

A signal subclass defines `on_signal` and uses synchronous signalfd delivery:

```perl
use POSIX qw(SIGINT SIGTERM);

{
    package Shutdown;
    use parent 'Linux::Event::Kernel::Signal';

    sub on_signal ($self, $number, $count) {
        $self->loop->stop;
    }
}

my $shutdown = Shutdown->new(
    loop    => $loop,
    signals => [SIGINT, SIGTERM],
);
```

An eventfd notification subclass defines `on_event`:

```perl
{
    package WorkReady;
    use parent 'Linux::Event::Kernel::Event';

    sub on_event ($self, $count) {
        consume_ready_work();
    }
}

my $event = WorkReady->new(loop => $loop);
$event->signal;
```

`Kernel::Event` is suitable for notifying the loop from code that can safely
signal an eventfd, including native code, forked children, and the supported
thread signaling boundary. Application payloads remain in the application's
own queue or IPC mechanism.

`Linux::Event::Kernel::Process` provides native process spawning, pidfd
lifecycle notification, signals, and asynchronous standard I/O.

## Backpressure and deadlines

Ordered-byte I/O writes immediately when possible and queues only the unsent
remainder. `high_watermark` and `low_watermark` provide cooperative
backpressure through `on_drain`. `max_pending_bytes` is an optional hard output
limit.

Established byte streams can use class defaults or per-instance overrides for
idle, read, and write deadlines. An explicit operation deadline can be set with:

```perl
$connection->set_deadline(
    after     => 5,
    operation => 'response',
);
```

and removed with:

```perl
$connection->clear_deadline;
```

Connection, TLS handshake, and established-stream deadlines retain separate
ownership so one timeout layer does not obscure another.

## Introspection

Loop diagnostics query authoritative state only when requested:

```perl
my $objects   = $loop->objects;
my $snapshot  = $loop->inspect($objects->[0]);
my $census    = $loop->census;
my $resources = $loop->resources;
my $reasons   = $loop->why_alive;
my $pressure  = $loop->pressure;
```

Optional profiling is enabled with `$loop->profile(1)`. Ordinary introspection
is designed not to require duplicate hot-path bookkeeping.

## Performance model

Linux::Event keeps the readiness path small:

- native epoll registration and dispatch
- named method callback CVs resolved once in immutable class descriptors
- native read draining, framing, and buffered write queues
- one effective method or constructor CV cached for direct semantic dispatch
- one native ordered-byte state shared by read and write directions
- no public generic dispatch object inserted between the loop and completed
  resource leaf

The benchmark programs below `bench/` exercise reactor dispatch, stream I/O,
framing, listeners, datagrams, timers, processes, callback batching, and
performance-regression baselines.

## Documentation

Architecture and behavior are documented under `docs/`. In particular:

- `docs/IO-KERNEL-ARCHITECTURE.md`
- `docs/ARCHITECTURE.md`
- `docs/FIRST-CLASS-STREAM-CALLBACKS.md`
- `docs/FRAMING.md`
- `docs/CHOOSING-A-FRAMER.md`
- `docs/SOCKET-CONNECTIONS.md`
- `docs/SOCKET-CONFIGURATION.md`
- `docs/LISTENER-DESIGN.md`
- `docs/PROCESS-DESIGN.md`
- `docs/INTROSPECTION.md`

The architecture documents describe public semantics. Historical engineering
roadmaps and benchmark decision logs are development material rather than
public API contracts.

## Platform

Linux only. The complete distribution uses epoll, timerfd, signalfd, eventfd,
pidfd, and other Linux facilities directly. Some features naturally require a
kernel new enough to provide the corresponding syscall behavior.

## License

Linux::Event is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.
