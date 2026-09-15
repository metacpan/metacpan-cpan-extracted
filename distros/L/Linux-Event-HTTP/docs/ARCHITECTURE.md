# Linux::Event::HTTP architecture

Linux::Event::HTTP is an HTTP communications layer for Linux::Event. It is not a
web framework or framework-adapter distribution.

## Ownership boundaries

The design separates five responsibilities:

- **Transport** - Linux::Event owns sockets, TLS, readiness, byte buffering,
  backpressure, deadlines, ordered output queues, and event dispatch.
- **Protocol execution** - Client::Connection and Server::Connection own HTTP/1
  parsing, serialization, framing, ordering, persistence, protocol handoff, and
  movement of bytes across Linux::Event transports.
- **Messages** - Request and Response represent HTTP messages independent of
  whether they were created or received by a client or server.
- **Exchange lifecycle** - Transaction represents exactly one Request/Response
  exchange and owns cancellation plus exchange-specific producer/output state.
- **High-level client lifecycle** - Client::Operation represents one application
  client action. It normally contains one Transaction, but may contain several
  when redirects are followed or authentication challenges are retried.

`Body::Stream` is the writable producer used by Transaction for outgoing
incremental Request or Response bodies. It is not a message and does not own a
second transport queue.

Reusable transport or ordered-byte performance work belongs in Linux::Event.
HTTP-specific native code should remain limited to HTTP wire work where a native
boundary is justified by correctness or measurement.

Routing, middleware, sessions, templates, PSGI/PAGI, and general framework
concerns are outside this distribution.

## Public structure

```text
Linux::Event::HTTP
Linux::Event::HTTP::Client
Linux::Event::HTTP::Client::Operation
Linux::Event::HTTP::Client::Connection
Linux::Event::HTTP::Server
Linux::Event::HTTP::Server::Connection
Linux::Event::HTTP::Request
Linux::Event::HTTP::Response
Linux::Event::HTTP::Transaction
Linux::Event::HTTP::Body::Stream
```

There is deliberately no generic public `Linux::Event::HTTP::Connection`.
Client and server connections execute opposite HTTP roles and have different
state machines even though both are Linux::Event stream sockets.

There are deliberately no `Client::Request`, `Client::Response`,
`Server::Request`, or `Server::Response` classes. Endpoint direction does not
change HTTP message identity.

There is deliberately no public proxy object. Proxy selection is high-level
Client route policy. Client::Connection remains a normal HTTP/1 executor and
Request remains an HTTP message rather than a route object.

Cookie and authentication engines are external policy objects rather than new
HTTP message or connection types. `HTTP::CookieJar` owns cookie semantics and
`Uniform::HTTP::Auth` owns HTTP authentication mechanics.

## Message model

```text
client sends Request  -----> server receives Request
client gets Response  <----- server sends Response
```

A locally constructed message is mutable until protocol commit. A received
message uses the same public type but its wire metadata is committed/read-only.
Parsed server Requests retain lazy XS-backed storage rather than being eagerly
expanded into Perl hashes or header objects.

Request and Response conform by behavior to the `Uniform::HTTP` 0.02 message
contract without inheriting from or being replaced by Uniform classes. This lets
other Uniform-aware code consume the native/live Linux::Event::HTTP messages
while connection, Transaction, streaming, retry, and handoff state remain
outside the message objects.

The message classes preserve duplicate header occurrences, inter-field order,
and original field-name spelling. `header_values` returns an array reference.
Capability methods report `has_buffered_body`, `is_mutable`, and
`headers_are_lossless`; Request additionally reports `target_is_exact`.

Common message concepts are:

```text
Request                         Response
-------                         --------
method                          status
target                          reason
version                         version
header                          header
add_header                      add_header
remove_header                   remove_header
header_values                   header_values
header_count                    header_count
header_name                     header_name
header_value                    header_value
content_length                  content_length
body                            body
has_buffered_body               has_buffered_body
is_complete                     is_complete
is_mutable                      is_mutable
headers_are_lossless            headers_are_lossless
target_is_exact
```

`target` is intentionally used instead of `uri`. An HTTP Request contains a
request-target. Full URL parsing, scheme, authority, route selection, Host
synthesis, redirect resolution, proxy selection, authentication policy, cookie
policy, and connection pooling belong to Client. They do not belong in Request
merely because a client needs them.

Request and Response do not retain their peer message, Connection, output
writer, pool, redirect chain, proxy route, authentication manager, cookie jar,
or protocol-transition state. Those relationships belong to Transaction,
Client::Operation, high-level policy, and protocol executors.

HTTP/1-only framing and persistence decisions remain private protocol state
rather than generic message methods.

## Transaction model

A Transaction represents exactly one HTTP exchange:

```text
Transaction
    one Request
    zero/one Response
    lifecycle state
    cancellation/error
    outgoing Request/Response body producer where applicable
    server response-output state
    server Upgrade/CONNECT state where applicable
```

A Transaction does not own a socket, parser, connection pool, URL, proxy route,
redirect chain, authentication manager, cookie jar, or transport output queue.
Its Client::Connection or Server::Connection controller performs protocol
execution.

A redirect is another HTTP exchange and therefore another Transaction. An
automatic 401/407 authentication retry is also another HTTP exchange and
therefore another Transaction. These are invariants, not implementation details.

A successful client/server Upgrade or successful CONNECT completes the HTTP
Transaction before the live transport belongs to the next protocol. Protocol
handoff is an executor/transport transition, not a new kind of HTTP message.

## Client::Operation model

High-level Client methods return Client::Operation rather than pretending a
multi-exchange action is one Transaction:

```text
Client::Operation
    initial URL
    current/final URL
    redirect limit and count
    authentication retry limit and count
    Transaction history
    operation terminal state

        Transaction #1: Request -> 407 Response
        Transaction #2: Request -> 302 Response
        Transaction #3: Request -> 401 Response
        Transaction #4: Request -> 200 Response
```

For the common single-exchange case, Operation delegates `request`, `response`,
`request_body`, `cancel`, and terminal-state access so ordinary code remains
concise. The actual body producer remains Transaction-owned.

`redirect_count` counts followed redirects only. `auth_retry_count` counts
performed automatic authentication retries only. Both kinds of exchange remain
visible in `transactions`; authentication retries repeat the same URL in `urls`.

A proxy route does not change Operation identity. Operation URLs remain target
URLs, including across redirects and target authentication retries. The route
used to reach those targets is Client policy outside Transaction/Operation.

Low-level `Client::Connection->request()` continues to return exactly one
Transaction. Redirect, authentication, cookie, and proxy-route policy exist only
in the high-level Client.

## Server model

`Linux::Event::HTTP::Server` is the ordinary server entry point and a thin
control-plane convenience over `Linux::Event::IO::Sock::Listener`.

```perl
on_request => sub ($conn, $req, $res) {
    $res->body("hello\n");
}
```

The active exchange is available without another callback argument:

```perl
my $tx = $conn->transaction;
```

The objects have different lifetimes:

- `$conn` is the persistent TCP/TLS HTTP connection;
- `$tx` is one HTTP exchange on that connection;
- `$req` is that exchange's Request;
- `$res` is that exchange's Response.

A complete HTTP response does not imply transport shutdown. On persistent
HTTP/1.1 the same socket normally remains available for later Transactions.

## Client model

`Linux::Event::HTTP::Client` is the ordinary outbound entry point:

```text
Client
    absolute target-URL parsing
    redirect policy
    target origin / Host policy
    target and proxy authentication retry policy
    optional cookie-jar policy
    explicit/default proxy-route policy
    TLS transport creation
    route connection selection/reuse
    protocol-handoff policy
    explicit CONNECT tunnel establishment
    convenience verbs

Client::Operation
    one application-facing client action
    one or more Transactions
    target URL history
    redirect/authentication retry accounting
    cancellation and operation terminal state

Client::Connection
    one HTTP/1 socket
    one active Transaction at a time
    Request serialization
    Response parsing/framing
    persistence/reuse eligibility
    validated 101 / CONNECT handoff

Transaction
    exactly one Request/Response exchange
```

The high-level form is:

```perl
my $operation = $client->request(
    'POST',
    'https://example.com/api/items',
    body => $bytes,
    max_redirects => 5,
    max_auth_retries => 3,
    on_redirect => sub ($op, $tx, $res, $next_url) { ... },
    on_response => sub ($tx, $res) { ... },
    on_body => sub ($tx, $res, $bytes) { ... },
    on_complete => sub ($tx) { ... },
    on_error => sub ($tx, $error) { ... },
);
```

Convenience methods are `get`, `head`, `post`, `put`, and `delete`.
`connect_tunnel` is the explicit high-level CONNECT operation. Ordinary requests
may use the Client default proxy, override it per request, or explicitly bypass
it with `proxy => undef`.

The current connection-reuse policy is deliberately bounded:

- no HTTP/1 pipelining;
- one active Transaction per Client::Connection;
- sequential keep-alive reuse;
- at most one idle connection retained per route origin;
- direct route origin equals target origin;
- proxied route origin equals the selected proxy origin;
- sequential requests to different target origins can reuse one persistent proxy
  connection;
- concurrent operations may create additional connections;
- when multiple connections later become idle for one route origin, one is
  retained and extras are closed;
- target redirect/authentication/cookie identity remains target-based even when a
  proxy route does not change;
- proxy authentication identity follows the route origin;
- a connection transitioned to another protocol or tunnel is never returned to
  the HTTP idle pool.

## Target URL and redirect policy

Client uses the established `URI` distribution rather than implementing URL
parsing itself.

Only absolute `http` and `https` target URLs are accepted. Fragments are not
transmitted. Without a proxy, origin-form path plus query becomes the Request
target, with `/` used when the URL has no path. HTTP/1.1 Host is synthesized when
absent. Direct callers may deliberately supply their own Host field.

Userinfo is rejected rather than silently creating authentication policy.

Automatic redirect following recognizes 301, 302, 303, 307, and 308. Relative
Location references are resolved against the current absolute target URL. When a
redirect Location omits a fragment, the existing fragment is inherited for URL
processing; fragments still never enter the HTTP request-target.

`max_redirects` defaults to 5 and may be configured globally or per operation.
Zero disables redirect interpretation completely. In that mode a 3xx is an
ordinary final Response; the Client does not validate or interpret its Location
fields as redirect instructions.

When following is enabled, a redirect is followed only when one Location field
is available. Multiple Location fields are rejected as ambiguous redirect
instructions.

Method/body policy follows common HTTP user-agent semantics:

- 301/302: POST may be changed to GET and its body discarded;
- 303: use GET, except HEAD remains HEAD, and discard the body;
- 307/308: preserve method and body.

A complete scalar body is replayable and may be reused for a method-preserving
redirect. A streaming producer is not inherently rewindable, so automatic
method-preserving redirect of a streaming Request fails rather than guessing.
A redirect that changes POST to GET can proceed because no body replay is
required.

Each redirect hop regenerates Host and framing/connection-specific fields.
Cross-origin target redirects additionally remove caller-managed Authorization
and Cookie. With a cookie jar, Cookie is regenerated from the new target URL.
Uniform-managed Authorization and Proxy-Authorization are attempt-local and are
not copied through redirects; the redirected endpoint can challenge again.

When an operation is explicitly waiting for HTTP Upgrade, a redirect hop also
regenerates `Connection: Upgrade` and the originally offered `Upgrade` protocol
fields. The Client does not forward a previous hop's connection-specific header
verbatim.

`on_response`, `on_body`, and `on_complete` are final-response callbacks.
Intermediate redirect and satisfiable authentication-challenge Responses are
consumed to their actual message boundaries but are not emitted through final
`on_body`. `on_redirect` receives each completed intermediate redirect
Transaction before the next hop begins. Authentication retries do not invoke
`on_redirect`. `on_informational` remains per-Transaction and can run on any
exchange.

## Cookie policy

Cookie policy is delegated to `HTTP::CookieJar`. Client accepts an explicitly
injected jar and never creates hidden cookie state.

For every ordinary target exchange, Client obtains Cookie with:

```perl
$jar->cookie_header($target_url)
```

and feeds every Response Set-Cookie field back with:

```perl
$jar->add($target_url, $value)
```

before redirect/authentication planning or application response callbacks. The
proxy route never becomes cookie identity. Domain, path, expiry, Secure handling,
and cookie ordering remain `HTTP::CookieJar` responsibilities.

When a jar is active, caller-supplied Cookie is rejected so one policy engine
owns cookie selection. `connect_tunnel()` does not consult the cookie jar.

## Authentication policy

Authentication mechanics are delegated to `Uniform::HTTP::Auth 0.02` from the
`Uniform-HTTP` distribution.

Client has two independent policy slots:

```text
auth       -> target 401 / WWW-Authenticate
proxy_auth -> route 407 / Proxy-Authenticate
```

They may refer to different Uniform objects or the same dynamic credential
manager. Each can be a Client default and each can be overridden or explicitly
disabled per ordinary request. `connect_tunnel()` uses `proxy_auth`, not target
`auth`.

Uniform owns challenge parsing, scheme selection, credential lookup, Basic,
Bearer, Digest construction, and Digest nonce/cnonce state. Linux::Event::HTTP
owns receiving the challenge Response, selecting the correct protection-space
origin, deciding replayability, draining the Response, reusing/selecting a
connection, and creating the retry Transaction.

The Client supplies the normalized protection-space origin and the actual
`Linux::Event::HTTP::Request` object to Uniform. Through the shared message
contract Uniform can read the exact method, request-target, and complete buffered
scalar body without consuming an incremental producer. Bodyless requests supply
an explicit empty entity body for Digest `qop=auth-int` calculations.

The exact wire target remains:

```text
direct ordinary request  -> origin-form
proxied ordinary request -> absolute-form
CONNECT                   -> authority-form
```

Target 401 uses the normalized target origin. Proxy 407 uses the selected route
origin. This allows one operation to answer proxy 407 and subsequently target
401 without conflating protection spaces.

`max_auth_retries` defaults to 3 and is independent from `max_redirects`. Zero
exposes 401/407 as ordinary final Responses. Hitting the limit likewise exposes
the next challenge instead of retrying again.

Complete scalar Request bodies are replayable. Streaming body producers are not
replayed automatically even if production has completed: the HTTP layer does
not own enough application state to rewind a producer safely. A satisfiable
challenge therefore terminates such an Operation with a replayability error.

Generated Authorization/Proxy-Authorization fields are attempt-local. They are
not preemptively cached or propagated through redirects. On the same request,
however, a proxy-authenticated attempt that subsequently receives target 401
retains Proxy-Authorization while adding target Authorization.

When `auth` is active, it owns Authorization. When `proxy_auth` is active, it
owns Proxy-Authorization. Caller fields are rejected under those managers;
disable the corresponding manager for an operation when manual construction is
desired.

## Explicit forward-proxy policy

A Client may configure one default forward proxy:

```perl
my $client = Linux::Event::HTTP::Client->new(
    loop => $loop,
    proxy => 'http://proxy.example:3128',
);
```

An ordinary request may override it or bypass it:

```perl
$client->get($url, proxy => 'http://other-proxy.example:3128');
$client->get($url, proxy => undef);
```

The target URL and proxy URL have separate responsibilities:

```text
target URL
    Operation URL/history
    Request Host
    redirect base
    target authentication boundary
    cookie boundary
    ordinary HTTP semantics

proxy URL
    socket/TLS destination
    route-origin pool key
    proxy authentication boundary
```

When a proxy route is selected:

- the proxy URL must be absolute `http` or `https`;
- it must not contain a path or query;
- connection acquisition and reuse use the proxy origin;
- `https` proxy means TLS is established to the proxy;
- the Request target uses HTTP/1 absolute-form based on the target URL;
- fragments remain excluded;
- Host is regenerated from the target URL so Host and the absolute-form target
  cannot disagree;
- scalar/streaming Request bodies and the normal response state machine remain
  unchanged;
- redirects remain target-URL redirects while the selected proxy route is
  carried to the next hop.

This is deliberately implemented above Client::Connection. The low-level
executor does not have a proxy mode; it serializes the Request it is given and
runs the existing HTTP/1 response/framing lifecycle.

An HTTPS target URL with `proxy` is sent as an absolute-form `https://...` URI to
the selected forward proxy. That is not an implicit CONNECT tunnel and does not
establish end-to-end target TLS. Code that needs tunnel semantics uses the
separate `connect_tunnel` operation.

`request('CONNECT', ..., proxy => ...)` is rejected rather than creating a second
way to express CONNECT.

Environment discovery, PAC, NO_PROXY, and SOCKS remain outside the current
explicit route policy.

## Explicit CONNECT tunnel policy

`Client->connect_tunnel($proxy_url,$target_authority,...)` is intentionally a
separate high-level operation rather than hidden behavior on ordinary proxied
requests:

```perl
my $operation = $client->connect_tunnel(
    'http://proxy.example:3128',
    'target.example:443',
    tunnel_to => 'MyTunnelProtocol',
    proxy_auth => $auth,
    on_tunnel => sub ($op, $tx, $res, $connection) { ... },
);
```

The proxy URL selects the actual HTTP/TLS endpoint. The tunnel target remains the
CONNECT authority-form request-target and Host value. An `https` proxy URL means
TLS is established to the proxy before CONNECT; this is distinct from whatever
protocol the application runs inside the resulting tunnel.

CONNECT is HTTP/1.1 and bodyless. Content-Length and Transfer-Encoding are not
sent. A 407 can be handled by the selected Uniform proxy-auth manager; the
challenge Response is drained to its normal HTTP boundary before another CONNECT
Transaction is attempted. A persistent proxy connection can be reused when
eligible.

Any successful 2xx response completes the HTTP Response and Transaction at the
response-head boundary. Content-Length or Transfer-Encoding fields supplied on
that successful response are ignored; subsequent bytes belong to the tunnel and
are handed to `tunnel_to` through Linux::Event `transition_to()`.

A non-2xx CONNECT response that is not automatically retried remains ordinary
HTTP. Its body can be delivered incrementally or through explicit bounded
buffering, and a persistent proxy connection can return to the proxy-origin idle
pool afterward. A successful CONNECT consumes that HTTP connection permanently;
it never returns to the pool.

`connect_tunnel` deliberately does not follow redirects or consult target auth or
cookies.

## Body model

HTTP wire framing and application body handling are separate concepts.
`Content-Length`, HTTP/1 chunked transfer coding, close delimiting, or a future
HTTP/2 DATA-frame boundary tell protocol execution how to identify body bytes.
They do not dictate whether the application buffers, incrementally
produces/consumes, forwards, parses, writes to disk, or discards those bytes.

A message's `body(...)` means the application has a complete scalar byte body.

### Server outgoing Response

```perl
$res->status(200);
$res->header('Content-Type', 'text/plain');
$res->body("hello\n");
```

Inside an HTTP callback, body assignment declares a complete body rather than
writing immediately. Response metadata remains mutable until callback return.

For a Response completed by another event:

```perl
my $tx = $conn->transaction;
$tx->response->body("later\n");
$tx->send_response;
```

Incremental server Response production is Transaction-owned:

```perl
my $body = $conn->transaction->response_body(
    on_drain  => sub ($body) { ... },
    on_cancel => sub ($body) { ... },
);

$body->write($bytes);
$body->complete;
```

Creating the producer does not commit response headers. First write/complete is
the output commit point. Complete scalar body and incremental producer are
mutually exclusive.

### Server incoming Request

`on_request` runs after the validated request head. `on_body` receives decoded
body bytes and `on_request_end` marks the actual body boundary. If `on_body` is
absent, body bytes are drained/discarded rather than accumulated.

### Client outgoing Request

A complete scalar body is stored on Request. Client::Connection adds
Content-Length when needed and checks an explicit Content-Length.

Incremental output is Transaction-owned:

```perl
my $operation = $client->post(
    $url,
    stream_body => {
        on_drain  => sub ($body) { ... },
        on_cancel => sub ($body) { ... },
    },
);

my $body = $operation->request_body;
$body->write($bytes);
$body->complete;
```

Known-length streams enforce Content-Length exactly. Unknown-length HTTP/1.1
streams use chunked transfer coding. HTTP/1.0 streaming requires Content-Length.

The same body producer/framing path is used for direct and forward-proxied
requests; proxy routing changes the request-target form and route connection,
not the outgoing body machinery.

Streaming producers are deliberately not considered replayable for automatic
redirect or authentication retry. Complete scalar bodies are replayable.

### Client incoming Response

Client bodies are incremental-first:

```perl
on_response => sub ($tx, $res) { ... },
on_body => sub ($tx, $res, $bytes) { ... },
on_complete => sub ($tx) { ... },
```

If `on_body` is absent, bytes are drained/discarded. The protocol layer never
creates an implicit unbounded whole-body scalar.

For callers that explicitly want one scalar:

```perl
$client->get(
    $url,
    buffer_body => 1_048_576,
    on_complete => sub ($tx) {
        my $bytes = $tx->response->body;
        ...;
    },
);
```

`buffer_body` and `on_body` are mutually exclusive. The configured limit counts
bytes after HTTP/1 chunk framing is removed. Content-Encoding is not decoded.
The same bound applies while intermediate redirect or authentication-challenge
bodies are consumed.

A known Content-Length above the limit fails before accumulation. Unknown-size
bodies fail when adding decoded bytes would cross the bound. Failure closes the
HTTP/1 connection so unread bytes cannot be mistaken for a reusable stream.

## Commit and completion state

Message, Transaction, and Operation completion are distinct:

- Request/Response `is_complete` describes the message body boundary;
- received metadata is committed/read-only once parsed;
- server `Transaction->is_response_started` describes output start;
- `Transaction->is_complete` means one HTTP exchange succeeded;
- `Client::Operation->is_complete` means the overall high-level client action,
  including followed redirects and performed authentication retries, reached its
  final successful Transaction;
- for a successful client Upgrade, the final 101 Response and Transaction are
  complete and the Operation is marked complete before `on_upgrade` runs;
- for a successful CONNECT tunnel, the 2xx Response and Transaction are complete
  and the Operation is marked complete before `on_tunnel` runs;
- cancellation and errors are separate terminal states.

Proxy routing, cookie policy, and authentication policy do not add new
Transaction lifecycle states. They decide which exchange comes next.

## Client HTTP/1 response framing

Client::Connection applies framing independently from application handling:

- HEAD, 204, and 304 have no delivered body;
- non-switching informational 1xx responses may precede the final Response;
- Content-Length is consumed to the exact declared boundary;
- HTTP/1.1 chunked transfer coding is decoded with the existing native decoder;
- a response without Content-Length or Transfer-Encoding is close-delimited and
  makes the connection non-reusable;
- Transfer-Encoding plus Content-Length is rejected as ambiguous;
- only plain `chunked` Transfer-Encoding is currently supported;
- a validated `101 Switching Protocols` completes HTTP framing and transitions
  the same live stream to the explicitly requested target class;
- any successful 2xx CONNECT response completes HTTP framing at the response
  head and transitions the same live stream into tunnel mode; framing fields on
  that successful response are ignored.

Cancelling an active client Transaction closes its HTTP/1 connection because an
unfinished response cannot generally be skipped safely while preserving stream
reuse. Operation cancellation delegates to the active Transaction.

## Backpressure and transport ownership

Linux::Event remains the only transport-output queue. HTTP does not maintain a
second queue for server or client body producers.

`Body::Stream->write()` preserves Linux::Event flow control:

```text
true  = accepted and producer may continue
false = accepted, but producer should pause until on_drain
```

Linux::Event owns queued bytes, watermarks, pending-byte limits, readiness,
drain signaling, connection progress, and TLS transport state.

The optional Client response buffer is retained message/application data, not a
transport queue. Forward-proxy, cookie, and authentication policy add no queues
of their own.

## Native HTTP/1 boundary

HTTP/1 native work is consolidated in one private extension:

```text
Linux::Event::HTTP::_HTTP1
```

It currently owns:

- picohttpparser server request-head parsing and lazy Request accessors;
- chunked transfer decoding used by server and client;
- server response-head serialization;
- the narrow default server scalar-response builder.

The client response-head parser is intentionally strict Perl code. Do not add
parser XS merely for symmetry. Benchmark representative client workloads before
adding another native fast path.

Forward-proxy selection, cookie policy, authentication orchestration, and
absolute-target construction are high-level Perl policy. They do not justify
another native parser or serializer path.

## Connection classes

`Linux::Event::HTTP::Server::Connection` and
`Linux::Event::HTTP::Client::Connection` are
`Linux::Event::IO::Sock::Stream` subclasses.

Server::Connection owns HTTP/1 server ordering, parsing, response output, and
Upgrade/CONNECT handoff. Client::Connection owns exactly one active client
Transaction, Request serialization, Response framing, reuse eligibility,
validated 101 handoff, and validated CONNECT tunnel handoff.

Client::Connection does not know whether a normal Request is direct or being
sent through a forward proxy, whether its Cookie was selected by a jar, or
whether Authorization came from Uniform. The high-level Client selects route and
policy, constructs the final Request, then gives that HTTP message to the
executor.

Direct Client::Connection use is appropriate when destination acquisition,
proxy routing, redirect, cookie, and authentication policy are being handled
elsewhere.

## TLS

HTTPS uses the same message, lifecycle, and connection classes. TLS remains
Linux::Event transport policy.

For a direct HTTPS request, the target URL host is the TLS server name and the
Client currently offers only `http/1.1` through ALPN.

For an HTTPS forward-proxy endpoint, TLS is established to the proxy and the
target URI is then sent in absolute-form. This is not end-to-end TLS to an HTTPS
target. An HTTPS proxy endpoint in `connect_tunnel` likewise terminates TLS at
the proxy before the CONNECT tunnel begins.

Cookie and target-authentication identity remain based on the target URL.
Proxy-authentication identity remains based on the route endpoint.

There is no separate HTTPS hierarchy.

## Upgrade

Server-side HTTP Upgrade is Transaction lifecycle:

```perl
$res->header('Upgrade', 'my-protocol');
$conn->transaction->upgrade('MyProtocolConnection');
```

The 101 response is validated and queued, the HTTP Transaction completes, and
Linux::Event `transition_to()` hands the same live stream object to the next
protocol class while preserving transport identity/state.

Client-side Upgrade is explicit Client/Client::Connection policy layered on the
same Linux::Event transport primitive:

```perl
my $operation = $client->get(
    $url,
    headers => [
        [ Connection => 'Upgrade' ],
        [ Upgrade    => 'my-protocol' ],
    ],
    upgrade_to => 'MyProtocolConnection',
    on_upgrade => sub ($op, $tx, $res, $connection) {
        ...;
    },
);
```

The Request must be bodyless HTTP/1.1 and advertise `Connection: Upgrade` plus
at least one Upgrade protocol. A successful 101 must use HTTP/1.1, contain
`Connection: Upgrade`, contain no Content-Length or Transfer-Encoding, and
select only protocols offered by the Request.

The 101 Response and HTTP Transaction complete before handoff callback delivery.
Linux::Event `transition_to()` reuses the same live stream object and preserves
bytes already read after the response head as target-protocol input. The
transitioned stream is no longer an HTTP connection and is never returned to the
Client's idle HTTP pool. Redirects and replayable authentication challenges may
precede the 101; each is a distinct Transaction.

An unexpected bare 101 without `upgrade_to` is a protocol error. CONNECT is a
separate sibling handoff operation with different HTTP semantics. WebSocket
handshake/frame semantics belong in a separate `Linux::Event::WebSocket`
distribution that can use the client/server handoff primitives here.

## CONNECT

Low-level callers construct a normal Request with method CONNECT, authority-form
`host:port` target, and matching Host, then request an explicit tunnel target:

```perl
my $tx = $connection->request(
    $request,
    tunnel_to => 'MyTunnelProtocol',
    on_tunnel => sub ($tx, $res, $connection) { ... },
);
```

High-level callers use `connect_tunnel`, which separates the proxy endpoint URL
from the CONNECT target authority. The successful tunnel transition uses the
same Linux::Event `transition_to()` primitive as Upgrade but has different HTTP
validation: any 2xx response forms the tunnel, and response framing fields do
not delimit HTTP content after a successful CONNECT. Non-2xx responses remain
ordinary HTTP and can retain the proxy connection for reuse.

High-level CONNECT can use `proxy_auth` to answer 407 challenges before tunnel
establishment. Uniform receives the proxy origin and actual CONNECT Request;
Linux::Event::HTTP drains the 407 and performs another CONNECT Transaction when
allowed.

CONNECT handling is Perl-side execution policy around existing transport
primitives. It adds no native parser path, extra transport object, or second
output queue.

Ordinary forward-proxy routing and CONNECT are intentionally distinct. The
`proxy` request option sends an absolute URI to a forward proxy and never
silently converts an HTTPS target into a tunnel. `connect_tunnel` is the one
high-level API for explicit tunnel establishment.

## Performance policy

Correctness, ease of correct use, coherent APIs, maintainability, and
composability take priority over HTTP-specific benchmark tricks.

Benchmark discoveries may justify private optimizations, but should not create
alternate public APIs merely to expose a fast path. The ordinary API should take
an optimization transparently when eligible.

Before adding HTTP-specific native transport machinery, first ask whether the
expensive primitive is reusable socket, buffer, or write machinery that belongs
in Linux::Event core.

Do not add a second HTTP output queue. Do not split the consolidated `_HTTP1`
extension without a measured reason. Do not add HTTP-specific XS merely to win a
benchmark.

The transaction-lifecycle ladder is a diagnostic of current internal costs, not
a compatibility surface. It is kept aligned with the Transaction-owned response
lifecycle and its smoke mode runs in regular CI so internal API drift is caught.

## Current status

The current foundation includes:

1. Direction-neutral Request and Response message types conforming behaviorally
   to the Uniform::HTTP 0.02 message contract.
2. Transaction as exactly one Request/Response exchange.
3. HTTP/1 Server and Server::Connection with request-body delivery, persistent
   ordering, scalar/incremental responses, TLS, deferred response send, Upgrade,
   and explicit CONNECT handoff.
4. HTTP/1 Client::Connection with scalar/streaming Request serialization, strict
   Response parsing, informational responses, incremental Content-Length/chunked/
   close body delivery, cancellation, sequential reuse, validated 101 handoff,
   and validated CONNECT tunnel handoff.
5. High-level Client::Operation with distinct Transaction history for redirects
   and authentication retries, separate redirect/auth retry accounting,
   cancellation, and final operation state.
6. High-level Client URL parsing, HTTP/HTTPS route acquisition, explicit/default
   forward-proxy routing with absolute-form targets, bounded route-origin idle
   reuse, common convenience verbs, explicit bounded whole-response buffering,
   redirects, Upgrade orchestration, and explicit HTTP/HTTPS proxy-endpoint
   CONNECT establishment.
7. Explicit `HTTP::CookieJar` integration for target cookie policy without
   duplicating RFC cookie storage/selection logic.
8. Explicit `Uniform::HTTP::Auth 0.02` integration for target 401 and proxy 407
   challenge handling, including Basic/Bearer/Digest mechanics, replay-safe
   retry Transactions, Digest auth-int scalar context, and authenticated CONNECT.
9. One consolidated private `_HTTP1` native extension and no duplicate transport
   queues.

Environment proxy discovery, NO_PROXY, PAC, SOCKS, preemptive auth caches,
Authentication-Info handling, and richer pool policy remain deferred until a
real workload requires them.

Client parser optimization remains measurement-driven. HTTP/2 is future protocol
work. WebSocket remains a separate protocol distribution.
