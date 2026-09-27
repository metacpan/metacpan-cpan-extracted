# CONNECT tunnels

Linux::Event::HTTP supports explicit HTTP/1.1 CONNECT tunnel establishment and
handoff.

CONNECT is intentionally separate from ordinary forward-proxy routing.

## Client CONNECT

Use the high-level Client:

```perl
$client->connect_tunnel(
    $proxy_url,
    $target_authority,

    tunnel_to => 'MyTunnelConnection',

    on_tunnel => sub ($tx, $res, $connection) {
        ...
    },

    on_error => sub ($tx, $error) {
        ...
    },
);
```

The proxy URL identifies the HTTP endpoint used to establish the tunnel.

The target authority identifies the requested tunnel destination.

A successful 2xx CONNECT response completes the HTTP Transaction at the
response-head boundary and transitions the same live Linux::Event stream to the
requested class.

Bytes already read after the successful response head are preserved for the
tunnel protocol.

A non-2xx response remains an ordinary HTTP response and may carry a normal
HTTP body.

Proxy 407 authentication can be retried through the configured
`Uniform::HTTP::Auth` proxy manager when the request is replayable.

## Server CONNECT

A server accepts a validated CONNECT request through its active Transaction:

```perl
on_request => sub ($conn, $req, $res) {
    if ($req->method eq 'CONNECT') {
        $conn->transaction->tunnel('MyTunnelConnection');
        return;
    }

    $res->status(405);
    $res->body("not allowed\n");
};
```

The default successful status is 200. Applications may configure another 2xx
status and additional response headers before handoff.

Opening or bridging an upstream destination is application policy. The HTTP
library only completes the HTTP handshake and transfers ownership of the
accepted stream.

## HTTP/2 boundary

The current tunnel API is a whole-transport HTTP/1 handoff.

HTTP/2 CONNECT and extended CONNECT create a byte channel inside one multiplexed
stream instead of transferring the whole connection.

They therefore require a different stream-level transport abstraction and are
not represented by this API.
