# HTTP::API::Core — Project Direction

This document defines the design direction for `HTTP::API::Core`. New features should be evaluated against these principles so that the distribution stays small, predictable, and useful as a long-lived foundation for Perl API clients.

## Goal

> **HTTP::API::Core is a small, dependency-light foundation for building production-quality HTTP API clients in Perl.**

The module does **not** aim to replace `HTTP::Tiny`, LWP, Mojo, Furl, or other HTTP transports. Its job is to provide the reusable layer that API client authors repeatedly need on top of HTTP transport.

A typical architecture should look like:

```text
My::GitHub
My::Stripe
My::InternalAPI
      |
      v
HTTP::API::Core
      |
      +-- JSON handling
      +-- query parameters
      +-- structured errors
      +-- retries / backoff / jitter
      +-- rate-limit handling
      +-- pagination
      +-- lifecycle hooks
      +-- authentication helpers
      +-- observability
      |
      v
HTTP transport
```

The desired developer experience is that an API-specific client contains mostly API-specific behavior:

```perl
package My::API;

use parent 'HTTP::API::Core';

sub users {
    my ($self) = @_;

    return $self->get(
        '/users',
        query => { active => 1 },
    );
}
```

Retry policy, JSON handling, pagination, rate limits, errors, and similar infrastructure should not have to be rewritten by every API client.

## Design principles

### Small

Keep the core focused. A feature belongs in the core when it is broadly useful to HTTP API clients rather than specific to one service or protocol.

Prefer a small composable primitive over a large framework abstraction.

### Boring

Predictable behavior is a feature. Prefer conventional HTTP semantics and explicit configuration over surprising magic.

Do not automatically perform actions that can change application semantics. For example, unsafe methods must not be retried by default.

### Dependency-light

Avoid dependencies unless they provide substantial value that would be unreasonable or risky to implement locally.

The distribution should remain practical in conservative Perl environments and existing production systems.

### Transport-independent

`HTTP::API::Core` is an API-client layer, not an HTTP stack.

The transport boundary should remain replaceable so callers can eventually use transports such as `HTTP::Tiny`, LWP, Mojo::UserAgent, Furl, or a test transport without rewriting API-specific code.

### Production-oriented

Features should account for real operational failure modes:

- timeouts
- transient transport failures
- safe retries
- exponential backoff and jitter
- rate limits
- pagination
- structured errors
- request IDs and tracing
- observability

Convenience must not come at the expense of safe failure behavior.

### Testable

Network behavior should be testable without real network access. Policies such as retry, pagination, rate-limit handling, authentication, and hooks should have deterministic regression tests.

### Stable

Once the public API reaches 1.0, downstream API clients should be able to depend on it without being rewritten for minor releases.

Public behavior must be explicitly documented and protected by regression tests. Internal implementation details remain free to evolve.

## Scope

The core is intended to cover reusable API-client infrastructure such as:

- base URLs and request construction
- headers and query parameters
- JSON request/response handling
- timeout configuration
- structured responses and errors
- retry/backoff/jitter policy
- rate-limit metadata and retry integration
- pagination
- lifecycle hooks
- common authentication helpers
- request/response observability
- idempotency support
- a documented transport adapter contract

## Non-goals

The core should **not** become an all-purpose networking framework.

The following are intentionally outside the core unless the project's direction is explicitly reconsidered:

- OpenAPI code generation
- GraphQL-specific clients
- complete OAuth flows or token servers
- WebSocket support
- HTTP server functionality
- an async runtime/framework
- service-specific SDK behavior

These may be implemented by separate distributions built on top of `HTTP::API::Core` where appropriate.

## Roadmap

The roadmap is directional rather than a promise that every version number must contain exactly the listed feature.

### Foundation

- **0.01** — HTTP, JSON, timeout, structured errors
- **0.02** — retry, exponential backoff, jitter
- **0.03** — pagination
- **0.04** — normalized rate-limit handling
- **0.05** — lifecycle hooks
- **0.06** — first-class query parameters

### Toward a complete API-client foundation

- **0.07** — common authentication helpers
  - Bearer token
  - Basic authentication
  - API-key header
  - API-key query parameter
  - OAuth token acquisition/refresh remains out of scope

- **0.08** — observability
  - elapsed request time
  - request IDs
  - useful request context for logging/metrics/tracing

- **0.09** — response ergonomics
  - clearly documented `json`, `text`, `content`, headers, and status behavior
  - defined behavior for empty bodies and content types

- **0.10** — error model stabilization
  - stable error categories
  - response/body access from HTTP errors
  - compatibility tests for machine-readable behavior

- **0.11** — idempotency support
  - reusable support for APIs that accept idempotency keys
  - no service-specific header assumptions in the core

- **0.12** — transport adapter contract
  - document the transport interface as a supported extension point
  - make alternate transports possible without changing API-specific clients

## Criteria for 1.0

Version 1.0 should be based on API maturity, not feature count.

Before 1.0, the following interfaces should be sufficiently mature that we are willing to preserve them across the 1.x series:

- constructor contract
- `request()` and convenience methods
- response API
- error API and categories
- retry policy
- pagination
- lifecycle hooks
- query parameters
- rate-limit API
- authentication configuration
- transport adapter contract

The project should also have a written public API compatibility policy and regression tests for the promised behavior.

## Feature decision test

Before adding a feature to the core, ask:

1. Is this needed by many unrelated HTTP APIs?
2. Does centralizing it remove repetitive or error-prone client code?
3. Can its behavior be made predictable and testable?
4. Can it remain transport-independent?
5. Can we reasonably support this API for years?
6. Does it preserve the project's small, boring, dependency-light character?

If several answers are no, the feature probably belongs in an extension or service-specific client instead of the core.

## North star

The goal is not to have the most features.

The goal is for a Perl developer to be able to write:

```perl
use HTTP::API::Core;
```

and have a dependable foundation for API integration that remains understandable, maintainable, and compatible years later.
