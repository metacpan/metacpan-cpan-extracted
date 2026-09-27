# Linux::Event::HTTP HTTP/2 architecture

This document describes the current HTTP/2 implementation and its deliberate
boundaries.

HTTP/2 is part of Linux::Event::HTTP. It is not a separate public distribution
or a parallel application API.

## Public API

Applications enable HTTP/2 on the high-level Server or Client:

```perl
http2 => 1
```

The same public classes remain in use:

- `Linux::Event::HTTP::Request`
- `Linux::Event::HTTP::Response`
- `Linux::Event::HTTP::Transaction`
- `Linux::Event::HTTP::Client::Operation`
- `Linux::Event::HTTP::Server`
- `Linux::Event::HTTP::Client`

HTTP/2 protocol machinery stays private.

## Protocol engine

HTTP/2 uses `Net::HTTP2::nghttp2` 0.011 or newer.

That binding provides libnghttp2 protocol machinery. Linux::Event::HTTP does not
maintain a competing HPACK/frame implementation.

nghttp2 owns:

- frame encoding/decoding;
- HPACK;
- stream state;
- SETTINGS;
- GOAWAY;
- HTTP/2 flow control.

Linux::Event owns the live socket/TLS transport.

Linux::Event::HTTP owns the mapping between those layers and the public HTTP
message/exchange model.

## TLS and ALPN

The production path is HTTPS negotiated with ALPN.

When HTTP/2 is enabled, the endpoint advertises:

```text
h2
http/1.1
```

If the peer selects `h2`, the live TLS stream transitions to the private H2
executor before HTTP/2 protocol bytes are emitted.

If the peer selects `http/1.1`, the ordinary HTTP/1 path remains in use.

Cleartext h2c is not provided.

## Transaction model

One HTTP/2 stream maps to one Transaction.

That means a single H2 connection may have many active Transactions at once.

The server callback API remains:

```perl
on_request => sub ($conn, $req, $res) {
    ...
}
```

During an HTTP/2 callback, `$conn->transaction` refers to the Transaction for
that callback's stream.

Code that needs the Transaction after callback return must retain it.

There is no one connection-global active Transaction for HTTP/2.

## Request mapping

Pseudo-headers map into protocol-neutral Request state:

```text
:method     -> method
:path       -> target
:scheme     -> scheme
:authority  -> authority
```

The Request version is `2`.

Pseudo-headers do not appear in the ordinary lossless header list.

Connection-specific HTTP/1 fields are rejected or handled at the H2 protocol
boundary rather than weakening the generic Request API.

## Response mapping

`:status` maps to Response status.

Received H2 responses use version `2`.

HTTP/2 does not carry a reason phrase.

## Multiplexed client pool

Selected H2 connections stay available to the high-level Client while streams
are active.

Later same-origin Operations can therefore open new streams without waiting for
earlier Transactions to complete.

Current local active-stream admission cap:

```text
100 per H2 connection
```

nghttp2 separately enforces peer `SETTINGS_MAX_CONCURRENT_STREAMS`.

When no existing H2 connection has local capacity, the Client may establish
another connection.

Cross-origin H2 connection coalescing is not implemented.

## Pre-ALPN operations

The Client creates Operation, Transaction, and Request identity before ALPN
completes.

Same-origin Operations may wait on a bounded negotiating selector.

If H2 wins, queued Transactions are submitted to the multiplexed connection.

If HTTP/1.1 wins, fallback Operations are distributed onto HTTP/1 connections
so HTTP/1 concurrency is preserved.

## Streaming request bodies before ALPN

A streaming Request producer is available immediately.

Bytes written before ALPN selection are held in a per-Transaction ordered queue.

Current cooperative high-water mark:

```text
65,536 bytes
```

After protocol selection, the selected executor adopts the same Transaction and
Body::Stream object and transfers queued bytes exactly once.

Content-Length is enforced before selection when present.

HTTP/1.1 fallback uses chunked framing for unknown lengths.

HTTP/2 does not synthesize Transfer-Encoding.

## Outgoing H2 bodies

Body::Stream remains the public producer.

The private H2 executor maps production into DATA while respecting:

- Linux::Event transport output capacity;
- HTTP/2 connection flow-control credit;
- HTTP/2 stream flow-control credit.

The producer does not expose HTTP/2 window details.

## Incoming H2 bodies

Body callbacks are synchronous consumers.

Successful callback delivery counts as application consumption for receive
window management.

The implementation must continue reading connection-level frames even when one
stream cannot progress; one slow stream must not pause the entire H2 socket.

Client `buffer_body` remains explicitly bounded.

## Header-list limits

Server and Client expose:

```perl
http2_max_header_list_size => 65_536
```

The limit is:

- advertised through `SETTINGS_MAX_HEADER_LIST_SIZE`;
- independently enforced after HPACK decoding.

Accounting follows:

```text
length(name) + length(value) + 32
```

per decoded field.

An oversized block fails the offending stream rather than unrelated streams.

## Buffered-response budget

The Client also exposes:

```perl
http2_max_buffered_response_bytes => 67_108_864
```

Default: 64 MiB per H2 connection.

This is separate from each Operation's own `buffer_body` limit.

The aggregate limit counts bytes retained for active buffered responses on that
connection.

Accounting is released on completion, failure, cancellation, or connection
close.

## GOAWAY

A received GOAWAY marks the connection draining.

No new Operations are assigned to it.

Existing streams may finish.

Transparent retry is not currently attempted because the selected binding does
not expose enough received GOAWAY last-stream-id information to safely identify
streams that were guaranteed unprocessed.

Guessing would risk replaying a request the peer already acted on.

## Cancellation and failure

HTTP/2 distinguishes stream failure from connection failure.

Where protocol state permits:

- Transaction cancellation resets only that stream;
- stream protocol errors fail only that Transaction;
- connection errors fail all Transactions owned by that connection.

This isolation is an important difference from HTTP/1 cancellation behavior.

## Redirects, cookies, and authentication

These remain high-level Client policy.

The H2 executor does not implement separate redirect, cookie, or authentication
rules.

A redirect or authentication retry creates another normal Transaction and may
reuse an H2 connection where policy and state allow.

## Deliberate HTTP/1 fallbacks

The following currently use the HTTP/1 path even when the high-level Client has
HTTP/2 enabled:

- explicit forward-proxy routes;
- HTTP/1 Upgrade;
- CONNECT tunnel handoff;
- explicit HTTP version selection.

These operations have HTTP/1 transport semantics that are not equivalent to an
HTTP/2 stream.

## Not implemented as current H2 features

- cleartext h2c;
- cross-origin connection coalescing;
- transparent GOAWAY replay;
- HTTP/2 CONNECT stream transport;
- RFC 8441 extended CONNECT/WebSocket-over-H2;
- application API for server push;
- a public H2-specific Connection class.

## Connection subclasses

The public `Client::Connection` and `Server::Connection` classes are HTTP/1
executors and subclass points.

High-level HTTP/2 currently requires the default connection classes.

This avoids silently changing the application-defined object class during ALPN
selection.

## Security and resource policy

HTTP/2 introduces connection-wide resource concerns because many streams share
one transport.

Current public limits cover:

- decoded header-list size;
- client aggregate buffered-response memory;
- server advertised concurrent streams;
- client local active-stream admission.

nghttp2 should remain the owner of protocol state it already enforces correctly.

Additional application-visible knobs should be added only when they represent a
real policy choice rather than merely exposing every libnghttp2 setting.

## Validation

HTTP/2 release validation should continue to cover:

- ALPN selection and HTTP/1 fallback;
- concurrent streams;
- streaming uploads and responses;
- redirect/cookie/auth policy;
- per-stream cancellation and failure;
- GOAWAY draining;
- header-list limits;
- aggregate buffering limits;
- malformed peer behavior;
- interoperability against independent HTTP/2 tooling.

Performance work should use multiplexed realistic workloads rather than
optimizing only for a one-stream echo case.

## Current h2spec baseline

Release validation uses h2spec v2.6.0.

The accepted current baseline is:

```text
144 passed
1 skipped
1 failed
146 total
```

The known failure is RFC 9113 section 5.1.1's lower new stream-identifier case.

This baseline should not regress silently. A release that changes it should
record whether the difference comes from Linux::Event::HTTP integration,
Net::HTTP2::nghttp2, libnghttp2, or the test environment.
