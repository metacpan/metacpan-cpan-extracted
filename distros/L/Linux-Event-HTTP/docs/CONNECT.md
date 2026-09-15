# CONNECT tunnels

Linux::Event::HTTP treats CONNECT as an HTTP protocol boundary, not as a proxy framework.

## Client CONNECT

The high-level Client explicitly separates the proxy endpoint from the tunnel target:

```perl
my $operation = $client->connect_tunnel(
    'http://proxy.example:3128',
    'target.example:443',
    tunnel_to => 'MyTunnelProtocol',
    headers => [
        [ 'Proxy-Authorization' => $value ],
    ],
    on_tunnel => sub ($operation, $tx, $res, $connection) {
        ...;
    },
);
```

The proxy URL selects the HTTP or HTTPS endpoint to which the Client connects. The second argument is the CONNECT authority-form target and Host value. `tunnel_to` names the Linux::Event stream class that owns the same live socket after a successful tunnel response.

CONNECT is HTTP/1.1 and bodyless. Content-Length and Transfer-Encoding are forbidden on the Request. Any successful 2xx response ends HTTP framing at the end of the response head; Content-Length or Transfer-Encoding fields present on that successful response do not delimit HTTP content. Bytes already read after the head become tunnel input.

A non-2xx response remains ordinary HTTP. Its body may be consumed incrementally or through explicit bounded buffering, and a persistent failed-CONNECT connection may return to the proxy-origin idle pool.

## Server CONNECT

CONNECT arrives through the ordinary server callback. Accepting the tunnel is an explicit Transaction lifecycle operation:

```perl
on_request => sub ($conn, $req, $res) {
    if ($req->method eq 'CONNECT') {
        $conn->transaction->tunnel('MyTunnelProtocol');
        return;
    }

    ...;
};
```

`Transaction->tunnel($target_class)` validates the successful server-side handshake before any tunnel response is emitted. The Request must be HTTP/1.1 CONNECT with an authority-form `host:port` target, exactly one matching Host field, no body, and no Content-Length or Transfer-Encoding. The Response must be a mutable bodyless 2xx response with no Content-Length, Transfer-Encoding, or `Connection: close`.

The normal request-end lifecycle completes first. Linux::Event::HTTP then queues only the successful response head, marks the Response and Transaction complete, clears HTTP state, and calls Linux::Event `transition_to()` so the same accepted stream object belongs to the target protocol class. Already-read bytes following the CONNECT request head are preserved as target-protocol input, while the existing Linux::Event output queue keeps the response head ordered before target-protocol output.

A rejected CONNECT is just an ordinary non-2xx HTTP response. It may carry a normal body and, when persistence permits, the same HTTP connection can process later requests.

## Scope boundary

Neither client nor server CONNECT turns Linux::Event::HTTP into a proxy implementation. The HTTP layer does not decide whether a destination is allowed, open an upstream connection on the server side, relay bytes between two streams, implement proxy authentication policy, or decide which protocol runs inside a successful tunnel.

Those responsibilities belong to the application or to a reusable protocol-bridge layer above HTTP. Linux::Event::HTTP owns the CONNECT handshake, HTTP message lifecycle, and live-stream handoff only.
