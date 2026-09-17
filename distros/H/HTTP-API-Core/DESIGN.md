# HTTP::API::Core — Project Direction

This document defines the design direction for `HTTP::API::Core`.

Now that the public API has reached 1.0, new features and changes should be evaluated against these principles so that the distribution remains small, predictable, compatible, and useful as a long-lived foundation for Perl API clients.

## Goal

> **HTTP::API::Core is a small, dependency-light foundation for building production-quality HTTP API clients in Perl.**

The module does **not** aim to replace `HTTP::Tiny`, LWP, Mojo, Furl, or other HTTP transports.

Its job is to provide the reusable layer that API client authors repeatedly need on top of HTTP transport.

A typical architecture looks like:

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
      +-- idempotency
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

Keep the core focused.

A feature belongs in the core when it is broadly useful to HTTP API clients rather than specific to one service or protocol.

Prefer a small composable primitive over a large framework abstraction.

### Boring

Predictable behavior is a feature.

Prefer conventional HTTP semantics and explicit configuration over surprising magic.

Do not automatically perform actions that can change application semantics. For example, unsafe methods must not be retried by default.

### Dependency-light

Avoid dependencies unless they provide substantial value that would be unreasonable or risky to implement locally.

The distribution should remain practical in conservative Perl environments and existing production systems.

### Transport-independent

`HTTP::API::Core` is an API-client layer, not an HTTP stack.

The transport boundary should remain replaceable so callers can use transports such as `HTTP::Tiny`, LWP, Mojo::UserAgent, Furl, or a test transport without rewriting API-specific code.

### Production-oriented

Features should account for real operational failure modes:

* timeouts
* transient transport failures
* safe retries
* exponential backoff and jitter
* rate limits
* pagination
* structured errors
* request IDs and tracing
* observability

Convenience must not come at the expense of safe failure behavior.

### Testable

Network behavior should be testable without real network access.

Policies such as retry, pagination, rate-limit handling, authentication, idempotency, and hooks should have deterministic regression tests.

### Stable

The 1.x public API is intended to remain compatible across minor releases.

Downstream API clients should not need to be rewritten simply because `HTTP::API::Core` receives new features or internal improvements.

Public behavior should be explicitly documented and protected by regression tests.

Internal implementation details remain free to evolve as long as documented public behavior is preserved.

## Scope

The core covers reusable API-client infrastructure such as:

* base URLs and request construction
* headers and query parameters
* JSON request/response handling
* timeout configuration
* structured responses and errors
* retry/backoff/jitter policy
* rate-limit metadata and retry integration
* pagination
* lifecycle hooks
* common authentication helpers
* request/response observability
* idempotency support
* a documented transport adapter contract

This list describes the intended responsibility of the core, not a requirement that every possible variation of these features must be implemented.

## Non-goals

The core should **not** become an all-purpose networking framework.

The following are intentionally outside the core unless the project's direction is explicitly reconsidered:

* OpenAPI code generation
* GraphQL-specific clients
* complete OAuth flows or token servers
* WebSocket support
* HTTP server functionality
* an async runtime or framework
* service-specific SDK behavior

These may be implemented by separate distributions built on top of `HTTP::API::Core` where appropriate.

## What 1.0 established

The 1.0 release established the main API-client foundation and the public interfaces that future 1.x releases should preserve.

The foundation includes:

* HTTP request handling
* JSON request and response handling
* timeout configuration
* structured errors
* retry policy
* exponential backoff and jitter
* pagination
* normalized rate-limit handling
* lifecycle hooks
* first-class query parameters
* common authentication helpers
* request timing and request-ID observability
* explicit response-body helpers
* idempotency support
* a supported transport adapter contract

These capabilities form the stable baseline of the project.

Future development should improve and extend this foundation without unnecessarily expanding the role of the core.

## Compatibility policy

Within the 1.x series, documented public APIs should remain backward compatible whenever reasonably possible.

This includes:

* constructor behavior
* `request()` and convenience methods
* response API
* error API and error categories
* retry configuration and behavior
* pagination interfaces
* lifecycle hooks
* query parameter handling
* rate-limit API
* authentication helpers
* idempotency behavior
* transport adapter contract

Changes to undocumented implementation details do not require compatibility guarantees.

If a public interface must change incompatibly, the change should be deliberate, documented, and reserved for an appropriate major release.

Bug fixes may change behavior when the previous behavior was clearly incorrect, unsafe, or inconsistent with documented semantics. Such changes should include regression tests and release notes.

## Development direction

Post-1.0 development should prioritize refinement over feature count.

Good candidates include:

* improving diagnostics and error context
* supporting additional broadly applicable HTTP API patterns
* improving interoperability with alternate transports
* strengthening tests around edge cases
* improving documentation and examples
* reducing unnecessary complexity
* making existing behavior more consistent and predictable

New features should not be added merely because they are convenient for one service.

Where possible, service-specific or protocol-specific behavior should live in modules built on top of `HTTP::API::Core`.

## Feature decision test

Before adding a feature to the core, ask:

1. Is this needed by many unrelated HTTP APIs?
2. Does centralizing it remove repetitive or error-prone client code?
3. Can its behavior be made predictable and testable?
4. Can it remain transport-independent?
5. Can we reasonably support this API for years?
6. Can it be added without unnecessarily breaking existing users?
7. Does it preserve the project's small, boring, dependency-light character?

If several answers are no, the feature probably belongs in an extension or service-specific client instead of the core.

## Changes to existing APIs

Because the project is now past 1.0, changing an existing public API should face a higher bar than adding an internal implementation improvement.

Before changing public behavior, consider:

* whether the problem can be solved without breaking compatibility
* whether a new optional capability can coexist with the existing API
* whether the existing behavior is documented
* whether downstream code is likely to depend on it
* whether the benefit justifies the compatibility cost
* whether the change belongs in a future major version instead

Backward compatibility is part of the value of the core.

## North star

The goal is not to have the most features.

The goal is for a Perl developer to be able to write:

```perl
use HTTP::API::Core;
```

and have a dependable foundation for API integration that remains understandable, maintainable, predictable, and compatible years later.
