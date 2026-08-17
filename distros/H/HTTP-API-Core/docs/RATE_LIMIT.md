# Rate-limit contract

`HTTP::API::Core::RateLimit` provides normalized, transport-independent rate-limit metadata for responses and HTTP errors.

This document describes behavior intended to remain compatible across the 1.x series.

## Supported header families

`from_headers()` recognizes header names case-insensitively from these families:

- `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Used`, `RateLimit-Reset`, `RateLimit-Resource`
- `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Used`, `X-RateLimit-Reset`, `X-RateLimit-Resource`
- `Retry-After`

When both standard-style and `X-RateLimit-*` quota fields are present, the standard-style field wins for the normalized value.

`RateLimit-Reset` is interpreted as a relative delay in seconds. `X-RateLimit-Reset` is interpreted as an epoch timestamp.

## Numeric parsing

Only non-negative decimal numeric header values are normalized as numbers. Missing or invalid numeric values become `undef` rather than raising an exception.

## Accessors

The public metadata accessors are:

- `limit`
- `remaining`
- `used`
- `reset`
- `reset_epoch`
- `retry_after`
- `resource`
- `source`

`source` is `ratelimit` when any standard-style limit/remaining/reset header is present, `x-ratelimit` when only the legacy family is present, and `undef` when neither family is detected.

`as_hash()` returns a new hash reference containing all public metadata fields.

## Exhaustion

`exhausted()` is true only when `remaining` is present and numerically less than or equal to zero. Missing `remaining` metadata does not imply exhaustion.

## Retry delay

`wait_seconds()` chooses the first available delay in this order:

1. `Retry-After`
2. `RateLimit-Reset`
3. `X-RateLimit-Reset` converted from epoch time

Epoch-based waits are clamped to zero when the reset time is already in the past. When no supported delay metadata is available, `wait_seconds()` returns `undef`.

For deterministic callers and tests, `wait_seconds(now => $epoch)` may provide the current epoch explicitly.

## Response and error integration

`HTTP::API::Core::Response->rate_limit` exposes normalized metadata parsed from response headers. HTTP errors expose the same metadata through `HTTP::API::Core::Error->rate_limit` when a response is available.

An exhausted `403` response is treated as retryable by the core. `429` remains retryable as an HTTP status regardless of whether quota metadata is present.
