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

If a `before_request` hook changes the HTTP method, the modified method is normalized to uppercase before transport and retry decisions. The **method actually sent** must also be allowed by the retry policy. For example, changing an initial `GET` to `POST` (or `post`) does not opt `POST` into retries. To deliberately retry a hook-mutated `POST`, configure `methods` to include both `GET` and `POST`. An `on_error` hook cannot change the retry eligibility of a method that has already been sent.

## Delays

The delay before another attempt is chosen in this order:

1. `Retry-After` (delay-seconds or HTTP-date)
2. exhausted rate-limit reset metadata
3. exponential backoff

Numeric `Retry-After` values and the date/time components of IMF-fixdate values must use ASCII digits (`0`–`9`). Other Unicode digit characters are malformed, not zero-second delays, so retry delay selection falls back to rate-limit reset or backoff.

HTTP-date values use the IMF-fixdate form (for example, `Wed, 21 Oct 2015 07:28:00 GMT`). The weekday must match the calendar date, and the converted UTC year must match the literal four-digit year in the header; a mismatch makes the header invalid. This also avoids treating historical years as future dates due to `Time::Local` year interpretation. Valid dates in the past produce a zero-second delay. Malformed values are ignored so the existing rate-limit reset or exponential-backoff fallback can be used.

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

`attempts` must be a defined positive integer; an explicit `undef`, zero, or non-integer value is rejected before a request is sent and without Perl uninitialized-value warnings. `base_delay` and `max_delay` must be non-negative numbers. All retry numeric options require ASCII digits (`0`–`9`); Unicode digit characters are rejected before numerical coercion, avoiding surprising zero-delay behavior and warnings. `methods` must be an array reference and may not contain empty values. Unknown retry options are rejected.

The `retry` accessor returns a defensive copy of the normalized policy so callers cannot mutate client state accidentally.
