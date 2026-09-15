# Client policy

Linux::Event::HTTP keeps transport execution and HTTP message identity separate
from higher-level client policy. Client policy belongs above Client::Connection
and must not turn Request, Response, or Transaction into routing/session objects.

## Implemented: explicit and default forward proxy routes

Ordinary requests may select a proxy per operation:

```perl
$client->get(
    'http://origin.example/path',
    proxy => 'http://proxy.example:3128',
);
```

A Client may also configure one default route:

```perl
my $client = Linux::Event::HTTP::Client->new(
    loop  => $loop,
    proxy => 'http://proxy.example:3128',
);
```

A per-request proxy overrides the Client default, while `proxy => undef`
explicitly bypasses it for that operation.

Target origin controls Host, redirects, target authentication, cookies, and
Operation URLs. Route origin controls connection acquisition, proxy
authentication, and idle reuse. Redirect hops retain the selected route for the
operation.

This remains explicit configuration. Linux::Event::HTTP does not inspect proxy
environment variables, evaluate PAC or NO_PROXY policy, add SOCKS semantics, or
silently convert ordinary proxy routing into CONNECT.

## Implemented: injected HTTP::CookieJar

Cookie policy is delegated to `HTTP::CookieJar` rather than reimplemented here.
The jar is explicit application-owned state:

```perl
use HTTP::CookieJar;

my $jar = HTTP::CookieJar->new;
my $client = Linux::Event::HTTP::Client->new(
    loop       => $loop,
    cookie_jar => $jar,
);
```

Linux::Event::HTTP does not create a hidden jar. The application decides jar
lifetime, sharing, persistence, preloading, and clearing.

For each ordinary request exchange, Client asks the jar for:

```perl
$jar->cookie_header($target_url)
```

and synthesizes the Cookie field only when the returned string is non-empty.
For every Set-Cookie field in an ordinary final, redirect, or authentication
challenge Response, Client calls:

```perl
$jar->add($target_url, $set_cookie)
```

before redirect/authentication policy or application response callbacks run.

The URL supplied to the jar is always the target URL. A forward proxy is only a
route and never becomes the cookie origin. Redirect hops ask the jar again for
the new target URL, so domain, path, expiry, Secure handling, and cookie ordering
remain `HTTP::CookieJar` responsibilities.

When a cookie jar is configured, caller-supplied Cookie fields are rejected so
cookie selection has exactly one owner. Applications that need to seed or alter
cookie state should do so through the jar.

`connect_tunnel()` does not consult the cookie jar. CONNECT is an explicit
exchange with the named proxy endpoint and then a protocol handoff, not an
ordinary target-resource request.

## Implemented: Uniform::HTTP::Auth

Authentication mechanics are delegated to `Uniform::HTTP::Auth 0.02` rather
than implemented in Linux::Event::HTTP.

```perl
use Uniform::HTTP::Auth;

my $auth = Uniform::HTTP::Auth->new(
    credentials => sub ($context) {
        return $store->lookup(
            $context->{origin},
            $context->{realm},
            $context->{scheme},
        );
    },
);

my $client = Linux::Event::HTTP::Client->new(
    loop       => $loop,
    auth       => $auth,
    proxy_auth => $auth,
);
```

`auth` handles target 401 / `WWW-Authenticate`. `proxy_auth` handles route 407 /
`Proxy-Authenticate`. They may be separate Uniform objects or the same dynamic
credential manager. Client defaults can be overridden per ordinary request; an
explicit `undef` disables the corresponding manager for that request.

Uniform owns:

- challenge parsing and validation;
- supported-scheme selection;
- credential lookup;
- Basic, Bearer, and Digest construction;
- Digest nonce/cnonce state.

Linux::Event::HTTP owns:

- receiving 401 and 407 Responses;
- target-versus-route origin selection;
- Request replayability;
- draining the challenge Response to its HTTP boundary;
- connection reuse;
- creating the retry Transaction;
- Operation/callback lifecycle.

Every successful automatic auth retry is another Transaction in the same
Client::Operation. Authentication retry count is tracked separately from
redirect count. `max_auth_retries` defaults to 3 and is an operation-wide limit;
zero exposes 401/407 as ordinary final Responses.

Uniform receives the actual `Linux::Event::HTTP::Request` object for the
exchange. The message contract exposes the exact request-target, so direct
requests use origin-form for Digest calculations, proxied ordinary requests use
absolute-form, and CONNECT uses authority-form. Target 401 uses the target
origin. Proxy 407 uses the selected route origin.

Complete scalar Request bodies are replayable and are available to Uniform
through the Request message, allowing Digest `qop=auth-int` to be calculated
without an HTTP-specific adapter. Bodyless Requests explicitly supply an empty
entity body. Streaming Request producers are never automatically replayed, even
after the producer has finished: Linux::Event::HTTP does not know how application
stream state should be rewound. A satisfiable challenge for such a Request
terminates the Operation with a replayability error.

Generated Authorization and Proxy-Authorization fields are attempt-local. They
are not copied across redirects, because Digest includes request-target state and
Uniform 0.02 deliberately does not implement a preemptive-authentication cache.
A redirected target or proxy can challenge again normally. On the same target
exchange, a proxy-authenticated retry that subsequently receives target 401
keeps the generated Proxy-Authorization while adding target Authorization.

When `auth` is active, caller-supplied Authorization is rejected. When
`proxy_auth` is active, caller-supplied Proxy-Authorization is rejected. This
keeps each authentication field under one policy owner. Disable the relevant
manager for a request when manual construction is desired.

`connect_tunnel()` does not use target `auth`, but it does use the Client's
`proxy_auth` by default and can override or disable it per call. A non-2xx 407 is
drained normally and may retry CONNECT on the reusable proxy connection before a
successful tunnel handoff.

## Deferred policy

Keep these separate until a real workload requires them:

- HTTP_PROXY / HTTPS_PROXY / ALL_PROXY environment discovery;
- NO_PROXY matching;
- PAC;
- SOCKS;
- preemptive authentication caches;
- Authentication-Info / Proxy-Authentication-Info handling;
- richer connection-pool policy;
- parser XS that is not justified by measurement.

The guiding rule remains: high-level policy may make correct use easy, but it
must not change Request/Response identity, expand Transaction beyond one
exchange, or duplicate Linux::Event transport machinery.
