# Established ordered-byte deadlines

Established deadlines protect an ordered-byte resource after its byte transport
is usable. They apply to the private engine behind `IO::Pipe`, `IO::TTY`, and
`IO::Sock::Stream` where the configured direction/lifecycle makes sense.

They do not replace stream-socket resolver/connection deadlines or TLS
handshake/shutdown deadlines.

## Configuration

Subclass defaults belong in the cached ordered-byte descriptor through the
current `stream_tuning()` tuning hook:

```perl
sub stream_tuning ($class) {
    return (
        idle_timeout  => 60,
        read_timeout  => 30,
        write_timeout => 10,
    );
}
```

All values are non-negative seconds and may be fractional. Zero disables that
policy.

A constructor value overrides the class default for one object. For an outbound
stream socket:

```perl
my $connection = ClientConnection->connect(
    host          => $host,
    port          => $port,
    idle_timeout  => 120,
    read_timeout  => 20,
    write_timeout => 5,
);
```

The same established options can be used by appropriate Pipe/TTY construction
paths and by an adopted established stream socket. A listener-created
connection uses its recipe class defaults followed by any
`stream => { tuning => {...} }` overrides.

An explicit zero constructor value disables a nonzero subclass default.
Constructor overrides remain in force across `transition_to`; non-overridden
policy follows the target protocol subclass.

## Inactivity policies

- `idle_timeout` measures time since the latest successful transport read or
  write. Pausing input does not suspend whole-resource idle policy.
- `read_timeout` measures active inbound byte progress. `pause_read` suspends
  it; `resume_read` starts a fresh interval. EOF permanently disarms it.
- `write_timeout` exists only while output is queued. It begins when an empty
  queue first gains unsent bytes, resets on successful write progress, and
  disappears when the queue drains.

For TLS stream sockets, established activity means successful plaintext
progress through the private byte-transport boundary. TLS handshake traffic
occurs before established policy begins and remains governed by the TLS
handshake deadline.

## Overall operation deadline

One explicit fixed operation deadline can coexist with inactivity policy:

```perl
my $connection = ClientConnection->new(
    fh       => $socket,
    deadline => {
        after     => 30,
        operation => 'authentication',
    },
);
```

It can later be replaced or cleared:

```perl
$connection->set_deadline(
    after     => 5,
    operation => 'response',
);

$connection->set_deadline(
    at        => Linux::Event::Kernel::Timer->now + 10,
    operation => 'request',
);

$connection->clear_deadline;
```

`after` starts when the ordered-byte resource becomes application-usable if it
was supplied before readiness. `at` is an absolute monotonic deadline.
Ordinary reads/writes do not extend an explicit operation deadline.

`deadline()` reports the active absolute deadline, or undef for an unattached
relative deadline. `deadline_operation()` reports its application label.

## Expiration

Expiration produces `Linux::Event::Error` with:

- `type => 'timeout'`;
- `operation` equal to `idle`, `read`, `write`, or the explicit application
  label;
- `timeout` containing the relative policy duration when applicable;
- `deadline` containing the expired monotonic deadline.

The resource invokes its cached `on_error` callback when present and then
follows its normal terminal close path, including `on_close`.

When exact candidates tie, explicit operation deadline wins, followed by write,
read, and idle policy. This affects only which operation is reported; every
expiration is terminal.

## Scheduler design

Every deadline-enabled ordered-byte object owns at most one private timer
representing its earliest current candidate. These private timers use the
Loop's shared timerfd and indexed native timer heap. An ordered-byte object does
not create a dedicated deadline fd.

Successful native reads and writes update monotonic activity timestamps only
when at least one inactivity policy is enabled. With all inactivity values at
zero, ordinary ordered-byte I/O performs no activity clock reads.

Pause, resume, EOF, and output-drain paths skip deadline candidate rebuilding
unless the corresponding policy is enabled. I/O progress does not enter Perl
merely to reschedule the timer. If progress moves a deadline beyond an already
armed timer, the private timer callback reads the latest native snapshot and
rearms itself.

Closing, detaching, failure, and Loop teardown cancel deadline scheduler
ownership.

## Protocol transitions

A protocol `transition_to()` retains the same explicit operation deadline and
the same live resource. Constructor timeout overrides remain fixed. Any
inactivity policy not explicitly overridden changes to the target protocol
subclass default.

A transition does not move deadlines between resource categories. It changes
application protocol policy on the same Pipe, TTY, or stream socket.

## Stream-socket acquisition boundaries

Outbound `IO::Sock::Stream->connect()` has a separate connection-acquisition
deadline covering resolver and socket-attempt work. TLS has separate handshake
and shutdown deadlines.

The lifecycle is therefore intentionally layered:

```text
resolve/connect deadline
        -> TLS handshake deadline (when declared)
        -> established ordered-byte deadlines
        -> TLS shutdown deadline (when graceful TLS shutdown begins)
```

Each layer owns and reports the operation it protects.
