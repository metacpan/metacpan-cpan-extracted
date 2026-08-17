# HTTP::API::Core

A small, dependency-light foundation for building JSON HTTP API clients in Perl.

The goal is not to replace `HTTP::Tiny`, LWP, Mojo::UserAgent, Furl, or another
HTTP transport. It provides the API-client layer applications repeatedly rebuild:
base URLs, JSON handling, query parameters, structured errors, retries,
pagination, rate limits, lifecycle hooks, authentication helpers, observability,
idempotency, and a transport adapter contract.

## Basic usage

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

## Query parameters

Pass a hash reference as `query` instead of building query strings by hand:

```perl
my $response = $api->get('/users',
    query => {
        state => 'active',
        tag   => ['admin', 'staff'],
        after => undef,
    },
);
```

Values are percent-encoded. Array references generate repeated keys, undefined
values are omitted, existing query strings are preserved, and parameters are
inserted before URL fragments. `before_request` hooks see the final encoded URL.

## Authentication helpers

`HTTP::API::Core::Auth` provides small authentication helpers implemented as
`before_request` hooks rather than service-specific client state.

```perl
use HTTP::API::Core::Auth qw(bearer_auth basic_auth api_key_auth);

my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.com',
    hooks => {
        before_request => bearer_auth($token),
    },
);
```

Bearer tokens, HTTP Basic authentication, API-key headers, and API-key query
parameters are supported. Explicit request headers take precedence over helper
values. OAuth token acquisition and refresh flows remain outside the core.

See `docs/AUTHENTICATION.md`.

## Observability

Responses expose transport elapsed time and common request IDs without choosing
a logging, metrics, tracing, or telemetry framework:

```perl
my $response = $api->get('/users');

say $response->elapsed;
say $response->request_id if defined $response->request_id;
```

`request_id` recognizes `X-Request-Id`, `Request-Id`, and `X-Correlation-Id`.

Lifecycle hooks receive the same per-attempt metadata in their context.
`started_at` is captured immediately before transport begins, `elapsed` measures
transport time, and `request_id` is populated before `after_response` or
`on_error` runs.

```perl
hooks => {
    after_response => sub {
        my ($response, $ctx) = @_;
        $metrics->observe($ctx->{elapsed});
    },
}
```

HTTP and transport errors also expose elapsed time; HTTP errors retain the
normalized request ID.

## Hooks

Client-level and per-request hooks make it possible to add authentication,
logging, metrics, tracing, or other cross-cutting behavior without subclassing.

```perl
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.com',
    hooks => {
        before_request => sub {
            my ($ctx) = @_;
            $ctx->{headers}{Authorization} = "Bearer $token";
        },
        after_response => sub {
            my ($response, $ctx) = @_;
            log_status($response->status);
        },
        on_error => sub {
            my ($error, $ctx) = @_;
            record_failure($error->category);
        },
    },
);
```

`before_request` receives a mutable context containing `method`, `url`,
`headers`, `content`, and the retry `attempt`. It runs immediately before each
transport attempt. `after_response` runs after a successful response is
received. `on_error` runs before retry is considered.

Each hook can be a coderef or an arrayref of coderefs. Request-local hooks are
appended after client-level hooks:

```perl
$api->get('/users',
    hooks => {
        before_request => sub {
            my ($ctx) = @_;
            $ctx->{headers}{'X-Request-Tag'} = 'users';
        },
    },
);
```

Hook failures are surfaced as structured, non-retryable `hook` errors.

## Rate limits

Responses expose normalized rate-limit metadata:

```perl
my $response = $api->get('/users');
my $rate = $response->rate_limit;

say $rate->limit        if defined $rate->limit;
say $rate->remaining    if defined $rate->remaining;
say $rate->resource     if defined $rate->resource;
say $rate->wait_seconds if $rate->exhausted;
```

`HTTP::API::Core::RateLimit` understands numeric `RateLimit-Limit`,
`RateLimit-Remaining`, and `RateLimit-Reset` fields as well as the widely used
`X-RateLimit-*` family and `Retry-After`. `X-RateLimit-Reset` is treated as a UTC
epoch timestamp; `RateLimit-Reset` is treated as a delay in seconds.

HTTP errors expose the same object through `$error->rate_limit`.

For exhausted quotas, `Retry-After` remains the first choice. When it is absent,
retry handling can fall back to reset metadata. A `403` is only treated as a
rate-limit retry when the response explicitly reports `remaining == 0`; ordinary
authorization failures are not retried.

## Pagination

`paginate` returns an iterator with `next` and `all`. All pagination styles use
the same API.

### Next URL

```perl
my $pager = $api->paginate(
    '/users',
    mode  => 'next_url',
    items => 'data.users',
    next  => 'links.next',
);

while (my $user = $pager->next) {
    ...
}
```

The `next` value may be an absolute URL or a path relative to `base_url`.

### Page number

```perl
my $pager = $api->paginate(
    '/users',
    mode      => 'page',
    items     => 'users',
    page_size => 100,
);

my @users = $pager->all;
```

The defaults are `page` for the page parameter and `per_page` for the page-size
parameter. Override them with `page_param` and `page_size_param`. If the response
exposes an explicit boolean, use `has_more => 'meta.has_more'`.

### Cursor

```perl
my $pager = $api->paginate(
    '/users',
    mode  => 'cursor',
    items => 'data.users',
    next  => 'meta.next_cursor',
    query => { limit => 100 },
);
```

The default cursor parameter is `cursor`; override it with `cursor_param`.

Extractor values such as `data.users` and `meta.next_cursor` are dotted paths. A
coderef can also be supplied when an API needs custom extraction logic.

Repeated next URLs or cursors are detected and rejected rather than looping
forever.

## Response API

Responses keep body handling explicit and predictable:

```perl
my $response = $api->get('/users');

$response->status;
$response->headers;
$response->header('content-type');
$response->content;
$response->text;
$response->content_type;
$response->is_json;
$response->json;
```

`content_type` strips parameters such as `charset` and normalizes the media type
to lower case. `is_json` recognizes `application/json` and structured syntax
suffix media types such as `application/problem+json`.

Calling `json` is explicit and does not require a JSON Content-Type header. Empty
or whitespace-only bodies return `undef`; invalid non-empty JSON raises a
structured `decode` error. `text` performs no charset decoding.

The `headers` method returns a copy so callers cannot accidentally mutate
response state.

See `docs/RESPONSE.md`.

## Error model

Failures use `HTTP::API::Core::Error`. Machine-readable categories are:

- `encode`
- `decode`
- `transport`
- `http`
- `hook`

HTTP errors retain their response and expose `body`, `text`, `json`, `headers`,
and `header` helpers. Code should use structured fields such as `category`,
`status`, `retryable`, and `request_id` instead of parsing human-readable error
messages.

See `docs/ERRORS.md`.

## Retry policy

Retries are intentionally conservative. By default only `GET`, `HEAD`, `PUT`,
`DELETE`, and `OPTIONS` are retried. `POST` and `PATCH` are not automatically
repeated because doing so can duplicate side effects.

Retryable failures include transport errors, HTTP `408`, `425`, `429`, `5xx`,
and exhausted-quota `403` responses. Delays use exponential backoff with jitter.
A numeric `Retry-After` header takes precedence; exhausted rate-limit reset
metadata is used as a fallback.

```perl
$api->get('/status', retry => 0);

$api->post('/jobs',
    json => { task => 'sync' },
    retry => {
        attempts => 2,
        methods  => ['POST'],
    },
);
```

## Idempotency

Idempotency keys can be supplied without assuming a service-specific header
name:

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

The core does not generate keys automatically and does not automatically make
unsafe methods retryable merely because an idempotency key is present. An
explicit request header with the same case-insensitive name takes precedence.

See `docs/IDEMPOTENCY.md`.

## Transport adapters

The `transport` constructor option is a supported extension point. It accepts
either a code reference or an object with a `request` method using the same
small contract:

```perl
my $api = HTTP::API::Core->new(
    base_url  => 'https://api.example.com',
    transport => My::Transport->new(...),
);
```

Adapters receive `($method, $url, \%options)` and return a hash containing at
least `status`, with optional `reason`, `headers`, and `content`. Transport
exceptions and malformed results become structured `transport` errors.

This keeps HTTP-library-specific integrations outside the core. See
`docs/TRANSPORT.md`.

## Features

- base URL handling
- default and per-request headers
- first-class query parameter encoding
- JSON request encoding and response decoding
- configurable timeout
- structured transport, HTTP, encode, decode, and hook errors
- request ID extraction
- response and error elapsed-time observability
- per-attempt observability metadata in lifecycle hook contexts
- automatic retry with exponential backoff and jitter
- normalized rate-limit metadata and reset-aware retry fallback
- next-URL, page-number, and cursor pagination
- client-level and per-request lifecycle hooks
- Bearer, Basic, and API-key authentication helpers
- explicit response body and Content-Type helpers
- idempotency-key support
- coderef and object transport adapters

## Project direction

The core aims to stay small, predictable, dependency-light, transport-independent,
and safe for production use. Service-specific SDK behavior, complete OAuth
flows, OpenAPI generation, GraphQL-specific clients, WebSockets, HTTP server
functionality, and async runtime concerns remain outside the core.

See `DESIGN.md` for the full project direction and criteria for 1.0.

## Migration from HTTP::API::Client

`HTTP::API::Core` continues the pre-release `HTTP::API::Client` project under a
new CPAN namespace. See `docs/MIGRATION_FROM_HTTP_API_CLIENT.md` for details.

## License

Same terms as Perl itself.
