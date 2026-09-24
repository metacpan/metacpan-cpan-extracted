# Object lifecycle and Loop attachment

Linux::Event has one owner of readiness: `Linux::Event::Loop`. Public resource
leaves implement their own lifecycle and expose a private `_attach_to_loop`
hook that `Loop->add()` uses. That hook is an implementation contract inside
the distribution, not an application subclass API.

## Two equivalent construction styles

Attachable public objects can receive `loop => $loop` during construction or
be attached later with `$loop->add($object)`.

Examples:

```perl
my $connection = ClientConnection->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => 9999,
);

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop   => $loop,
    host   => '0.0.0.0',
    port   => 9999,
    stream => {
        class => 'ServerConnection',
    },
);

my $timer = SessionTimer->new(
    loop  => $loop,
    after => 30,
    data  => $session,
);

my $signal = ShutdownSignal->new(
    loop    => $loop,
    signals => [SIGINT, SIGTERM],
    data    => $listener,
);

my $dgram = MetricsDgram->new(
    loop => $loop,
    host => '0.0.0.0',
    port => 9000,
);

my $event = ResultReady->new(
    loop => $loop,
    data => $result_queue,
);

my $inotify = Linux::Event::Kernel::Inotify->new(loop => $loop);
my $log_watch = $inotify->watch(
    'log.txt',
    on_modify => sub ($event) { ... },
);

my $process = WorkerProcess->spawn(
    loop    => $loop,
    command => ['/usr/bin/worker', '--once'],
);
```

Equivalent detached construction:

```perl
my $connection = $loop->add(ClientConnection->connect(
    host => '127.0.0.1',
    port => 9999,
));

my $listener = $loop->add(Linux::Event::IO::Sock::Listener->new(
    host   => '0.0.0.0',
    port   => 9999,
    stream => {
        class => 'ServerConnection',
    },
));

my $timer = $loop->add(SessionTimer->new(after => 30));
my $signal = $loop->add(ShutdownSignal->new(signals => [SIGINT, SIGTERM]));
my $dgram = $loop->add(MetricsDgram->new(host => '0.0.0.0', port => 9000));
my $event = $loop->add(ResultReady->new(data => $result_queue));

my $inotify = Linux::Event::Kernel::Inotify->new;
my $log_watch = $inotify->watch(
    'log.txt',
    on_modify => sub ($event) { ... },
);
$loop->add($inotify);

my $process = $loop->add(WorkerProcess->spawn(
    command => ['/usr/bin/worker', '--once'],
));
```

`add()` stores the Loop, starts the object's activity, and returns that same
object. It does not wrap or replace it.

## Ownership rules

- An attachable object belongs to at most one Loop.
- An object can be attached only once.
- A terminal object cannot be reattached.
- `IO::Pipe` owns each distinct configured handle until close or detach.
- `IO::TTY` borrows supplied terminal handles by default. It temporarily makes
  them nonblocking and close-on-exec, then restores their captured descriptor
  state when the complete TTY closes or detaches. `owns_handles => 1` opts
  into owning/closing semantics.
- `IO::Sock::Stream` owns its connected socket once acquired/adopted.
- An established deadline-enabled ordered-byte object owns at most one private
  timer entry in the Loop scheduler.
- `IO::Sock::Listener` owns sockets it creates; ownership of an adopted
  listening handle follows `owns_socket`.
- `IO::Sock::Dgram` owns created datagram sockets and owned Unix paths; adopted
  handles default to caller ownership.
- The Loop retains active `Kernel::Timer` and `Kernel::Signal` resources while
  they are registered.
- `Kernel::Event` owns one eventfd and its Loop registration; only its supported
  signaling operation crosses the documented thread/fork boundary.
- `Kernel::Inotify` owns one inotify fd and internal Loop registration; its
  child Watch objects are logical subscriptions rather than separate Loop
  resources.
- The Loop retains a running `Kernel::Process`; Process owns pidfd and configured
  pipe ends but does not implicitly signal the child merely because an
  application reference is dropped.

Violations are rejected synchronously so fd ownership remains unambiguous.

## Fork ownership transitions

`Loop->fork()` is an explicit ownership operation, not permission to keep
using copied epoll state after an ordinary process fork.

The first supported disposition matrix is intentionally narrow:

- Listener: `share` or `move`;
- Timer: `clone` or `move`;
- Inotify: `clone` or `move`;
- established plain socket Stream: `move`.

A resource omitted from all disposition lists remains parent-owned and its
child copy is made inert without application callbacks. `clone` means the
child reconstructs an independent kernel facility while the parent stays
unchanged. `share` means both processes intentionally register the inherited
kernel object in separate Loop reactors. `move` uses a child-ready/parent-
commit handshake; only after child reconstruction succeeds does the parent
close or cancel its side and poison the moved object.

The child receives a new epoll instance and new Loop-owned timer source rather
than reusing either inherited reactor descriptor. Timer clones are scheduled at
the same absolute monotonic deadline. Inotify clones rebuild their logical
watches on a fresh child inotify instance. Pending `defer` callbacks are never
inherited.

Managed fork is quiescent-only in the initial contract. It also assumes the
calling process has no unrelated live threads. Linux::Event tears down its own
idle resolver worker service before forking and rejects active resolver requests,
but it cannot make arbitrary third-party pthread state or application-created
threads safe for continued Perl execution in the child. Pending socket
connections and non-plain Stream transports also reject the operation. An
ordinary `CORE::fork` leaves the inherited Loop owned by the parent PID, so
child-side registration, driving, introspection, statistics, and tuning fail
predictably.

## Logical resources and native registrations

A public object is a logical activity, not necessarily one epoll entry.

A connecting `IO::Sock::Stream` can temporarily own connection-attempt,
resolver, and deadline resources before its established socket registration is
installed. The application holds the same connection object throughout.

An `IO::Sock::Listener` owns its listening registration and creates one
`IO::Sock::Stream` instance per accepted descriptor, using the configured base
class or subclass. The connection is attached before listener `on_accept`; plain
connection `on_ready` follows, while TLS `on_ready` waits for successful
handshake/verification.

`Kernel::Timer` is also a logical scheduled object rather than a one-to-one
timerfd wrapper. Timers on a Loop share one private timerfd and indexed native
heap.

`Kernel::Signal` subscriptions share one private signalfd service per Loop.
Several objects can subscribe to one signal and one object can subscribe to
several signals.

`Kernel::Event` is a logical eventfd notification object. Its counter indicates
that work may be available; application payloads remain in the application
queue or IPC mechanism.

`Kernel::Inotify` is one managed resource even when it owns many logical
filesystem Watch objects. Several logical Watches may share one native inotify
watch descriptor when they resolve to the same inode.

`IO::Sock::Dgram` owns one packet socket and whole-packet output queue.
`Kernel::Process` may own pidfd plus stdin/stdout/stderr registrations. Those
remain one application object because their lifecycle and callbacks are
inseparable.

## Ordered-byte ownership

`IO::Pipe`, `IO::TTY`, and `IO::Sock::Stream` share private ordered-byte
machinery but retain resource-specific public lifecycle semantics.

Read EOF and write completion are independent. Split Pipe/TTY descriptors can
be closed directionally. A shared non-socket descriptor has no universal kernel
half-close operation. Stream sockets can map graceful write completion to
socket `shutdown()`.

Plain detach ends Linux::Event management only when the concrete leaf allows it
and pending output has drained. Pipe and Stream detach transfer owned handles.
A default borrowed TTY instead restores the captured descriptor flags and
returns the caller-owned handles; an owning TTY transfers them. TLS connections
cannot detach a bare socket while encrypted provider state remains attached.

Constructor-supplied ordered-byte callbacks are retained for the object's
active lifetime. Compatible callbacks survive `transition_to()`; terminal
close and failed construction release them, while detach releases them without
invoking `on_close`.

See `ORDERED-BYTE-IO-DESIGN.md` for the shared native engine and
`ORDERED-BYTE-DEADLINES.md` for established deadline ownership.

## Listener acceptance

The Listener's `stream => {...}` recipe may name
`Linux::Event::IO::Sock::Stream` itself or a supported subclass with its
`class` member. The base class is valid for raw accepted Streams whose behavior
comes from recipe callbacks; subclasses provide reusable class-level framing,
tuning, socket, TLS, native-consumer, or method policy. Recipe `data` is
initially passed to each accepted connection. `on_accept` can replace
connection data, retain the object, or close it.

Accepted connections do not receive an intermediate public watcher or temporary
socket object. The accepted descriptor is transferred directly into the
configured connection class.

## Timer lifecycle

A one-shot `Kernel::Timer` releases its application data after callback
completion according to the timer contract. Recurring timers remain active
until cancelled or until Loop teardown.

Cancellation is terminal. Rescheduling is allowed while active, including from
inside `on_timer`, but a terminal timer cannot be revived.

Private ordered-byte deadline timers use the same scheduler but are not public
objects and retain only the route required to notify their owner.

## Signal lifecycle

Signal cancellation is terminal. Self-cancellation and cross-cancellation
during fan-out are safe because dispatch snapshots the relevant subscriber
state. Linux::Event restores only signal-mask entries that its service changed.

## Event lifecycle

`Kernel::Event` uses eventfd notification semantics. `signal()` writes the
counter without invoking the callback inline. `on_event` always runs on the
owning Loop thread/interpreter.

Thread clones or forked children do not gain ownership of the parent's Loop,
callback state, or application data. They can only use the narrow signaling
boundary documented in `EVENT-DESIGN.md`.

## Inotify lifecycle

A detached `Kernel::Inotify` records child Watch specifications without
starting kernel monitoring. Successful Loop attachment creates the inotify fd,
installs every pending watch transactionally, and then registers the source with
epoll. `loop => $loop` uses that same attachment path.

A Watch created after parent attachment becomes active synchronously.
`$watch->cancel` is idempotent and terminal; the Watch receives no callback
after cancellation, including the `IN_IGNORED` generated by its own
`inotify_rm_watch()`. Kernel invalidation of a still-active watch may deliver
`on_ignored` before that Watch becomes terminal.

`$inotify->close` is idempotent and terminal. It removes the internal Loop
registration, closes the inotify fd, and makes all child Watches terminal
without callbacks. Inotify objects are not detached and reattached after a
successful attachment.

See `INOTIFY-DESIGN.md` for shared-inode, overflow, callback-order, and
fairness semantics.

## Dgram lifecycle

`IO::Sock::Dgram::close()` releases an owned descriptor and owned Unix path
according to the selected configuration. `detach()` transfers the open handle
without invoking `on_close` and suppresses later path cleanup by the detached
object.

Packet output remains whole across queuing and retry; this is why datagrams do
not reuse ordered-byte queue semantics.

## Process lifecycle

`Kernel::Process` has no generic `cancel` operation. Applications close stdin,
send an explicit signal, or otherwise interact with the child while retaining
the Loop until `on_exit` reports terminal process state.

Process ownership covers the pidfd and any configured asynchronous stdio pipe
ends. These are implementation resources beneath one public Process object.

## Raw descriptor registrations

Low-level applications can register a descriptor directly:

```perl
my $registration = $loop->watch(
    fh   => $fh,
    read => sub ($registration) {
        my $count = sysread($registration->fh, my $bytes, 8192);
        $registration->cancel if defined($count) && $count == 0;
    },
);
```

`watch()` attaches immediately and returns an opaque native registration. It is
not a public subclass hierarchy. Cancellation, replacement, and Loop destruction
make the handle inert; fd or watcher storage reuse cannot redirect an obsolete
handle to another registration.

Use a concrete `IO::*` or `Kernel::*` resource when Linux::Event should own the
higher-level lifecycle instead of the application manually managing a raw fd.

## Destruction

Explicit terminal operations are preferred because they make callback timing
and ownership transfer clear. Destructors are a safety net.

Ordered-byte resources invoke `on_close` according to their complete-resource
terminal rules. Detach intentionally does not: the descriptor remains open and
ownership transfers to the caller.

Loop destruction tears down remaining managed resources and their private
registrations without exposing those registrations as public application
objects.

## Interpreter ownership

Loop and native resource-owning objects remain confined to their creating Perl
interpreter unless a resource documents a narrower signaling-only boundary.
`Kernel::Event` is the deliberate eventfd exception.

Class declarations are ordinary Perl package state and can be loaded in another
interpreter. Immutable native class descriptors are rebuilt there on first use
where required. An object created before a thread boundary remains owned by its
original interpreter.

Private implementation and native ABI packages do not alter these ownership
rules. They are `no_index` implementation details, not application subclassing
APIs.
