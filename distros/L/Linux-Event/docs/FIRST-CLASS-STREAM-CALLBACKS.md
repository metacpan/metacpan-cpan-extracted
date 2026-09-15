# First-class ordered-byte callbacks

Linux::Event ordered-byte objects support both subclass methods and
constructor-supplied coderefs. Constructor callbacks are ordinary Perl
closures, so they retain lexical application state without target objects,
method injection, caller-pad access, or package globals.

```perl
use v5.36;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

socketpair(my $stream_fh, my $peer_fh,
    AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";

my $loop = Linux::Event::Loop->new;
my $prefix = 'received';
my $stream = Linux::Event::IO::Sock::Stream->new(
    loop    => $loop,
    fh      => $stream_fh,
    on_data => sub ($stream, $bytes) {
        say "$prefix: $bytes";
        $stream->close;
        $loop->stop;
    },
);

syswrite($peer_fh, 'hello') == 5 or die "syswrite: $!";
$loop->run;
close $peer_fh;
```

## Surface and precedence

The callback options and signatures are:

| Callback | Signature | Availability |
|---|---|---|
| `on_data` | `($stream, $bytes)` | Raw Pipe, TTY, or connected Stream input |
| `on_message` | `($stream, $message)` | Framed Pipe, TTY, or connected Stream input |
| `on_messages` | `($stream, $messages)` | Framed input with `message_batch_size` |
| `on_drain` | `($stream)` | Output falls to the low watermark after backpressure |
| `on_eof` | `($stream)` | Read direction reaches EOF |
| `on_error` | `($stream, $error)` | Ordered-byte I/O, framing, timeout, or transport error |
| `on_close` | `($stream)` | Complete object reaches terminal close |
| `on_ready` | `($stream)` | Connected Stream becomes application-ready |
| `on_transport_ready` | `($stream)` | Connected Stream transport becomes usable, immediately before `on_ready` |

`IO::Sock::Stream->new` and `IO::Sock::Stream->connect` accept every callback
above. `IO::Pipe->new` and `IO::TTY->new` accept the ordered-byte callbacks
through `on_close`; they do not have a connection or transport readiness
phase. A constructor callback overrides the corresponding class method for
that instance. If no constructor callback is supplied, existing subclass
behavior is unchanged.

The public `IO::Sock::Stream` leaf may be used directly for raw I/O when its
required `on_data` callback is supplied to the constructor. A subclass remains
the reusable policy mechanism for a framer, native consumer, `stream_tuning()`,
`socket_options()`, named callbacks, and optional TLS defaults. Accepted TLS is
selected independently by the Listener recipe and is not part of Stream class
identity.

Framer selection and socket defaults remain class-level policy. Listener recipe
tuning can override class `stream_tuning()` for generated connections and a
live Stream can subsequently change mutable ordered-byte policy with `tune()`.

Raw, framed, batched, and native-consumer modes remain explicit. `on_data`
cannot be used on a framed class and message callbacks cannot be used on a raw
class. A framed class may provide both `on_message` and `on_messages` so a live
`tune(message_batch_size => ...)` can switch delivery policy without changing
protocol class; the callback required by the initial effective policy must
exist. Perl message callbacks cannot replace a native consumer. Invalid
combinations fail during construction rather than during dispatch.

## Dispatch model

Class methods are resolved once into the class descriptor. Constructor input
callbacks are validated once and retained directly in native per-object state.
The result is one effective CV for each active input boundary:

```text
class method CV or constructor closure CV
                  |
                  v
       native per-object callback slot
                  |
                  v
          direct Perl invocation
```

There is no per-message method lookup, object-hash callback lookup, closure
creation, or method-versus-coderef branch. Native reads, buffering, framing,
and batching remain native until application code must run. Lifecycle
callbacks are also resolved once, but remain in Perl because lifecycle and
exception orchestration are cold-path policy.

Instance input callbacks and lifecycle overrides survive compatible
`transition_to()` operations. Class-derived callbacks follow the target class
descriptor. `close()` and failed construction release retained callbacks;
`detach()` releases them without invoking `on_close`.

## Listener reuse

An `IO::Sock::Listener` accepts the complete connected-Stream callback set in
its generated-Stream recipe:

```perl
my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 9999,
    stream => {
        on_data => sub ($stream, $bytes) {
            $stream->write($bytes);
        },
    },
);
```

The Listener resolves the recipe once, retains one CV, and supplies that same
CV to every accepted Stream. Per-connection identity and initial mutable state
belong in `stream => { data => ... }`. Creating a fresh closure per connection
is unnecessary unless the application truly needs distinct lexical state, and
carries measurable construction cost.

Top-level `on_accept` and `on_error` belong to the Listener itself. Stream
callbacks such as `on_data` and Stream `on_error` belong inside `stream => {}`.

## Performance evidence

The cached-closure experiment measured raw and framed native dispatch with
4,194,304 callbacks per small-message row. Capturing one or four lexicals did
not produce a scaling penalty; closure rows remained approximately within
1-1.5% of the cached subclass method path in the decisive framed runs, with
raw delivery showing the same practical equivalence.

Accepted-Stream construction showed that post-construction setter/wrapper work
was the material cost, not retaining a shared closure. Direct native seeding
reduced the shared-closure CPU difference to about 1.35% in the official paired
result, with the distribution crossing zero. Fresh per-connection closure
allocation remained measurably more expensive.

Permanent regression harnesses are:

- `bench/run-first-class-framed-callback-bench.pl`;
- `bench/run-first-class-raw-callback-bench.pl`;
- `bench/run-first-class-callback-construction-bench.pl`.
