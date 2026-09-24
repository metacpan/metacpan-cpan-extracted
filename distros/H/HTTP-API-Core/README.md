# HTTP::API::Core

[![CPAN version](https://img.shields.io/cpan/v/HTTP-API-Core.svg)](https://metacpan.org/dist/HTTP-API-Core)
[![CI](https://github.com/kawamurashingo/HTTP-API-Core/actions/workflows/test.yml/badge.svg)](https://github.com/kawamurashingo/HTTP-API-Core/actions/workflows/test.yml)
[![Perl](https://img.shields.io/badge/perl-5.10%2B-blue.svg)](https://www.perl.org/)
[![CPAN Testers](https://img.shields.io/badge/CPAN-Testers-blue.svg)](https://www.cpantesters.org/distro/H/HTTP-API-Core.html)
[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](https://dev.perl.org/licenses/)

**Production-ready API client plumbing for Perl — without replacing your HTTP stack.**

Retries, pagination, rate limits, authentication, structured errors, JSON handling, observability, and idempotency in one small, dependency-light core.

```perl
use HTTP::API::Core;

my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.com',
);

my $users = $api->get('/users')->json;
```

Keep using `HTTP::Tiny`, LWP, Mojo::UserAgent, Furl, or your preferred transport. `HTTP::API::Core` sits above it and centralizes the policy that otherwise gets reimplemented in every API client.

**You write the service-specific methods. HTTP::API::Core handles the plumbing.**

## Is this for me?

Use `HTTP::API::Core` when you are building an API client or small SDK and do not want to reimplement the same plumbing for every service:

* JSON request and response handling
* query parameter encoding
* `application/x-www-form-urlencoded` request-body encoding
* structured errors
* safe retries and `Retry-After`
* rate-limit handling
* next-URL, page-number, and cursor pagination
* authentication hooks
* request IDs and timing
* idempotency keys
* transport adapters

You still write the small, service-specific methods that make your client useful:

```perl
sub get_user {
    my ($self, $id) = @_;
    return $self->{api}->get("/users/$id")->json;
}
```

The core handles the policy around that request.

## Quick start

Install the latest release from CPAN:

```console
cpanm HTTP::API::Core
```

Or with the CPAN client:

```console
cpan HTTP::API::Core
```

For development from a checkout:

```console
perl Makefile.PL
make
make test
```

See the [distribution on MetaCPAN](https://metacpan.org/dist/HTTP-API-Core) for release information and generated module documentation.

Then create a client:

```perl
use HTTP::API::Core;

my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.com',
    headers  => {
        Authorization => "Bearer $ENV{API_TOKEN}",
    },
    timeout => 10,
    retry => {
        attempts   => 3,
        base_delay => 0.25,
        max_delay  => 5,
        jitter     => 1,
    },
);

my $response = $api->get('/users');
my $data = $response->json;
```

## Why not just call the HTTP client directly?

An API wrapper often starts simple:

```perl
my $response = $http->get($url);
```

Then production requirements arrive: encode parameters, decode JSON, normalize failures, retry transient errors, respect rate limits, paginate, attach authentication, capture request IDs, and make the whole thing testable.

`HTTP::API::Core` provides those common pieces without becoming a service-specific SDK or a new HTTP stack.

## Common use cases

**Building a GitHub-like API client?** Use page-number pagination and normalized rate-limit metadata.

**Building a Slack-like API client?** Use cursor pagination without writing the iteration loop yourself.

**Calling an unreliable API?** Configure conservative retries with exponential backoff, jitter, and `Retry-After` support.

**Building an internal SDK?** Keep authentication, structured errors, logging/tracing hooks, and transport details out of your resource methods.

## Real API examples

Tested examples show how the same core maps onto APIs with different conventions:

* `HTTP::API::Core::Example::GitHub` — page-number pagination over a top-level JSON array, plus GitHub rate-limit metadata
* `HTTP::API::Core::Example::Slack` — cursor pagination using `response_metadata.next_cursor`
* `HTTP::API::Core::Example::Cloudflare` — page-number pagination using `result_info.total_pages`

See [docs/REAL_API_EXAMPLES.md](docs/REAL_API_EXAMPLES.md).

These are integration recipes, not official SDKs for those services.

## Features at a glance

### Query parameters

Pass a hash reference instead of building query strings by hand:

```perl
my $response = $api->get('/users',
    query => {
        state => 'active',
        tag   => ['admin', 'staff'],
        after => undef,
    },
);
```

Values are percent-encoded, array references generate repeated keys, undefined values are omitted, and existing query strings and fragments are handled correctly.

### Form request bodies

Use the form helper when an API expects `application/x-www-form-urlencoded` data:

```perl
use HTTP::API::Core::Form qw(form_urlencode);

my $response = $api->post('/token',
    headers => { 'content-type' => 'application/x-www-form-urlencoded' },
    content => form_urlencode({
        grant_type => 'client_credentials',
        scope      => 'read write',
    }),
);
```

The helper uses UTF-8-aware form encoding, deterministic key ordering, and repeated keys for array-reference values. Parameter values may be scalars, array references containing scalars, or `undef`; unsupported nested references are rejected instead of being stringified. `undef` is encoded as an empty form value. Content-Type remains explicit so request policy stays visible at the call site.

### Authentication

Authentication helpers are implemented as `before_request` hooks:

```perl
use HTTP::API::Core::Auth qw(bearer_auth);

my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.com',
    hooks => {
        before_request => bearer_auth($token),
    },
);
```

Bearer tokens, HTTP Basic authentication, API-key headers, and API-key query parameters are supported. OAuth token acquisition and refresh deliberately remain outside the core.

See [docs/AUTHENTICATION.md](docs/AUTHENTICATION.md).

### Pagination

Next-URL, page-number, and cursor pagination share one iterator interface:

```perl
my $pager = $api->paginate(
    '/users',
    mode  => 'cursor',
    items => 'data.users',
    next  => 'meta.next_cursor',
    query => { limit => 100 },
);

while (my $user = $pager->next) {
    ...
}
```

Extractors may be dotted paths or coderefs. Repeated next URLs or cursors are rejected instead of looping forever.

### Retries and rate limits

Retries are intentionally conservative. By default, only `GET`, `HEAD`, `PUT`, `DELETE`, and `OPTIONS` are retried.

Retryable failures include transport errors, HTTP `408`, `425`, `429`, `5xx`, and exhausted-quota `403` responses. Delays use exponential backoff with jitter; `Retry-After` delay-seconds or HTTP-date values take precedence when available.

Responses expose normalized rate-limit metadata:

```perl
my $rate = $response->rate_limit;

say $rate->remaining    if defined $rate->remaining;
say $rate->wait_seconds if $rate->exhausted;
```

### Structured errors

Failures use `HTTP::API::Core::Error` with machine-readable categories:

* `encode`
* `decode`
* `transport`
* `http`
* `hook`

Application code can inspect fields such as `category`, `status`, `retryable`, and `request_id` instead of parsing human-readable messages.

See [docs/ERRORS.md](docs/ERRORS.md).

### Hooks and observability

Client-level and per-request hooks let you add authentication, logging, metrics, tracing, or other cross-cutting behavior without subclassing.

Responses expose transport elapsed time and common request IDs:

```perl
say $response->elapsed;
say $response->request_id if defined $response->request_id;
```

### Idempotency

Supply an idempotency key without assuming a service-specific header:

```perl
my $response = $api->post(
    '/payments',
    json => { amount => 1000 },
    idempotency => {
        key    => $key,
        header => 'Idempotency-Key',
    },
);
```

The core does not generate keys automatically or make unsafe methods retryable implicitly.

See [docs/IDEMPOTENCY.md](docs/IDEMPOTENCY.md).

### Transport adapters

Use the `transport` option to integrate another HTTP implementation:

```perl
my $api = HTTP::API::Core->new(
    base_url  => 'https://api.example.com',
    transport => My::Transport->new(...),
);
```

Adapters can be coderefs or objects with a `request` method. Transport exceptions and malformed results become structured `transport` errors.

See [docs/TRANSPORT.md](docs/TRANSPORT.md).

## Detailed reference

For the complete behavioral notes and examples—including hooks, observability, rate-limit semantics, all pagination modes, retry policy, response handling, errors, idempotency, and transport adapters—see [docs/REFERENCE.md](docs/REFERENCE.md).

## Response API

Response handling is explicit and predictable:

```perl
$response->status;
$response->headers;
$response->header('content-type');
$response->content;
$response->text;
$response->content_type;
$response->is_json;
$response->json;
```

See [docs/RESPONSE.md](docs/RESPONSE.md).

## Scope and project direction

`HTTP::API::Core` aims to stay small, predictable, dependency-light, transport-independent, and safe for production use.

Service-specific SDK behavior, complete OAuth flows, OpenAPI generation, GraphQL-specific clients, WebSockets, HTTP server functionality, and async runtime concerns intentionally remain outside the core.

See [DESIGN.md](DESIGN.md) for the full project direction and criteria for 1.0.

## License

Same terms as Perl itself.
