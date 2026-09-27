# Linux::Event::HTTP architecture

This document describes the current production architecture of
Linux::Event::HTTP.

It is intentionally about ownership and invariants, not the history of how the
implementation arrived here.

## Layering

Linux::Event::HTTP is a protocol layer above Linux::Event.

Linux::Event owns:

- sockets and file descriptors;
- epoll readiness;
- TLS transport;
- transport input/output buffering;
- transport backpressure;
- stream lifecycle;
- live stream transition.

Linux::Event::HTTP owns:

- HTTP message parsing and validation;
- HTTP body framing;
- HTTP persistence rules;
- Request and Response objects;
- Transaction lifecycle;
- high-level client policy;
- HTTP/1 and HTTP/2 protocol execution.

Application policy remains above both layers.

Linux::Event::HTTP deliberately does not become a web framework.

## Public object model

The public model is shared by HTTP/1 and HTTP/2.

### Request

`Linux::Event::HTTP::Request` is one HTTP request message.

It owns message data such as:

- method;
- request target;
- version;
- scheme/authority metadata where represented;
- ordered lossless headers;
- optional complete scalar body.

It does not own a connection or Transaction.

### Response

`Linux::Event::HTTP::Response` is one HTTP response message.

It owns:

- status;
- optional HTTP/1 reason phrase;
- version;
- ordered lossless headers;
- optional complete scalar body.

It does not own a connection or Transaction.

### Transaction

`Linux::Event::HTTP::Transaction` is exactly one Request/Response exchange.

It owns exchange lifecycle:

- request and response association;
- outgoing streaming-body producers;
- cancellation;
- delayed response send;
- HTTP/1 Upgrade handoff;
- HTTP/1 CONNECT handoff.

A Transaction does not own the transport or connection pool.

For HTTP/1, one connection executes one Transaction at a time.

For HTTP/2, one connection may execute many Transactions concurrently, one per
stream.

### Client::Operation

`Linux::Event::HTTP::Client::Operation` is one high-level client action.

It normally contains one Transaction.

Redirects and automatic authentication retries create additional Transactions
inside the same Operation.

This preserves the invariant:

> one Transaction == one HTTP Request/Response exchange

### Server and Client

`Linux::Event::HTTP::Server` and `Linux::Event::HTTP::Client` are the ordinary
high-level application entry points.

They hide protocol-executor selection where possible.

## HTTP/1 execution

HTTP/1 server request heads and client response heads are parsed through the
private native input path built around vendored picohttpparser.

Linux::Event::HTTP still owns HTTP/1 body framing and message semantics.

The public advanced HTTP/1 executors are:

- `Linux::Event::HTTP::Server::Connection`
- `Linux::Event::HTTP::Client::Connection`

They intentionally remain HTTP/1-specific.

HTTP/1 pipelining is not enabled on the client.

## HTTP/2 execution

HTTP/2 uses private protocol executors around
`Net::HTTP2::nghttp2`/libnghttp2.

nghttp2 owns protocol machinery such as:

- HTTP/2 frames;
- HPACK;
- stream state;
- SETTINGS;
- GOAWAY;
- HTTP/2 flow control.

Linux::Event still owns the TLS/socket transport.

The HTTP/2 executors map nghttp2 protocol events into the same public Request,
Response, Transaction, Client, and Server model used by HTTP/1.

Applications do not receive separate public H2 Request or Response classes.

## TLS and protocol selection

Without `http2 => 1`, HTTPS uses the ordinary HTTP/1 path.

With `http2 => 1`, the high-level Server or Client advertises:

```text
h2
http/1.1
```

ALPN selects the protocol.

A critical executor invariant is:

> no HTTP/2 protocol bytes are emitted before the live Linux::Event stream has
> completed its transition from the HTTP/1 selector state to the HTTP/2
> executor state.

The production HTTP/2 path is TLS + ALPN.

Cleartext h2c is not implemented.

## HTTP/2 request mapping

HTTP/2 pseudo-headers are protocol syntax, not ordinary headers.

Mapping:

```text
:method     -> Request->method
:path       -> Request->target
:scheme     -> Request->scheme
:authority  -> Request->authority
HTTP/2      -> Request->version == "2"
```

Pseudo-headers never appear in the ordinary lossless header list.

HTTP/1 can also derive scheme/authority metadata when the wire message itself
contains enough information.

## HTTP/2 response mapping

`:status` maps to `Response->status`.

Received HTTP/2 responses use:

```text
Response->version == "2"
```

HTTP/2 has no reason phrase. A local reason value is not serialized on the H2
wire.

## Body model

### Incoming bodies

Incoming bodies are streaming-first.

If an application installs a body callback, decoded body bytes are delivered
incrementally.

If it does not, bytes are drained rather than implicitly accumulated.

Client response buffering is available only with an explicit bounded
`buffer_body` limit.

### Outgoing bodies

A complete scalar body belongs to Request or Response.

An incremental body producer belongs to Transaction through
`Linux::Event::HTTP::Body::Stream`.

The same producer API is used for HTTP/1 and HTTP/2.

### Backpressure

HTTP does not introduce a second transport output queue.

For HTTP/1, Body::Stream production is governed primarily by Linux::Event
transport backpressure.

For HTTP/2, the executor combines Linux::Event transport backpressure with H2
stream/connection flow control while preserving the same public producer
contract:

```text
write() true  -> bytes accepted; producer may continue
write() false -> bytes accepted; pause until on_drain
```

Protocol-specific window state remains private.

## HTTP/2 multiplexing

The high-level Client maintains an H2 pool per origin.

Once a connection selects H2, later Operations to that origin can use
concurrent streams while earlier Transactions are still active.

Current local admission cap:

```text
100 active submitted streams per H2 connection
```

nghttp2 separately enforces peer SETTINGS behavior.

Before ALPN has completed, same-origin Operations may wait behind a bounded
selector. If H2 wins, they collapse onto the multiplexed connection. If HTTP/1.1
wins, fallback work is fanned out to preserve HTTP/1 concurrency.

## Resource limits

Current H2 application-visible limits include:

- decoded request/response header-list size: 65,536 bytes by default;
- aggregate active buffered client response bytes: 64 MiB per H2 connection;
- server advertised concurrent streams: 100;
- client local active-stream admission cap: 100.

Header-list accounting follows HTTP/2 decoded header-list semantics.

A stream-local limit violation should fail the offending stream rather than
destroy unrelated streams when protocol state permits that isolation.

## GOAWAY

After GOAWAY, an H2 client connection becomes draining:

- no new Operations are assigned to it;
- existing streams may finish;
- the connection retires when no active streams remain.

Transparent replay is deliberately not guessed.

The selected binding does not provide enough received GOAWAY last-stream-id
information to safely distinguish streams that the peer promises it did not
process.

## Redirects, cookies, and authentication

These remain high-level Client policy and are not duplicated inside protocol
executors.

A redirect or authentication retry creates another ordinary Transaction.

The selected HTTP/1 or HTTP/2 connection executes that exchange.

Cookie identity and target authentication are based on the target URL, not the
proxy route.

See `CLIENT-POLICY.md`.

## Forward proxies

Forward-proxy routing is a high-level Client policy.

The target URL remains the Operation identity.

The proxy URL selects the route connection.

Current explicit forward-proxy execution uses the HTTP/1 path, including when
the Client has `http2 => 1`.

## Upgrade and CONNECT

HTTP/1.1 Upgrade and CONNECT handoff transfer ownership of the entire live
transport.

The same Linux::Event Stream object is transitioned to another class after the
HTTP exchange reaches the correct boundary.

Already-read post-HTTP bytes remain available to the next protocol.

This whole-transport model does not apply to multiplexed HTTP/2.

HTTP/2 CONNECT or extended CONNECT would require a stream-level transport
abstraction and are not represented by the current whole-connection handoff API.

## Connection subclasses

The public Connection subclass APIs are HTTP/1 APIs.

A custom Server::Connection or Client::Connection class is not silently
replaced by a private HTTP/2 class.

Therefore high-level `http2 => 1` currently requires the default connection
class.

This boundary is explicit rather than hiding an incompatible subclass identity
change.

## Native boundaries

The HTTP/1 parser path consumes bytes from Linux::Event's native ordered input
buffer before unnecessary Perl scalar construction.

The native boundary is an implementation optimization, not a public parser API.

Public Request and Response semantics do not depend on parser representation.

## Performance policy

Correctness and public API clarity come before isolated benchmark wins.

Performance work should preserve:

- one transport output queue;
- bounded buffering;
- shared HTTP/1 and HTTP/2 message semantics;
- protocol-local failure isolation where possible;
- minimal unnecessary Perl allocation on hot input paths.

Benchmark methodology and current harnesses are documented in
`BENCHMARKING.md`.

## Scope

Linux::Event::HTTP provides HTTP communication.

It does not provide:

- application routing;
- templates;
- sessions;
- application middleware stacks;
- a framework-specific Request/Response replacement.

Those belong above the protocol layer.
