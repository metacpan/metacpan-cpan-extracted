# Authentication helpers

`HTTP::API::Core::Auth` provides small `before_request` hook helpers for authentication schemes commonly used by HTTP APIs. The helpers deliberately build on the lifecycle-hook mechanism instead of adding service-specific authentication state to the client core.

This document describes the authentication behavior that is treated as part of the public compatibility contract on the path to 1.0.

## Public helpers

The module exports helpers only on request:

```perl
use HTTP::API::Core::Auth qw(
    bearer_auth
    basic_auth
    api_key_auth
);
```

Each helper returns a `before_request` callback suitable for `HTTP::API::Core`'s `hooks` option.

## Bearer authentication

```perl
hooks => {
    before_request => bearer_auth($token),
}
```

`bearer_auth($token)` requires a defined, non-reference, non-empty scalar. The callback adds:

```text
Authorization: Bearer <token>
```

Authorization header matching is case-insensitive. If the request already has any `Authorization` header spelling, the helper leaves it unchanged.

## HTTP Basic authentication

```perl
hooks => {
    before_request => basic_auth($username, $password),
}
```

Both username and password must be defined scalar values. Empty strings are allowed. The callback encodes `username:password` with standard Base64 encoding and adds a `Basic` Authorization header.

As with Bearer authentication, an existing Authorization header wins and is not overwritten.

## API keys

Header form:

```perl
api_key_auth(
    name  => 'X-API-Key',
    value => $key,
)
```

`in` defaults to `header`. Header keys use the same case-insensitive "do not overwrite an existing value" rule as Authorization headers.

Query form:

```perl
api_key_auth(
    in    => 'query',
    name  => 'api_key',
    value => $key,
)
```

The key name must be a defined, non-reference, non-empty scalar. The value must be a defined scalar and may be an empty string.

Query API keys are appended to the request URL after ordinary request query parameters have been encoded. Both the key name and value are percent-encoded as UTF-8 bytes using unreserved URI characters unchanged.

If the exact query parameter name is already present in the URL, the helper leaves the URL unchanged instead of adding a second credential.

## Composition and precedence

Authentication helpers are ordinary `before_request` hooks. This has two important compatibility consequences:

1. normal client-level and per-request hook ordering still applies;
2. explicit request credentials can take precedence because the built-in helpers do not overwrite an existing matching header or query parameter.

Applications that need token refresh or dynamic credential lookup may write their own hook or return a new helper callback when credentials change.

## Validation

Invalid helper configuration fails immediately when the helper is constructed. Unknown `api_key_auth` options are rejected instead of silently ignored.

## Scope

These helpers intentionally cover only reusable credential attachment:

- Bearer tokens
- HTTP Basic credentials
- API keys in headers
- API keys in query strings

OAuth authorization flows, token acquisition, refresh orchestration, signing schemes, cookies, credential storage, and service-specific authentication remain outside the core.
