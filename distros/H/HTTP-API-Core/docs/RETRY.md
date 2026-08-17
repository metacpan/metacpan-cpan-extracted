# Retry policy

`HTTP::API::Core` retries conservatively. Retry behavior is part of the public API contract and is intentionally explicit so callers can reason about duplicate side effects and failure timing.

## Defaults

A client created without a `retry` option uses:

```perl
{
    attempts   => 3,
    base_delay => 0.25,
    max_delay  => 5,
    jitter     => 1,
    methods    => [qw(GET HEAD PUT DELETE OPTIONS)],
}
```

`attempts` counts the initial request. A value of `1` disables additional attempts.

Unsafe methods are not retried by default. `POST` and `PATCH` must be opted in explicitly with `methods` when a caller knows repeating the request is safe.

Method names supplied in `methods` are normalized to upper case.

## Retryable failures

Transport failures are retryable.

HTTP responses are retryable for status codes:

- `408 Request Timeout`
- `425 Too Early`
- `429 Too Many Requests`
- all `5xx` responses

A `403` is retryable only when normalized rate-limit metadata reports an exhausted quota (`remaining <= 0`). Ordinary authorization failures are not retried.

A retryable error is only retried when the request method is allowed by the active retry policy.

## Delays

The delay before another attempt is chosen in this order:

1. numeric `Retry-After`
2. exhausted rate-limit reset metadata
3. exponential backoff

Exponential backoff starts at `base_delay`, doubles after each failed attempt, and is capped at `max_delay`.

When `jitter` is enabled, the backoff delay is randomized between zero and the calculated delay. Jitter is enabled by default.

## Per-request overrides

Use `retry => 0` to force a single attempt for one request:

```perl
$api->get('/status', retry => 0);
```

A hash reference replaces the retry policy for that request:

```perl
$api->post('/jobs',
    json => { task => 'sync' },
    retry => {
        attempts   => 2,
        methods    => ['POST'],
        base_delay => 0.1,
        max_delay  => 1,
        jitter     => 0,
    },
);
```

`retry => 1` uses the client-level policy.

## Validation

`attempts` must be a positive integer. `base_delay` and `max_delay` must be non-negative numbers. `methods` must be an array reference and may not contain empty values. Unknown retry options are rejected.

The `retry` accessor returns a defensive copy of the normalized policy so callers cannot mutate client state accidentally.
