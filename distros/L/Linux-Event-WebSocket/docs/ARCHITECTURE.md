# Linux::Event::WebSocket Architecture

This document describes the architecture of the 0.001 release.

## Layer ownership

`Linux::Event` owns sockets, epoll, TLS, ordered byte delivery, write
buffering, backpressure, lifecycle, timers, and in-place `transition_to()`
operations.

`Linux::Event::HTTP` owns the opening HTTP/1.1 request/response exchange and
preserves bytes read after the Upgrade headers during the protocol transition.

`Linux::Event::WebSocket` owns the public connection API, Upgrade policy,
RFC 6455 data semantics, text policy, control behavior, and graceful close
lifecycle.

The production frame/message engine is a vendored, locally patched
`bq_websocket` core reached through XS. It does not own transport or the event
loop.

## Connection model

An established WebSocket connection is the same live Linux::Event Stream that
performed the HTTP Upgrade. It is transitioned in place rather than wrapped or
replaced. Socket identity, TLS state, queued output, application data, and
already-read bytes remain attached.

The class chains use ordinary single inheritance:

```text
Linux::Event::WebSocket::Client::Connection
    -> Linux::Event::WebSocket::Connection
    -> Linux::Event::IO::Sock::Stream

Linux::Event::WebSocket::Server::Connection
    -> Linux::Event::WebSocket::Connection
    -> Linux::Event::IO::Sock::Stream
```

There are no roles, mixins, multiple-inheritance trees, or injected methods in
the connection design.

## HTTP Upgrade handoff

The high-level server composes `Linux::Event::HTTP::Server`. Accepted streams
start as HTTP connections and transition to the configured WebSocket connection
class after a valid handshake.

The high-level client uses `Linux::Event::HTTP::Client::Connection` for the
opening exchange. WebSocket state is attached before the request is sent,
because post-101 bytes may be delivered to the transitioned class before the
public HTTP `on_upgrade` callback runs.

Linux::Event::HTTP 0.002 owns server-side HTTP byte input natively, so the
private WebSocket server handshake connection does not declare or override an
HTTP input consumer. HTTP parses the opening request from the native ordered-byte
buffer and Linux::Event `transition_to()` replaces the HTTP consumer with the
WebSocket bq raw-input consumer after the validated 101 handoff.

The HTTP client response path remains Perl-based in 0.002. The private WebSocket
client handshake connection therefore keeps a small temporary native bridge that
materializes the borrowed native window and feeds the existing HTTP client
parser. After a valid 101 response, `transition_to()` replaces that bridge
with the WebSocket bq raw-input consumer while preserving unread bytes.

In both directions the live object is reblessed before preserved post-HTTP
bytes are re-driven, so the first WebSocket frame may share the same transport
read as the HTTP Upgrade without established WebSocket traffic using Perl
`on_data`.

The native WebSocket engine is created with bq's handshake disabled. HTTP
parsing and Upgrade validation therefore remain outside bq. Production test
`t/12-upgrade-tail.t` covers the same-read boundary in both directions and
requires `open` to precede delivery of a same-read first message.

## Production data path

Established inbound data follows:

```text
Linux::Event native ordered-byte buffer
    -> WebSocket raw consumer in WebSocket.xs
    -> vendored bq_websocket parser/message assembly
    -> XS RFC 3629 validation for completed text
    -> _Engine direct event delivery
    -> application callback
```

No Perl read scalar is created before WebSocket parsing. A payload SV is created
only for a completed application message that must cross into Perl.

Outbound text follows:

```text
application send_text
    -> Connection
    -> _Engine
    -> _BQ XS adapter
    -> Perl C UTF-8 validation/byte representation
    -> bq_websocket framing/masking
    -> Stream::write
```

Binary data bypasses UTF-8 validation. Client masking keys come from Linux
`getrandom(2)`.

### Raw native-input path

Linux::Event 0.116's raw native-consumer ABI exposes a borrowed ordered-byte
input window before core creates a Perl read scalar. Linux::Event::WebSocket
uses that facility as its established receive path without moving any
WebSocket framing policy into Linux::Event core.

The provider and `_Engine` share one `_BQ` object, so inbound parsing,
outbound sends, Ping/Pong, Close, and error state remain one protocol state
machine. Provider creation does not re-enter Perl. On first WebSocket input the
provider obtains connection configuration, creates bq, obtains the actual
`_Engine` object once, and retains that Engine for direct event delivery.

The provider preserves the Engine's `in_feed` guard while bq drains input so
application sends from message callbacks keep the same non-reentrant output
semantics as the previous path. Linux::Event host retain/release brackets the
callback-capable input work.

Linux::Event core remains protocol-neutral. Its responsibilities here are the
generic raw-input ABI, safe provider replacement during `transition_to()`,
preservation of unread native input, and correct reentrant terminal teardown.
The HTTP bridge, bq parser, RFC policy, and WebSocket lifecycle all remain in
this distribution.


The adapter compiles bq single-threaded because a connection is owned by one
Linux::Event loop. bq's automatic Ping and timeout policy is disabled;
Linux::Event::WebSocket keeps its existing close timer and explicit `ping()`
semantics.

## Private implementation pieces

```text
_BQ         XS loader for the native protocol adapter
_Engine     WebSocket policy, lifecycle, dispatch, and error mapping
_Handshake  WebSocket HTTP Upgrade validation/policy
_State      connection/application state preserved across transition
_Frame      close-code helpers plus test/developer frame utilities
_UTF8       close-reason string conversion helpers
_Parser     retained reference/test parser, not the production data path
```

`WebSocket.xs` embeds the vendored bq source directly. No system bq library is
required.

## Vendored bq policy

The vendored source is based on upstream commit
`6c188d3f0edca38d7a8926e0d30f4c145414ba4c` and is distributed under MIT.
It is intentionally patched. The maintained differences include secure Linux
mask generation, RFC close-code and close-reason validation, rejection of
oversized control frames before side effects, safe Close echo ownership, and
one Pong response for every Ping.

The complete patch policy and license location are documented in
`vendor/bq_websocket/README.md`.

Upstream refreshes are deliberate maintenance work, not blind source copies.
They must preserve the local policy and pass normal tests plus Autobahn client
and server conformance.

## UTF-8 policy

WebSocket text must satisfy RFC 3629. The production receive and send paths use
Perl's C UTF-8 API from XS with
`UTF8_DISALLOW_ILLEGAL_C9_INTERCHANGE`. This rejects malformed/overlong
sequences, surrogate code points, Perl-extended UTF-8, and values above
U+10FFFF while continuing to permit Unicode noncharacters.

Inbound valid non-ASCII text is delivered as a Perl UTF-8 scalar. ASCII text
stays on the invariant fast path.

Close reasons remain small control payloads and use the private `_UTF8`
helper at the Perl policy layer.

## Size limits and fragmentation

The high-level client and server default `max_message_size` to 16 MiB. bq is
configured so the application message-size limit, not bq's upstream queue or
fragment-count defaults, controls accepted logical message size.

Valid control frames retain the RFC 6455 125-byte maximum even if the
application data-message limit is smaller.

## Close behavior

Receiving a valid Close dispatches `on_close` and ends transport output. A
locally initiated Close waits for the peer response, with the existing
configurable timeout falling back to a hard abort.

Protocol violations produce the applicable close status when possible:

- 1002 for protocol errors;
- 1007 for invalid UTF-8 payloads;
- 1009 for configured size-limit violations.

`Linux::Event::WebSocket::Connection::close()` intentionally means the RFC
6455 close handshake. `abort()` is immediate transport termination.
Linux::Event 0.116 supplies the matching core invariant that involuntary Stream
teardown bypasses a protocol subclass's public `close()`.

## Test and conformance policy

Normal CI targets Perl 5.36 and Perl 5.44.

Repository-only Autobahn testing covers both server and client. Sections 12 and
13 remain excluded because permessage-deflate is not implemented. Native-engine
changes are not acceptable unless both directions remain free of conformance
failures. The report checker also requires all 301 selected cases so a
truncated run cannot pass.

The current bq integration reports 287 OK, 11 NON-STRICT, and 3 INFORMATIONAL
cases in each direction, with 298 OK and 3 INFORMATIONAL close results. The
NON-STRICT cases are accepted Autobahn behaviors, not conformance failures:

- seven cases close correctly with 1002 after a later malformed frame in a
  coalesced read, but bq does not first expose an already-complete preceding
  message to the application;
- four fragmented-invalid-UTF-8 cases close correctly with 1007 when the
  logical message is completed rather than at the earliest byte at which the
  invalid sequence can be proven.

Changing the first behavior would require interleaving application delivery and
output flushing inside bq's parse of one transport read, which would alter the
measured batching path. It is intentionally not done solely to convert an
Autobahn NON-STRICT classification to OK.

The production suite also keeps the older frame/parser tests as an independent
reference for wire vectors and protocol-policy regressions.

## Native-code decision

The first implementation intentionally stayed in Perl until measurement
identified a material end-to-end bottleneck. The bq experiments then showed
large improvements on small/medium messages, large messages, realistic Unicode,
100-client traffic, and broadcast fan-out while preserving conformance.

That evidence justifies native WebSocket code in this distribution. It does not
justify putting WebSocket-specific framing in Linux::Event core.

See `docs/BENCHMARKS.md` for representative measurements.

## Deferred work

- permessage-deflate negotiation and compression;
- optional future upstream bq refreshes;
- async/await-first APIs.
