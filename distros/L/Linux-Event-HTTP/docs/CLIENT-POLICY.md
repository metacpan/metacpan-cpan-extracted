# Client policy

This document describes high-level policy owned by
`Linux::Event::HTTP::Client`.

The protocol executors do not duplicate these rules. The same policy model is
used whether an exchange runs over HTTP/1 or HTTP/2.

## Transaction rule

A `Client::Operation` is one high-level client action.

A `Transaction` is exactly one Request/Response exchange.

Therefore:

- a redirect creates another Transaction;
- an authentication retry creates another Transaction;
- Operation history preserves every exchange.

## Redirects

Recognized automatic redirects:

- 301
- 302
- 303
- 307
- 308

Default limit:

```text
5
```

Set `max_redirects => 0` to disable automatic following.

Method handling:

- 301/302 may convert POST to GET;
- 303 uses GET except for HEAD;
- 307/308 preserve method and body.

Complete scalar bodies can be replayed when policy requires it.

Streaming Request producers are not assumed rewindable and are not replayed
automatically.

Cross-origin redirects do not blindly copy caller-supplied Authorization or
Cookie fields.

## Cookies

Cookie policy is delegated to an application-owned `HTTP::CookieJar`.

Example:

```perl
my $client = Linux::Event::HTTP::Client->new(
    loop       => $loop,
    cookie_jar => $jar,
);
```

The Client does not create an implicit global cookie store.

Before an ordinary exchange, the jar is consulted using the target URL.

Set-Cookie fields from ordinary final responses, redirects, and authentication
challenge responses are fed back to the jar before the next policy step.

Cookie identity is always the target URL, not the proxy route.

When a cookie jar is configured, it owns Cookie generation for that request.

## Authentication

Authentication mechanics are delegated to `Uniform::HTTP::Auth`.

The Client owns HTTP lifecycle around those mechanics.

`auth` handles target-server 401 challenges.

`proxy_auth` handles proxy 407 challenges.

Example:

```perl
my $auth = Uniform::HTTP::Auth->new(
    credentials => sub ($context) {
        return lookup_credentials($context);
    },
);

my $client = Linux::Event::HTTP::Client->new(
    loop       => $loop,
    auth       => $auth,
    proxy_auth => $auth,
);
```

Default automatic authentication retry limit:

```text
3
```

Set `max_auth_retries => 0` to expose 401/407 as ordinary final responses.

Authentication retry creates another Transaction.

Streaming body producers are not replayed after a challenge.

Generated authentication fields are attempt-local. Redirected requests can be
challenged again normally.

## Forward proxies

A Client may have a default explicit proxy:

```perl
proxy => 'http://proxy.example:3128'
```

An individual request may override it.

Two identities remain separate:

```text
target URL -> application request identity, cookies, target auth
proxy URL  -> route connection, proxy auth
```

Ordinary HTTP forward-proxy requests use absolute-form targets.

The idle HTTP/1 route pool is keyed by route origin, allowing sequential target
origins to reuse one persistent proxy route where valid.

## HTTPS proxy endpoint

If the proxy URL itself is HTTPS, TLS is established to the proxy endpoint.

That does not imply CONNECT to the target.

An HTTPS target sent through ordinary forward-proxy mode remains an absolute
target URI handled by that proxy.

Use `connect_tunnel()` when an actual CONNECT tunnel is required.

## CONNECT

`connect_tunnel($proxy_url, $target_authority, ...)` is an explicit HTTP/1.1
CONNECT operation.

The proxy endpoint and tunnel target are separate inputs.

Proxy authentication may retry a 407 before final tunnel success/failure.

A successful 2xx response transitions the same live Linux::Event stream to the
requested tunnel class.

## HTTP/2 interaction

Direct HTTPS Operations may negotiate HTTP/2 when `http2 => 1`.

Redirect, cookie, and authentication policy remains unchanged at the high level.

Current explicit forward-proxy routes and CONNECT tunnel establishment use the
HTTP/1 path.

## Deliberately deferred policy

The Client does not currently provide implicit operating-system/browser-style
proxy discovery such as:

- HTTP_PROXY / HTTPS_PROXY / ALL_PROXY environment discovery;
- NO_PROXY matching;
- PAC;
- SOCKS;
- preemptive authentication caches.

These can be added when a concrete application requirement justifies their
policy surface.
