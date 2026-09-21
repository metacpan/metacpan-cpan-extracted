# Native ordered-byte consumer ABI

The native consumer ABI is an extension boundary for distributions that need
either complete framed messages or direct native raw input without surfacing
each payload through a Perl callback first. It belongs to the private
ordered-byte engine shared by `IO::Pipe`, `IO::TTY`, and
`IO::Sock::Stream`.

It is deliberately narrower than a transport, framer, Future, queue, or
scheduler. The core ABI contains no coroutine semantics, Future class,
continuation protocol, or cancellation policy.

The primary intended consumer is a separate higher-level async/await
distribution.

## Data path

Ordinary framed delivery is:

```text
epoll
  -> native byte transport read
  -> native framer
  -> cached on_message callback
```

A framed class with a native consumer uses:

```text
epoll
  -> native byte transport read
  -> native framer
  -> provider message function
```

A raw-input native consumer instead uses:

```text
epoll
  -> native byte transport read
  -> shared native input buffer
  -> provider input function over borrowed (data, length)
```

The raw-input provider reports how many leading bytes it consumed. Linux::Event
keeps any unconsumed tail in native storage and presents it again on a later
provider call; no payload SV is required merely to cross the core/provider
boundary.

The provider owns one context per ordered-byte object. It can retain an
outstanding receive, queue a result, or wake another abstraction; Linux::Event
core does not need to know the higher-level policy.

## Declaring a provider

An extension loads its native code, obtains the address of a static
`les_consumer_ops_v1_t`, and declares it on a framed concrete class through the
public extension-author support API:

```perl
Linux::Event::Framer->declare_native_consumer(
    'My::FramedConnection',
    {
        provider           => $provider_lifetime_token,
        abi_version        => 1,
        operations_address => $native_table_address,
    },
);
```

The target must inherit a Linux::Event ordered-byte leaf. A framed consumer
declares one built-in native framer and is mutually exclusive with
`on_message`, `on_messages`, and `message_batch_size`.

A provider that sets `LES_CONSUMER_F_RAW_INPUT` instead attaches to an
unframed ordered-byte class and must provide the appended `input` operation.
Raw-input consumers are mutually exclusive with `on_data`,
`read_batch_bytes`, and built-in native framing.

The declaration follows normal Perl MRO inheritance and becomes immutable when
the concrete class descriptor is built. The `provider` value is retained for
the descriptor lifetime so the extension and provider-owned static/native state
remain alive.

`declare_native_consumer()` is for extension authors. It does not expose an
application async API in Linux::Event core.

## Canonical C contract

The canonical ABI-v1 declarations live in
`xsbytestream/stream_consumer_abi.h`. The C filename describes the ordered-byte
engine contract and does not define the public Perl resource taxonomy.

External XS distributions should vendor the canonical versioned header and
retain the ABI version/size checks rather than including unrelated private
ordered-byte implementation headers.

The provider operations table contains:

| Function | Contract |
|---|---|
| `create` | Create one provider context for one host ordered-byte object. Return `NULL` on failure. |
| `message` | Consume one borrowed framed-message `SV *` and return a consumer status. |
| `input` | Optional appended ABI-v1 raw-input hook receiving a borrowed contiguous native byte window plus a consumed-byte output. |
| `event` | Observe the first terminal input/lifecycle event. |
| `destroy` | Release the provider context exactly once. |
| `flush` | Optional end-of-drain notification for bounded provider batching. |

The host table passed to `create` contains:

| Function | Contract |
|---|---|
| `resume` | Clear consumer pause, synchronously dispatch buffered frames when possible, and restore read interest. |
| `pause` | Stop application payload reads immediately, including while no message callback is active. |
| `stream` | Return the borrowed host Perl object `SV *`; the native ABI field retains its historical name. |
| `is_closed` | Report whether the host object is closed. |
| `retain` | Retain host state and provider context across a provider-owned reentrant frame. |
| `release` | Release a prior retain; this may destroy both contexts and must be the frame's final context access. |

Every table begins with `abi_version` and `struct_size`. Linux::Event rejects
version mismatches, structures smaller than required fields, unsupported flags,
missing provider names, and missing required functions before constructing the
host object.

The provider operations table must remain at a stable address for every cached
class descriptor that declares it.

## Optional v1 raw-input extension

`input` is an optional field appended to `les_consumer_ops_v1_t`. A provider
requests it with `LES_CONSUMER_F_RAW_INPUT`; the host then verifies
`struct_size` reaches that field and that the function pointer is non-null.
Providers using the original ABI-v1 table layout remain valid when they do not
request raw input.

The call receives a borrowed contiguous `(data, length)` view into the
ordered-byte native input buffer. The provider writes the number of leading
bytes consumed to `*consumed` and returns an ordinary consumer status.
`consumed` may be zero to retain an incomplete protocol unit for a later read,
but it must never exceed `length`.

The borrowed pointer is valid only for the duration of the `input` call.
Provider code must copy bytes it needs after return. The host retains
unconsumed bytes natively, including across provider pause/resume, and can
re-drive already-buffered input synchronously when resumed.

An `input` call may invoke application code that closes the host reentrantly.
Terminal teardown then owns and clears the native input buffer; the host
validates the provider's returned status and consumed count but does not apply
that count to the cleared buffer. A nonterminal provider-changing
`transition_to()` is different: the source provider's consumed prefix is
applied first, and the unconsumed native tail is then re-driven through the
replacement provider.

This extension is intended for protocol engines whose own native parser cannot
be expressed as one of Linux::Event's built-in native framers. It generalizes
the existing consumer boundary without making the core own protocol parsing.

## Optional v1 flush extension

`flush` is an optional appended ABI-v1 field. A provider requests it with
`LES_CONSUMER_F_WANT_FLUSH`. The host then requires a sufficiently large table
and a non-null function.

A host predating that extension rejects the flag, while providers compiled
against the original v1 layout remain valid when they do not request it.

The hook runs after a framed native-input drain that invoked `message` at least
once and returns the same consumer status values as `message`. This allows a
provider to retain a bounded batch and defer one higher-level wakeup until the
current native read/buffered-input drain completes.

## Host lifetime retain extension

`retain` and `release` are appended host-table ABI-v1 lifetime functions. A
provider that calls callback-capable host operations from its own XSUB or other
provider-owned frame must:

1. verify `struct_size` reaches the required retain/release fields;
2. call `retain` before entering reentrant host work;
3. guarantee matching `release` on normal return and exception unwinding;
4. perform no host/provider context access after `release`.

`release` can immediately cause provider `destroy` and host-context destruction.
The retain therefore covers the complete provider-owned frame, not merely one
call to `resume()` or `pause()`.

Retaining only the host Perl scalar is not a replacement for retaining the
native host context.

## Message ownership

The `message` argument is borrowed and valid for the duration of the provider
call. A provider that retains it increments its Perl reference count and later
releases that reference.

The raw `input` byte window is likewise borrowed, but it is native memory
rather than a Perl scalar. Its pointer becomes invalid when `input` returns;
only the provider-reported consumed count crosses that boundary.

Retaining the same scalar transfers no payload bytes and is the intended
zero-copy-ish result path for a native receive integration.

The provider owns its context and any retained values. The host invokes
`destroy` only after native delivery has stopped and every provider-held host
lifetime retain has been released.

## Consumer statuses

`message`, raw `input`, and requested `flush` operations return one of:

| Status | Effect |
|---|---|
| `LES_CONSUMER_CONTINUE` | Continue parsing complete frames when lifecycle permits. |
| `LES_CONSUMER_PAUSE` | Disable application payload read interest. |
| `LES_CONSUMER_CLOSE` | Close the host through normal lifecycle. |
| `LES_CONSUMER_ERROR` | Raise a fatal provider error. |

Every returned status is validated even if provider code made the host
terminal during the call. `ERROR` and out-of-range statuses remain fatal
provider failures.

After validation, a valid `CONTINUE`, `PAUSE`, or `CLOSE` result is not applied
as though it could revive a host that became terminal reentrantly.

## Pause, resume, and pull consumers

`LES_CONSUMER_F_START_PAUSED` prevents application payload reads until the
provider invokes host `resume`. This supports pull-style consumers without
forcing Linux::Event to maintain a second general message queue.

Host `pause` lets a provider withdraw an armed receive before a message arrives.
It does not close the resource or discard native/kernel-resident input.

`resume` can synchronously invoke `message` before returning when complete
frames are already buffered. Provider code must therefore establish its pending
operation state before calling `resume`.

If the provider will inspect context, call another host function, or continue
stateful work after a callback-capable host operation, it must hold the host
lifetime retain across that entire reentrant frame.

The same lifetime rule applies to `pause` when its state transition can produce
provider/application notifications.

## Delivery reentrancy

A provider can wake higher-level user code from `message`; that code may arm
the next receive immediately.

The provider should return `CONTINUE` when another receive is ready to consume
more buffered frames and `PAUSE` when no receive is armed. The host rechecks
pause, close, EOF, and descriptor state between semantic messages.

A `message` result of `CONTINUE` does not erase an independently requested
provider pause. A deferred `flush` result of `CONTINUE` can clear the
end-of-drain consumer pause and re-drive buffered input according to the
existing ABI-v1 contract.

Transport progress remains independent of consumer pause. TLS can continue
handshake/shutdown control traffic while plaintext application delivery is
paused.

## Terminal flush ordering

Entering `message` marks the current native drain as flush-owed immediately
when flush support is enabled.

If provider or user code begins terminal teardown reentrantly, the required
terminal flush runs before `message` returns and before the terminal consumer
event. The host first marks the relevant direction terminal so `resume` or
`pause` cannot restart application input.

At that terminal boundary valid `CONTINUE`, `PAUSE`, and `CLOSE` statuses do
not reopen or otherwise alter lifecycle. Invalid statuses and explicit
`ERROR` remain provider failures.

If `message` throws before terminal teardown consumes a pending flush,
exception unwinding clears the incomplete flush marker.

## Provider failure rules

`create` reports failure by returning `NULL`. `destroy` must not throw.

A `message`, `flush`, or `event` implementation that invokes Perl can propagate
an exception like an ordinary Linux::Event semantic callback. It must update
its ownership/pending-operation state before that invocation so exception
unwinding leaves the provider context valid.

An invalid status or explicit consumer error is treated as a provider bug, not
an ordinary protocol error to be ignored.

## Terminal events

The provider receives at most one terminal event for the host input/lifecycle
boundary:

| Event | Meaning |
|---|---|
| `LES_CONSUMER_EVENT_EOF` | Clean input EOF. |
| `LES_CONSUMER_EVENT_READ_ERROR` | Native transport read failure. |
| `LES_CONSUMER_EVENT_FRAMING_ERROR` | Active native framer rejected input. |
| `LES_CONSUMER_EVENT_CLOSED` | Explicit or error-driven complete close. |
| `LES_CONSUMER_EVENT_DETACHED` | Plain transport ownership was detached. |
| `LES_CONSUMER_EVENT_READ_CLOSED` | Application explicitly closed only the read direction. |

The consumer event runs before the corresponding ordinary EOF/error/close
application callback. Existing structured errors and semantic callbacks remain
active, so a higher-level integration can use them for richer error values
while using the native terminal event to settle pending provider state.

Host `resume` is rejected after terminal input state, including from a
reentrant terminal callback.

Additional terminal event codes can be appended while retaining the ABI-v1
table layout. A provider must treat an unknown event code conservatively as
terminal rather than reject it or attempt to resume input.

## Descriptor transitions

`transition_to()` can change framing while retaining one provider context when
source and target cached descriptors use the same operations-table pointer.

It can also replace one native consumer provider with another, or remove the
native consumer when the target is an ordinary Perl Stream input sink. For a
provider replacement, the target provider context is created before the live
source context is disturbed. If target creation fails, the source descriptor,
source provider context, and unread native input remain active. Consumer
removal has no target provider context to create.

A provider-changing or provider-removing transition preserves unread bytes in
the shared native input buffer. Source flush debt is settled before the source
context is destroyed. If the transition is requested reentrantly from a
provider callback, or while the source provider holds a host lifetime retain,
destruction is deferred until that provider frame/retain is safely released.
For replacement, the target context is then installed. For removal, consumer
mode becomes inactive. In either case retained input is immediately re-driven
under the target descriptor when application input is not paused.

During transition-time target `create`, host `pause`, `resume`, `retain`,
and `release` are intentionally unavailable until the target context is
activated. Once a
provider-changing handoff is pending, those same mutating operations are also
unavailable to the retiring source context; an already-held source retain may
only be released so the handoff can reach its safe point. Stream identity and
closed-state queries remain available. This prevents either side from driving
buffered input while target descriptor state and source provider state overlap.

Removing a native consumer provider into an ordinary target is supported.
Adding a native consumer to an already-ordinary live object remains rejected;
that reverse direction has no current core contract. The transition also must
remain within the same public resource category.

## Fairness

`read_budget_bytes` is a general ordered-byte class option. The shared
default is 65,536 bytes, which bounds one readiness callback so continuously
replenished input yields back to the Loop. Explicit zero preserves the
drain-until-EAGAIN opt-in. Level-triggered readiness continues on a later Loop
turn when a positive budget is reached.

This can be useful when a reentrant pull consumer continuously returns
`CONTINUE`, but the option is not specific to async/await and also applies to
ordinary raw/framed callback workloads.

## Stability boundary

ABI version 1 exposes only the two public native tables and constants in the
canonical consumer header. Provider code must not inspect the private native
ordered-byte state, descriptor implementation, watcher storage, input buffer,
or transport context.

New optional table fields require a larger `struct_size`. An incompatible
contract requires a new ABI version.

Historical C identifiers and the canonical header filename still use `Stream`
because they are stable native ABI names. The public Perl resource taxonomy can
change independently without gratuitously renaming those native symbols.
