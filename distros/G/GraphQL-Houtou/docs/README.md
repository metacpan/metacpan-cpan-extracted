# Documentation guide

The documentation in this directory describes the current implementation and
release profile. Completed plans, temporary handover notes, debugging diaries,
and superseded architecture proposals are kept in Git history instead of the
main branch.

## Users and operators

- [`production-deployment.md`](production-deployment.md) — prefork PSGI
  deployment, limits, timeouts, logging, shutdown, and public-endpoint policy.
- [`persisted-queries.md`](persisted-queries.md) — compiled programs and fixed
  bundles.
- [`migrating-from-graphql-perl.md`](migrating-from-graphql-perl.md) —
  schema-first and code-first migration, execution API changes, default
  resolution, async behavior, and staged rollout.
- [`federation.md`](federation.md) — Federation 2 subgraph support and its
  trust boundary.
- [`execution-benchmark.md`](execution-benchmark.md) — reproducible execution
  benchmark methodology and comparison rules.

The main module POD and generated `README.md` remain the primary public API
reference.

## Specification and release readiness

- [`spec-conformance-september-2025.md`](spec-conformance-september-2025.md) —
  supported GraphQL specification profile.
- [`validation-conformance.md`](validation-conformance.md) — executable
  validation rules mapped to regression tests.
- [`production-release-audit-2026-07-18.md`](production-release-audit-2026-07-18.md)
  — current first-release decision and remaining production qualification.

## Maintainers

- [`architecture-overview.md`](architecture-overview.md) — current compile and
  request data flow.
- [`module-map.md`](module-map.md) — ownership and responsibility by module.
- [`vm-internals-ja.md`](vm-internals-ja.md) — VM opcodes, frames, values, and
  execution lanes.
- [`parser-internals.md`](parser-internals.md) — tokenizer/parser ownership and
  AST construction.
- [`evolution-and-performance.md`](evolution-and-performance.md) — rationale
  behind the current native architecture and major optimizations.
- [`memory-leak-check.md`](memory-leak-check.md) — ASan, Valgrind, frame-counter,
  and RSS-soak workflow.
- [`xs-coding-rules.md`](xs-coding-rules.md) — XS/C ownership and error-handling
  rules.

When implementation or release state changes, update the relevant current
document rather than adding another dated plan or status snapshot.
