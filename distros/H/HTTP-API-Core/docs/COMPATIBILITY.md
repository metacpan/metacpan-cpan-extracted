# HTTP::API::Core compatibility policy

This document defines the compatibility promises for `HTTP::API::Core` starting
with version 1.00.

## 1.x compatibility promise

The following documented interfaces are public and should remain backward
compatible throughout the 1.x series:

- the `HTTP::API::Core` constructor and its documented options
- `request`, `get`, `post`, `put`, `patch`, and `delete`
- `paginate` and the pagination iterator's `next` and `all` methods
- response status, headers, body, JSON, content-type, request-ID, elapsed-time,
  and rate-limit accessors
- structured error categories and documented error accessors
- retry policy configuration and safe-method defaults
- lifecycle hook names and callback contracts
- query parameter handling
- authentication helper functions
- idempotency request configuration
- the documented transport adapter contract

A compatible 1.x release may add constructor options, methods, response fields,
error metadata, authentication helpers, or other opt-in capabilities. It should
not remove or rename documented interfaces, change documented return types, or
silently change default request semantics.

## Pre-1.0 history

The initial `HTTP::API::Core` 0.01 release carried forward the implementation
and regression coverage developed through the pre-rename
`HTTP::API::Client` 0.12 series. Before 1.00, public interfaces were allowed to
be refined deliberately while the compatibility contracts were stabilized.
The namespace rename itself is documented in `MIGRATION_FROM_HTTP_API_CLIENT.md`.

## What is not covered

The following are not compatibility promises unless explicitly documented as
public API:

- private functions whose names begin with `_`
- object hash layout and other implementation details
- exact human-readable error-message wording
- undocumented fields in hook context hashes or transport internals
- ordering of hash keys
- behavior that depends on an external HTTP service or transport implementation

Applications should use documented methods and structured fields instead of
relying on internal representation.

## Deprecation policy

When a 1.x public interface needs to change, prefer this sequence where
practical:

1. introduce the replacement without removing the old interface;
2. document the old interface as deprecated;
3. keep regression coverage for both during the deprecation window;
4. remove the deprecated interface only in a future major release.

Security or correctness issues may require a faster change. Such exceptions
should be documented prominently in `Changes` with migration guidance.

## Regression coverage

`t/public-api.t` acts as a small compatibility guard for the documented public
surface. Feature-specific tests remain the source of truth for detailed
semantics such as retries, pagination, hooks, rate limits, response decoding,
and transport behavior.
