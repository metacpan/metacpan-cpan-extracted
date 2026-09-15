# 🌍 JQ::Lite — Design

## Purpose

`JQ::Lite` is a **lightweight JSON query engine** designed to make structured data
easy to filter, transform, and reuse across diverse environments.

Its goal is simple:

> **Make JSON processing reliable, portable, and human-readable — everywhere.**

---

## 1. Why Lightweight Matters

JSON has become the universal format for:

- APIs and service integration
- Observability and telemetry
- Configuration and automation
- Machine-to-machine communication

However, many environments still face practical constraints:

- Limited or restricted runtime environments
- Legacy or long-lived systems
- Minimal base images and offline deployments

`JQ::Lite` is built to operate reliably under these constraints,
providing a **small, dependency-minimal JSON processor** that can be used
where heavier tools are unavailable or impractical.

---

## 2. A Common Interface for Structured Data

`JQ::Lite` treats JSON as a **first-class interface** between systems.

Key design principles:

- JSON-in / JSON-out processing
- Compatibility with UNIX pipelines
- Identical behavior as a **CLI tool** and as a **library**

This makes it suitable for workflows where structured data flows between
scripts, services, automation tools, and humans.

---

## 3. Design Philosophy

`JQ::Lite` follows a conservative and long-term design approach:

- Prefer **clarity over cleverness**
- Favor **portability over performance tricks**
- Avoid unnecessary dependencies
- Maintain predictable behavior across versions

The goal is not to chase trends, but to provide a **stable, dependable utility**
that continues to work across time and platforms.

---

## 4. Type Semantics and Numeric Coercion

`jq-lite` currently distinguishes JSON types using Perl scalar flags, so
`type()` reports `"number"` only for true numeric values (including scientific
notation) and reports `"string"` for numeric-looking strings.

Arithmetic operators, however, follow Perl-style numeric coercion and will
implicitly coerce numeric-looking strings into numbers (for example, `"1e3" + 1`
evaluates to `1001`). This means type classification and arithmetic behavior
are not strictly aligned today.

This behavior is an explicit design discussion item: we may keep the permissive
coercion for compatibility, or move toward stricter jq-style runtime errors for
string arithmetic in a future breaking change.

---

## 5. Open and Reproducible Workflows

Modern data pipelines often depend on proprietary platforms or tightly coupled
ecosystems.

`JQ::Lite` intentionally avoids this:

- Fully open source
- No vendor lock-in
- No cloud dependency
- Usable in restricted or offline environments

This allows users to build **reproducible, inspectable data transformations**
that can be versioned, audited, and shared.

---

## 6. Structured Data as Text

As infrastructure, observability, and automation increasingly rely on structured data,
text-based workflows remain essential.

`JQ::Lite` supports this by enabling:

- Text-based JSON transformations
- Git-friendly configuration and processing logic
- Simple integration with automation systems and scripts

This keeps data processing transparent, reviewable, and automatable.

---

## 7. Ecosystem Compatibility

`JQ::Lite` is designed to integrate naturally with other tools and workflows.

```text
JSON producer
    ↓
jq-lite (filter / transform)
    ↓
script / CLI / automation
```

The tool does not prescribe how data should be used —
it simply ensures that **extracting and shaping JSON remains easy and reliable**.

---

## Summary

| Aspect        | Focus                                             |
|---------------|---------------------------------------------------|
| Scope         | Lightweight JSON querying and transformation      |
| Philosophy    | Portability, clarity, long-term stability         |
| Usage         | CLI and library                                   |
| Environment  | Offline, restricted, legacy, and modern systems   |
| Longevity    | Designed to remain usable across platforms/years  |

---

## Conclusion

`JQ::Lite` aims to be a **small, dependable building block**
in the broader ecosystem of structured data processing.

By keeping JSON handling simple, portable, and transparent,
it helps ensure that data remains usable — regardless of environment or scale.

---

© 2025 Shingo Kawamura

## 8. Internal Query Architecture

Query execution has an explicit internal pipeline:

```text
source text
    ↓
JQ::Lite::Tokenizer
    ↓
JQ::Lite::Parser
    ↓
JQ::Lite::AST
    ↓
JQ::Lite::Evaluator
    ↓
JQ::Lite::Runtime
```

The tokenizer owns source boundaries and currently emits top-level filter,
pipe, and end-of-input tokens. Delimiters inside strings, arrays, objects, and
parenthesized expressions remain within a filter token. This narrow lexer
boundary allows syntax to move incrementally without changing 2.x behavior.

The parser validates and compatibility-normalizes those filter tokens and
builds a typed pipeline AST. The evaluator only walks AST nodes and controls
stream propagation. The runtime owns JSON decoding and dispatch to the
existing built-in and traversal implementations. This separation prevents
parsing decisions from being mixed into the top-level evaluation loop.

`JQ::Lite::Tokenizer`, `JQ::Lite::AST`, `JQ::Lite::Evaluator`, and
`JQ::Lite::Runtime` are implementation details. They are intentionally outside
the stable Library API and may evolve as more filter-local syntax is represented
by dedicated AST node types. `JQ::Lite->new` and `run_query` remain the public
entry points.

`JQ::Lite::Value` is the shared value-semantics layer for the 3.0 evaluator.
It classifies JSON values without conflating booleans, numbers, and strings,
and provides recursive jq-style equality and total ordering for compound
values. The stable 2.x filter implementation does not call this layer yet;
that separation prevents preparatory 3.0 work from changing 2.x results.

### Built-in registry

`JQ::Lite::Filters` owns language constructs such as expressions, control
flow, constructors, assignment, and traversal. Built-in filters are resolved
through `JQ::Lite::Builtin`, whose internal registry supports both exact names
and parameterized-call patterns. Implementations are grouped by responsibility
under `JQ::Lite::Builtin::{Array,Object,String,Math,Aggregate,Encoding,Type}`.
Category modules receive the evaluator owner and current input stream, so they
can preserve streaming and error behaviour without depending on the parser or
the top-level filter loop.

The registry and all category packages are internal implementation details,
like the tokenizer and evaluator layers. New built-ins should be registered in
the narrowest applicable category rather than adding another branch to
`JQ::Lite::Filters`.
