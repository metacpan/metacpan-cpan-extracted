# Generic Upgrade and CONNECT handoff (Unblock rebuild)

Linux::Event::HTTP provides generic byte-oriented handoff through the
framework-neutral `Unblock::HTTP` contract. Applications receive real
Unblock transactions; no Linux-specific parser, proxy-policy layer, old
`connect_tunnel()`, or `upgrade_to` API is retained.

## HTTP/1: whole socket transfer

For a successful 101 Upgrade or 2xx CONNECT response, the HTTP1 Server
callback is:

```perl
on_handoff => sub ($tx, $request, $response, $host) {
    return My::Consumer->new(host => $host);
},
```

A client can request an HTTP/1 Upgrade or CONNECT using ordinary
`$client->request(...)` / `$client->get(...)` options, including an
`on_handoff` callback:

```perl
on_handoff => sub ($tx, $response, $host) {
    return My::Consumer->new(host => $host);
},
```

The returned consumer becomes the input owner of the same TCP/TLS stream.
The response is serialized before successor output, and unread data in the
same read is delivered exactly once. The upgraded socket leaves the HTTP
client pool. Applications own its lifetime after handoff.

## HTTP/2 and HTTP/3: individual stream transfer

Extended CONNECT requires peer protocol negotiation. Enable
`http2 => { enable_connect_protocol => 1 }` or
`http3 => { enable_extended_connect => 1 }` as appropriate.

The Server receives `on_handoff => sub ($tx, $request, $bridge) { ... }`
and the Client receives
`on_handoff => sub ($tx, $response, $bridge) { ... }`.
A Client request can use:

```perl
$client->request(
    url          => $url,
    method       => 'CONNECT',
    protocol     => 'raw-tunnel',
    http_version => '2',  # or '3'
    on_handoff   => sub ($tx, $response, $bridge) {
        return My::Consumer->new(bridge => $bridge);
    },
);
```

The bridge supports `unblock_send($bytes)` and
`unblock_finish()`, while the consumer receives `input($bytes)`,
`input_eof()`, `transport_error($error)` and `resume_output()`.
Only the CONNECT stream is transferred; other HTTP transactions continue
over the same TLS/QUIC transport. Deferred output and flow control remain
bounded by the protocol engines. Rejection with no successor does not
dispatch an ordinary request callback.

The executable contracts are
`t/rebuild/104-generic-handoff.t`,
`t/rebuild/105-generic-client.t` and
`t/rebuild/107-generic-multiplex.t`. WebSocket uses its separate
opt-in `on_websocket` / `connect_websocket` interface.
