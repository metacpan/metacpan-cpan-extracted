# Idempotency support

`HTTP::API::Core` supports API-specific idempotency keys without assuming that every API uses the same header name.

```perl
my $response = $api->post(
    '/payments',
    json => { amount => 1000 },
    idempotency => {
        key    => $request_key,
        header => 'Idempotency-Key',
    },
);
```

The option is intentionally explicit:

- `key` is the idempotency value.
- `header` is the exact API-specific header name.
- both must be non-empty scalar values.
- an explicitly supplied request header with the same case-insensitive name takes precedence.

The client does not generate keys automatically and does not make `POST` retryable merely because an idempotency key is present. Retry policy remains an explicit, separate concern.

This keeps the core service-neutral: APIs using `Idempotency-Key`, `X-Idempotency-Key`, or another convention can all use the same mechanism.
