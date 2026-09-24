# Core Reactor Guide

This document describes the low-level Linux::Event XS reactor. Applications
that want resource ownership should normally choose a concrete public leaf
below `Linux::Event::IO` or `Linux::Event::Kernel` instead of implementing fd
lifecycle themselves.

## Mental model

Linux::Event separates readiness from I/O policy:

```text
kernel epoll
    |
    v
Linux::Event::Loop
    |
    v
opaque native registration
    |
    +-- error callback   EPOLLERR / EPOLLHUP / EPOLLRDHUP
    +-- read callback    EPOLLIN
    `-- write callback   EPOLLOUT
```

The reactor tells you what can be attempted. A raw callback decides whether to
`sysread`, `syswrite`, accept, drain a Linux fd, or perform another operation
appropriate to that descriptor.

Higher-level public leaves own those policies for common resources:

```text
Linux::Event::IO::Pipe
Linux::Event::IO::TTY
Linux::Event::IO::Sock::Stream
Linux::Event::IO::Sock::Listener
Linux::Event::IO::Sock::Dgram
Linux::Event::Kernel::Timer
Linux::Event::Kernel::Signal
Linux::Event::Kernel::Event
Linux::Event::Kernel::Inotify
Linux::Event::Kernel::Process
```

`IO` and `Kernel` are namespace categories, not public base objects.

## Constructing a loop

```perl
use Linux::Event::Loop;
my $loop = Linux::Event::Loop->new;
```

Each Loop owns one epoll instance, its native fd registry, scheduled timer
state, and the private registrations used by attached higher-level resources.
Concrete public objects can accept `loop => $loop` or attach later through:

```perl
$loop->add($object);
```

`add()` returns the same object.

## Registering a handle directly

Normal raw application code should label the watched resource explicitly:

```perl
my $registration = $loop->watch(
    fh   => $fh,
    data => { connection_id => 42 },
    read => sub ($registration) {
        my $count = sysread($registration->fh, my $bytes, 8192);
        $registration->cancel if defined($count) && $count == 0;
    },
    write => sub ($registration) {
        $registration->disable_write;
    },
    error => sub ($registration) {
        $registration->cancel;
    },
);
```

The returned value is an opaque native registration handle. Its internal class
name is not public and it must not be subclassed.

Supplying `fh` lets Linux::Event retain the handle and resolve its integer fd
once at registration. If only an integer descriptor is available:

```perl
my $registration = $loop->watch(
    fd   => $fd,
    read => sub ($registration) { $registration->cancel },
);
```

Exactly one of `fh` or `fd` is required. A registration created from `fd`
alone has no retained filehandle, so `$registration->fh` is `undef`.

The lower-level positional form remains available:

```perl
$loop->watch_fd($fd, read => sub ($registration) {
    $registration->cancel;
});
```

`watch_fd` is useful for internal code and measured registration-heavy
workloads. `watch()` and `watch_fd()` create the same native readiness record
and have the same steady-state dispatch path.

## Registration replacement and lifetime

One active registration is allowed per integer fd. Registering the fd again
replaces the old native record. The old opaque handle becomes inert and cannot
cancel or alter the replacement even if the kernel later reuses the fd number.

Cancellation and Loop destruction release retained Perl state as soon as no
active callback is dispatching through the registration.

## Callback order

For one returned epoll event the dispatch order is:

1. terminal/error callback
2. read callback
3. write callback

The registration is rechecked after every callback. Self-cancellation can
therefore prevent later readiness types for the same returned event.

## Reading until EAGAIN

A level-triggered raw callback normally drains the fd:

```perl
read => sub ($registration) {
    my $fh = $registration->fh;

    while (1) {
        my $buf = '';
        my $n = sysread($fh, $buf, 8192);

        if (!defined $n) {
            last if $!{EAGAIN} || $!{EWOULDBLOCK};
            $registration->cancel;
            last;
        }

        if ($n == 0) {
            $registration->cancel;
            last;
        }

        handle_bytes($buf);
    }
},
```

The repeated Perl syscall, buffering, queue, and lifecycle work is intentionally
visible in this low-level API. The ordered-byte engine used by
`IO::Pipe`, `IO::TTY`, and `IO::Sock::Stream` moves those mechanics into native
code when Linux::Event should own them.

## Writable interest

Raw code should generally enable writable readiness only while output is
blocked:

```perl
$registration->enable_write;
$registration->disable_write;
```

The ordered-byte public leaves manage this transition automatically through
their native write queue.

## Deferred owner-interpreter work

Protocol and lifecycle code that must complete outside the initiating callback
stack can queue work on the owning Loop:

```perl
my $pending = $loop->defer(sub {
    apply_completed_transition();
});
```

`defer()` never invokes the callback inline. Eligible callbacks run FIFO.
Callbacks deferred while a deferred drain is already executing wait for a later
Loop turn. The opaque handle supports `cancel()` and `is_active()`; dropping
the handle does not cancel pending work.

A drain examines at most 1,024 queue entries. If work remains, the private
eventfd source is signaled again so Linux readiness can interleave with a
self-scheduling deferred chain. Callback exceptions propagate normally after
the remaining queue is re-armed, allowing the caller to catch the exception
and drive the Loop again.

Deferred callbacks are owned by the creating Perl interpreter. `defer()` is
not a cross-thread or cross-process callback-posting API. Use
`Linux::Event::Kernel::Event` plus an appropriate payload queue or IPC channel
when another execution context must wake the Loop.

## Driving the loop

### Foreign-loop integration

Another event system can own the application's top-level loop and drive
Linux::Event through one fd:

```perl
my $fd = $loop->poll_fd;

# Register $fd for level-triggered read readiness in the foreign loop.
# From that readiness callback:
my $events = $loop->poll;
```

`poll_fd()` is the Loop-owned epoll descriptor. It becomes readable when any
Linux::Event-owned kernel source is ready, including ordinary I/O, timerfd,
signalfd, pidfds, eventfd notifications, and inotify filesystem events. The descriptor is borrowed; do not
close it. Duplicate it first if the foreign API requires ownership of a Perl
filehandle.

`poll()` performs exactly one nonblocking epoll wait and dispatches that batch.
It is intentionally a separate public contract from `run_once(0)`, even though
both use the same native readiness path. Foreign adapters should watch
`poll_fd()` with level-triggered semantics and call `poll()` once per host-loop
readiness callback. If more work remains than one event batch can hold, the
epoll fd remains readable for a later host-loop turn. An interrupted native
wait is treated as an empty turn; other native wait failures throw, and callback
exceptions propagate after driver state is restored.

Linux::Event does not depend on or take ownership of the foreign loop. Adapters
for EV/AnyEvent, IO::Async, Mojo, or other event systems belong outside core.

Persistent drive:

```perl
$loop->run;
```

Stop from a callback:

```perl
$loop->stop;
```

Single iteration:

```perl
my $events = $loop->run_once(-1);  # block indefinitely
my $events = $loop->run_once(0);   # poll
my $events = $loop->run_once(50);  # wait at most 50 ms
```

Bounded drive:

```perl
$loop->run_for(0.250);
```

`run_for` uses a monotonic deadline. Only one driver method may be active on a
particular Loop. Recursive drive of the same Loop throws; a callback may drive
a different Loop. Callback exceptions propagate after Loop driver and dispatch
state has been restored.

## No-argument fast callbacks

A closure that already captures everything it needs can omit the registration
argument:

```perl
my $registration = $loop->watch(
    fh      => $fh,
    read    => sub { drain_socket($fh) },
    no_args => 1,
    lean    => 1,
);
```

`lean` is available only on this no-argument path. It reduces retained Perl
state and is intended for expert, measured hot paths.

## Edge-triggered and oneshot modes

`watch()` accepts:

```perl
edge_triggered => 1
oneshot        => 1
```

Use them only when the application implements their Linux semantics. An
edge-triggered reader must drain until EAGAIN. An oneshot registration must be
rearmed before more readiness can be delivered.

## Introspection

The Loop can query managed objects, native resources, liveness reasons, and
conservative capacity pressure without maintaining duplicate hot-path
bookkeeping:

```perl
my $objects   = $loop->objects;
my $snapshot  = $loop->inspect($objects->[0]);
my $census    = $loop->census;
my $resources = $loop->resources;
my $reasons   = $loop->why_alive;
my $pressure  = $loop->pressure;
```

`running` is an O(1) native driver-state query. Other object/resource views are
assembled from authoritative registries when requested. See
[Loop Introspection](INTROSPECTION.md) for exact shapes and complexity.

## Statistics and profiling

```perl
my $stats = $loop->stats;
$loop->reset_stats;
```

Cheap counters cover epoll waits, readiness classes, callback calls,
`epoll_ctl`, batching, watcher lifecycle, timers, and drive methods.

Optional nanosecond profiling is explicit:

```perl
$loop->profile(1);
# measured workload
my $stats = $loop->stats;
$loop->profile(0);
```

Profiling changes the measured workload and should remain disabled for normal
throughput comparisons.

## Measured reactor defaults

The current measured defaults are:

- event capacity: 8192
- callback scope limit: 128
- aggressive watcher reclaim: disabled

Setters remain available for controlled experiments. They are not general
application tuning requirements.

## What the raw reactor intentionally does not own

The low-level reactor does not provide application-level:

- input buffering;
- output queues;
- partial-write management;
- framing or codecs;
- backpressure policy;
- socket connection semantics;
- packet semantics;
- process lifecycle semantics;
- Future, Promise, or coroutine scheduling.

Those responsibilities belong to the appropriate semantic layer. Ordered bytes
belong to the private engine behind `IO::Pipe`, `IO::TTY`, and
`IO::Sock::Stream`; packet boundaries belong to `IO::Sock::Dgram`; listening
ownership belongs to `IO::Sock::Listener`; kernel scheduling/notification state
belongs to the concrete `Kernel::*` leaves.

Third-party async/await or Future layers may compose Linux::Event without
changing that division. A new core primitive should be added only when an
external implementation demonstrates that the existing reactor cannot express
the required behavior safely or efficiently.
