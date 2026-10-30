# Linux::Event::HTTP 0.004 release notes

This release replaces the previous HTTP implementation with a thin
Linux-native integration of the independent Unblock::HTTP engines.

**This release changes the public API.** The previous Linux::Event::HTTP
Request, Response, Transaction and connection classes are not retained
as compatibility wrappers. Applications should follow the new Server
and Client examples in the README.

**Coordinated WebSocket release:** Linux::Event::WebSocket 0.002 is not
compatible with HTTP 0.004 because it uses removed HTTP internals.
Linux::Event::WebSocket **0.003** replaces that dependency with
published Unblock::HTTP1 and retains its dedicated client/server API.
Publish WebSocket 0.003 before HTTP 0.004 so users can update both
without a broken intermediate installation.

For WebSocket-only programs use Linux::Event::WebSocket. For WebSocket
endpoints already running inside an HTTP server/client, use
Linux::Event::HTTP's on_websocket/connect_websocket interface.
No application needs to configure the underlying framing implementation.

## What's included

- HTTP/1 over TCP/TLS; optional HTTP/2 over TLS with ALPN; optional
  HTTP/3 over QUIC/TLS.
- Real Unblock transactions and Uniform::HTTP request/response messages.
- Streaming requests and responses, bounded buffering, connection pools,
  cancellation, backpressure and graceful shutdown.
- WebSocket support and HTTP Upgrade/CONNECT handoff. On HTTP/2 and
  HTTP/3, Extended CONNECT transfers individual streams rather than
  the entire connection.
- Linux::Event native borrowed-input integration for HTTP/1 and HTTP/2;
  the protocol parsers remain in their standalone engines.
- No dependency on optional HTTP/2, HTTP/3 or WebSocket engines unless
  the corresponding feature is enabled.

## Requirements

Linux and Perl 5.36 or newer, Linux::Event 0.117, Unblock::HTTP 0.03,
Unblock::HTTP1 0.13 and Uniform::HTTP 0.06.

For optional features:
- HTTP/2: Unblock::HTTP2 0.13.
- HTTP/3: Unblock::HTTP3 0.14 and Net::QUIC 0.06.
- WebSocket: Unblock::WebSocket 0.02.

All these prerequisite versions are published on CPAN. No unreleased
engine feature branch is needed for this release.

## Compatibility and limitations

HTTP/2 requires TLS ALPN; h2c and HTTP/2 prior knowledge are not
implemented. HTTP/3 servers currently require a concrete host address
and an accompanying TCP listener. They cannot be wildcard-bound or
HTTP/3-only. See the README for supported configuration.

The new HTTP/1 server does more canonical message and transaction
lifecycle work than the former highly specialized native server.
Its measured maximum requests/second are therefore lower. The
trade-off is documented in docs/BENCHMARKING.md and is not treated
as a protocol correctness failure.

## Verification

Full Linux::Event::HTTP cross-Perl matrix, native and portable HTTP/1
paths, source-distribution tests, optional HTTP/2, HTTP/3 over real
QUIC/TLS, WebSocket and generic protocol handoffs have passed.
Strict h2spec 2.6.0 passed all 147 cases for the independent HTTP/2
engine and for both Linux::Event input paths.

Release preparation does not create a GitHub release or publish to CPAN.
Publication remains a maintainer action.
