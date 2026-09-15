# Ordered-byte transport boundary

The private ordered-byte engine owns application byte semantics: buffering,
framing, output ordering, backpressure, queue limits, read pause, EOF,
directional lifecycle, established deadlines, errors, and protocol
transitions.

`Linux::Event::Loop` owns descriptor readiness. A transport provider owns the
mechanics that move bytes between the ordered-byte engine and the underlying
resource.

For ordinary `IO::Pipe`, `IO::TTY`, and plain `IO::Sock::Stream` objects the
transport is the native plain path. `Linux::Event::TLS` supplies the current
non-plain transport for stream sockets.

## Why transport is private

Transport is an implementation capability, not a public resource identity.
Applications select the completed Linux resource leaf:

```text
IO::Pipe
IO::TTY
IO::Sock::Stream
```

rather than choose an internal transport class. A leaf may be used directly
with constructor callbacks where no reusable class policy is needed, or
subclassed for framing, tuning, socket policy, and named protocol callbacks.
Transport selection is an acquisition decision layered onto the Stream object;
it is not a second Stream hierarchy.

This keeps several concerns separate:

```text
Loop readiness
    -> byte transport
    -> ordered-byte buffering/framing
    -> application protocol callback
```

For TLS stream sockets:

```text
socket readiness
    -> OpenSSL transport
    -> plaintext ordered-byte framing
    -> application protocol callback
```

## Plain transport

The plain path performs direct descriptor operations:

- `read` from the readable descriptor;
- immediate `write` to the writable descriptor;
- `writev` draining of queued output;
- resource-specific writable completion where supported.

For `IO::Sock::Stream`, graceful writable completion maps to kernel
`shutdown(SHUT_WR)` where appropriate. Shared non-socket descriptors do not
receive invented socket half-close semantics.

The plain path is specialized in XS. After the minimal provider identity check,
it issues the direct syscall path without Perl method dispatch or a generic
callback on each operation.

`transport_name()` reports `plain` for an active ordinary transport.
`transport()` exposes the configured private non-plain provider where one
exists, and `is_transport_ready()` reports asynchronous provider readiness.

## Native operation contract

A native transport operation reports byte progress plus one status:

| Status | Meaning |
|---|---|
| `OK` | Bytes moved successfully |
| `EOF` | Clean transport EOF |
| `WANT_READ` | Retry after readable readiness |
| `WANT_WRITE` | Retry after writable readiness |
| `INTERRUPT` | Mechanical interruption; retry immediately |
| `ERROR` | Terminal transport failure |

`WANT_READ` and `WANT_WRITE` are distinct because TLS operations can require
readiness opposite to the application operation: `SSL_read` can need writable
readiness and `SSL_write` can need readable readiness.

The provider also participates in graceful writable shutdown so the public
`end()` operation can remain ordered-byte lifecycle rather than OpenSSL policy.

## TLS acquisition policy

`Linux::Event::TLS` is an OpenSSL transport for
`Linux::Event::IO::Sock::Stream`. It is not a framer and not a second socket
hierarchy.

For accepted connections, TLS is selected by the Listener's generated-Stream
recipe:

```perl
my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '0.0.0.0',
    port => 9443,
    stream => {
        class => 'GatewayConnection',
        tls => {
            cert_file => $cert_file,
            key_file  => $key_file,
            alpn      => ['http/1.1'],
        },
    },
);
```

The same `GatewayConnection` class can be used by another Listener without a
`tls` recipe and will then be plain. Class identity therefore does not decide
whether an accepted connection is encrypted.

A Stream subclass may define `tls_defaults()` for reusable server policy such
as ALPN and handshake/shutdown timeouts. Those defaults are consulted only when
a Listener explicitly selects TLS; they do not activate TLS by themselves.

Outbound connections retain explicit client acquisition policy. Existing
class-level `use Linux::Event::TLS ...` declarations remain supported for
outbound client verification and adopted-handle compatibility, while the
ordinary server path uses the Listener recipe.

## Prepared server context

Listener construction resolves server TLS before acceptance begins:

1. merge optional class TLS defaults with Listener deployment overrides;
2. validate certificate/key and TLS policy;
3. load identity material;
4. create one reusable server `SSL_CTX` template.

Each accepted TLS connection clones only independent per-connection SSL state
from that prepared context and binds the accepted descriptor. The shared
`SSL_CTX` uses OpenSSL reference counting, so established Streams remain valid
after the Listener closes.

This keeps certificate parsing and configuration merging out of ordinary
accept/read/write paths. Plain listeners allocate no TLS connection state.

`bench/run-tls-accept-setup-bench.pl` isolates fresh per-connection server
context construction versus cloning from the prepared Listener-style context.
`bench/run-tls-microbench.pl` remains the separate established encrypted-I/O
benchmark.

## TLS behavior

The provider supplies:

- nonblocking client and server handshakes;
- client certificate-chain and hostname verification by default;
- SNI and configurable ALPN;
- `WANT_READ` / `WANT_WRITE` readiness switching;
- plaintext delivery through the existing raw/framed ordered-byte engine;
- ordered plaintext output through the existing segmented queue;
- the same high/low watermark and hard output-limit policy;
- clean TLS close notification for graceful writable shutdown;
- typed handshake, verification, read, write, and shutdown failures;
- SIGPIPE-safe socket writes using Linux `MSG_NOSIGNAL`;
- explicit rejection of bare-descriptor detach while encrypted provider state
  remains active.

Framers always see plaintext. TLS encryption and framing are intentionally
different layers.

## Readiness

A plain stream socket becomes application-ready after connection establishment.
A TLS stream socket becomes application-ready only after the handshake and
required verification have succeeded.

A Listener's `on_accept` callback runs after the accepted Stream object is
constructed and attached. For TLS, that occurs before application `on_ready`;
the latter remains the notification that encrypted transport is usable by the
application protocol.

## Read pause and TLS control traffic

Application `pause_read()` suppresses plaintext application delivery. It must
not prevent TLS control traffic required to finish a handshake, write, or clean
shutdown.

A provider can therefore request read/write readiness needed for its own
protocol progress while the ordered-byte engine continues withholding paused
plaintext callbacks. Any retained plaintext remains subject to the same input
limits.

## EOF and shutdown

A clean TLS peer `close_notify` enters ordinary readable EOF lifecycle.
Underlying stream-socket EOF without the required TLS close semantics is a
typed TLS read failure rather than silently pretending the encrypted protocol
closed cleanly.

`end()` drains accepted plaintext output and then performs provider-specific
graceful writable shutdown. `close()` remains immediate.

## Deadline ownership

Deadline ownership follows lifecycle boundaries:

```text
stream-socket resolve/connect
    -> TLS handshake
    -> established ordered-byte idle/read/write/operation deadlines
    -> TLS graceful shutdown
```

Connection acquisition owns the first deadline. TLS owns handshake and shutdown
timeouts. Established ordered-byte policy begins only after the provider
reports application readiness.

Successful TLS plaintext progress updates the same optional activity timestamps
as the plain transport. Handshake control traffic does not start or reset
established inactivity policy.

See `ORDERED-BYTE-DEADLINES.md` for established deadline behavior.

## Protocol transitions

`transition_to()` changes application protocol callbacks/framing while retaining
the existing byte transport. It does not recreate the socket, remove TLS, or
change resource identity.

Transport replacement is not part of the current public API. This document
describes the implemented transport boundary only; a future upgrade mechanism
must define ciphertext/plaintext ownership explicitly before being exposed.

## Dependency isolation

Linux::Event builds the TLS extension against OpenSSL 1.1.1 or newer. The
mechanical dependency is isolated in the TLS native extension. The reactor and
plain ordered-byte native extension do not link OpenSSL.

An ordinary plain Pipe, TTY, or stream socket allocates no TLS state, calls no
OpenSSL code, and retains the direct-syscall path.

The native transport contract is versioned with the distribution. The
ordered-byte state retains the provider object so its operations table and
native context outlive every in-flight operation.

Native headers retain `stream` terminology for the ordered-byte engine, while
XS package names use the private `_ByteStream` taxonomy. Neither defines a
second public Stream API.
