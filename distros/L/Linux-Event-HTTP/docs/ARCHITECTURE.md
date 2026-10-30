# Linux::Event::HTTP architecture

Version 0.004 uses independent Unblock protocol engines. It replaces the
previous Linux::Event::HTTP internals and does not retain the old API.

## Ownership boundaries

- `Linux::Event` owns epoll, TCP sockets, listeners, TLS, UDP readiness,
  timers, output queues, backpressure and stream transitions.
- `Linux::Event::HTTP` owns Linux-native listener and client transport setup,
  socket/QUIC lifecycle, the native borrowed-input bridge, shutdown and
  application-facing `Server` and `Client` convenience.
- `Unblock::HTTP` coordinates protocol selection, client operations, connection
  pooling, transaction lifecycle, WebSocket negotiation and generic handoff.
- `Unblock::HTTP1`, `Unblock::HTTP2` and `Unblock::HTTP3` own HTTP framing,
  message parsing, multiplexing, stream flow control and protocol correctness.
- `Net::QUIC` owns QUIC and remains usable without Linux::Event.
- `Uniform::HTTP` owns canonical Request and Response messages.

The application receives real Unblock Transaction objects and Uniform
Request/Response objects. There are no Linux::Event::HTTP-specific Request,
Response, Transaction, client Operation, HTTP1 parser or HTTP2 executors.

## TCP and TLS paths

`Linux::Event::HTTP::Server` creates a Linux::Event listener and attaches
`Unblock::HTTP::Server` engines to accepted streams.
`Linux::Event::HTTP::Client` extends the Unblock client and supplies
Linux-native connection, scheduling and timeout callbacks. The public API
does not ask applications to implement transport adapters.

The private `_Stream` and `_Transport` classes manage readiness, protocol
attachment, input/EOF/error, output congestion and graceful draining.
TLS ALPN selects HTTP/2 when enabled; HTTP/1 remains the ordinary fallback
unless disabled by protocol policy. Cleartext h2c is not supported.

The optional `_NativeStream` uses a small `xsbridge/NativeBridge.xs`
adapter to Linux::Event's borrowed-input native-consumer ABI. Each of
Unblock::HTTP1 and Unblock::HTTP2 publishes a separate native provider
contract; the bridge checks the selected ABI rather than casting their tables
interchangeably. It contains no HTTP parser. The Perl input path is
available with `native_input => 0` for comparison and diagnostics.

## HTTP/3

When HTTP/3 is enabled, the Server operates a TCP/TLS listener and a UDP
socket at the same concrete host/port. `_QUICSocket` supplies Linux::Event
datagram readiness and timer handoff; Net::QUIC and Unblock::HTTP3 own QUIC
and HTTP3 protocol state. A strict client can choose
`http_version => '3'`. Server callbacks retain their HTTP1/2 signatures.

HTTP3-only listeners and wildcard-address binding are not implemented.
The supported combined TCP/UDP path has real QUIC/TLS loopback,
multi-connection, cancellation, stream credit, timeout and shutdown tests.

## Protocol transitions

HTTP/1 Upgrade or successful CONNECT transfers the *whole* live TCP/TLS
stream and its unread same-read tail to the successor. Output ordering and
TLS state survive the handoff. The native input bridge recognizes
`INPUT_SWITCH` and never parses the unread tail as HTTP again.

HTTP/2 and HTTP/3 Extended CONNECT hand over *one multiplexed transaction*,
not the underlying TCP or QUIC transport. Normal sibling HTTP requests
remain active. A successor is a raw input consumer returned from the
application's `on_handoff` callback. See `docs/CONNECT.md` for contracts.

## Shutdown and validation

`Server->close` stops admission; `shutdown(grace => 30, on_complete => sub ($server) { ... })` drains and releases owned transports. The Client
delegates pooling and operation lifecycle to Unblock. Both native and Perl
input paths run the same rebuilt regression contract in `t/rebuild/`.

HTTP/2 h2spec conformance is verified on Unblock::HTTP2 0.13: all 147
cases pass on the standalone engine and Linux::Event native/Perl paths.
HTTP/1 real-socket benchmarking documents a performance trade-off versus
the prior specialized server; see `docs/BENCHMARKING.md`. Correctness,
message ownership and backpressure remain required. Do not bypass
Uniform validation or add Linux::Event-specific behavior to Unblock.
