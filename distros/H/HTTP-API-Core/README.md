# HTTP::API::Core

A small, dependency-light foundation for building JSON HTTP API clients in Perl.

`HTTP::API::Core` sits above your HTTP transport and handles the application-level plumbing that API clients repeatedly need: JSON, query parameters, structured errors, safe retries, pagination, rate limits, authentication hooks, observability, idempotency, and transport adapters.

It does **not** replace `HTTP::Tiny`, LWP, Mojo::UserAgent, Furl, or another HTTP stack. Use the transport you prefer and keep the repetitive API-client policy in one place.

## Why HTTP::API::Core?

A small API wrapper often starts simple:

```perl
my $response = $http->get($url);
```

Then production requirements arrive:

* encode query parameters correctly
* send and decode JSON
* normalize HTTP and transport failures
* retry transient failures safely
* respect `Retry-After` and rate-limit metadata
* paginate through different API styles
* attach authentication consistently
* capture request IDs and timing
* add logging, metrics, or tracing hooks
* support idempotency for unsafe requests
* test application logic without coupling it to one HTTP library

`HTTP::API::Core` provides those pieces without becoming a service-specific SDK or a new HTTP stack.

You still write the small resource methods that make your client useful:

```perl
sub get_user {
    my ($self, $id) = @_;
    return $self->{api}->get("/users/$id")->json;
}
```

The core handles the policy around that request.

## Quick start

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

## What you get

* base URL handling
* default and per-request headers
* first-class query parameter encoding
* JSON request encoding and response decoding
* configurable timeouts
* structured transport, HTTP, encode, decode, and hook errors
* conservative retries with exponential backoff and jitter
* `Retry-After` and rate-limit-aware retry behavior
* next-URL, page-number, and cursor pagination
* lifecycle hooks at client and request scope
* Bearer, Basic, and API-key authentication helpers
* request ID and elapsed-time observability
* explicit response body and Content-Type helpers
* idempotency-key support
* coderef and object transport adapters

## Real API examples

Small, tested example clients show how the same core maps onto APIs with different conventions:

* `HTTP::API::Core::Example::GitHub` — page-number pagination over a top-level JSON array, plus GitHub rate-limit metadata
* `HTTP::API::Core::Example::Slack` — cursor pagination using `response_metadata.next_cursor`
* `HTTP::API::Core::Example::Cloudflare` — page-number pagination using `result_info.total_pages`

See `docs/REAL_API_EXAMPLES.md`.

These are integration recipes, not official SDKs for those services.

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

Values are percent-encoded. Array references generate repeated keys, undefined values are omitted, existing query strings are preserved, and parameters are inserted before URL fragments.

`before_request` hooks see the final encoded URL.

## Authentication

`HTTP::API::Core::Auth` provides small authentication helpers implemented as `before_request` hooks:

```perl
use HTTP::API::Core::Auth qw(
    bearer_auth
    basic_auth
    api_key_auth
);

my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.com',
    hooks => {
        before_request => bearer_auth($token),
    },
);
```

Supported helpers include:

* Bearer tokens
* HTTP Basic authentication
* API-key headers
* API-key query parameters

Explicit request headers take precedence over helper-provided values.

OAuth token acquisition and refresh flows deliberately remain outside the core.

See `docs/AUTHENTICATION.md`.

## Hooks

Client-level and per-request hooks let you add authentication, logging, metrics, tracing, or other cross-cutting behavior without subclassing.

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

`before_request` receives a mutable context containing `method`, `url`, `headers`, `content`, and the current retry `attempt`. It runs immediately before each transport attempt.

`after_response` runs after a successful response. `on_error` runs before retry handling decides whether another attempt should be made.

Each hook may be a coderef or an arrayref of coderefs. Request-local hooks are appended after client-level hooks.

Hook failures become structured, non-retryable `hook` errors.

## Observability

Responses expose transport elapsed time and common request IDs without forcing a logging, metrics, tracing, or telemetry framework:

```perl
my $response = $api->get('/users');

say $response->elapsed;
say $response->request_id if defined $response->request_id;
```

`request_id` recognizes:

* `X-Request-Id`
* `Request-Id`
* `X-Correlation-Id`

Lifecycle hooks receive the same per-attempt metadata through their context. `started_at` is captured immediately before transport begins, `elapsed` measures transport time, and `request_id` is populated before `after_response` or `on_error` runs.

HTTP and transport errors also expose elapsed time. HTTP errors retain the normalized request ID.

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

`HTTP::API::Core::RateLimit` understands numeric `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset` fields, as well as the widely used `X-RateLimit-*` family and `Retry-After`.

`X-RateLimit-Reset` is treated as a UTC epoch timestamp. `RateLimit-Reset` is treated as a delay in seconds.

HTTP errors expose the same object through `$error->rate_limit`.

For exhausted quotas, `Retry-After` is preferred. When it is absent, retry handling can fall back to reset metadata.

A `403` is treated as a rate-limit retry only when the response explicitly reports `remaining == 0`; ordinary authorization failures are not retried.

## Pagination

`paginate` returns an iterator with `next` and `all`. Different pagination styles use the same interface.

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

The default parameter names are `page` and `per_page`. Override them with `page_param` and `page_size_param`.

If the response exposes an explicit boolean, use:

```perl
has_more => 'meta.has_more'
```

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

Extractor values such as `data.users` and `meta.next_cursor` are dotted paths. A coderef may also be supplied when an API needs custom extraction logic.

Repeated next URLs or cursors are detected and rejected instead of looping forever.

## Response API

Response body handling is explicit and predictable:

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

`content_type` strips parameters such as `charset` and normalizes the media type to lowercase.

`is_json` recognizes `application/json` and structured syntax suffix media types such as `application/problem+json`.

Calling `json` is explicit and does not require a JSON Content-Type header. Empty or whitespace-only bodies return `undef`; invalid non-empty JSON raises a structured `decode` error.

`text` performs no charset decoding.

The `headers` method returns a copy so callers cannot accidentally mutate response state.

See `docs/RESPONSE.md`.

## Error model

Failures use `HTTP::API::Core::Error` with machine-readable categories:

* `encode`
* `decode`
* `transport`
* `http`
* `hook`

HTTP errors retain their response and expose `body`, `text`, `json`, `headers`, and `header` helpers.

Application code can inspect structured fields such as:

* `category`
* `status`
* `retryable`
* `request_id`

instead of parsing human-readable error messages.

See `docs/ERRORS.md`.

## Retry policy

Retries are intentionally conservative.

By default, only these methods are retried:

* `GET`
* `HEAD`
* `PUT`
* `DELETE`
* `OPTIONS`

`POST` and `PATCH` are not automatically repeated because doing so can duplicate side effects.

Retryable failures include:

* transport errors
* HTTP `408`
* HTTP `425`
* HTTP `429`
* HTTP `5xx`
* exhausted-quota `403` responses

Delays use exponential backoff with jitter.

A numeric `Retry-After` header takes precedence. Exhausted rate-limit reset metadata is used as a fallback.

Retries can be disabled per request:

```perl
$api->get('/status', retry => 0);
```

Unsafe methods may be opted in explicitly:

```perl
$api->post('/jobs',
    json => { task => 'sync' },
    retry => {
        attempts => 2,
        methods  => ['POST'],
    },
);
```

## Idempotency

Idempotency keys can be supplied without assuming a service-specific header name:

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

The core does not generate keys automatically.

Supplying an idempotency key also does not automatically make an unsafe method retryable. Retry behavior remains explicit.

An explicit request header with the same case-insensitive name takes precedence.

See `docs/IDEMPOTENCY.md`.

## Transport adapters

The `transport` constructor option is the supported extension point for integrating another HTTP implementation.

It accepts either a code reference or an object with a `request` method:

```perl
my $api = HTTP::API::Core->new(
    base_url  => 'https://api.example.com',
    transport => My::Transport->new(...),
);
```

Adapters receive:

```perl
($method, $url, \%options)
```

and return a hash containing at least:

```perl
status => 200
```

with optional `reason`, `headers`, and `content`.

Transport exceptions and malformed results become structured `transport` errors.

This keeps HTTP-library-specific integration outside the core.

See `docs/TRANSPORT.md`.

## Scope and project direction

`HTTP::API::Core` aims to stay:

* small
* predictable
* dependency-light
* transport-independent
* safe for production use

The following intentionally remain outside the core:

* service-specific SDK behavior
* complete OAuth acquisition and refresh flows
* OpenAPI generation
* GraphQL-specific clients
* WebSockets
* HTTP server functionality
* async runtime concerns

See `DESIGN.md` for the full project direction and criteria for 1.0.

## License

Same terms as Perl itself.
