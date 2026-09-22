# Vendored bq_websocket

Upstream: https://github.com/bqqbarbhg/bq_websocket
Upstream commit: 6c188d3f0edca38d7a8926e0d30f4c145414ba4c
License used here: MIT

Linux::Event::WebSocket vendors the protocol core directly so CPAN installs do
not depend on a system bq_websocket package. The upstream platform/socket layer
is not used. Linux::Event continues to own sockets, epoll, TLS, HTTP Upgrade,
write buffering, backpressure, timers, and connection lifecycle.

The source in this directory is intentionally not a pristine upstream copy.
Linux::Event::WebSocket maintains a small patch set required by its RFC 6455
policy and Linux-only runtime:

- client frame masks use Linux getrandom(2);
- incoming Close codes accept the RFC range through 1014 plus 3000-4999 while
  rejecting reserved 1004, 1005, and 1006;
- incoming Close reasons are checked against RFC 3629 before automatic echo;
- one-byte Close payloads are rejected;
- control payloads larger than 125 bytes are rejected before Ping/Close side
  effects can occur;
- every received Ping retains its own Pong response instead of keeping only the
  latest pending Pong;
- when control messages are exposed, a validated received Close is copied before
  the original object is retained for automatic echo; rejected Close frames are
  never copied, preserving native allocation ownership on protocol errors.

The XS adapter additionally configures bq with skip_handshake, disables its
automatic ping/timeout policy, removes the library's partial-fragment count cap
while preserving Linux::Event::WebSocket's message-size limit, and compiles the
context single-threaded because each connection is owned by one Linux::Event
loop.

Any future upstream refresh must re-apply and re-test these differences with
the normal suite and both Autobahn directions before it is accepted.
