# Production release audit (2026-07-18)

Last verified against main: 2026-07-19 (`c84c477`).

## Decision

The current tree has complete query/mutation validation against the September
2025 stable specification, including executable documents and type-system
schemas. Subscription execution is intentionally unsupported. It should not
yet be presented as ready for an untrusted, high-traffic public GraphQL
endpoint until production-shaped deployment qualification is complete.

## Verified baseline

- The complete local suite passes on Perl 5.44 / macOS arm64: 49 files and
  469 tests.
- The normal CI matrix covers Perl 5.24 through 5.44 on Linux.
- Robustness CI includes ASan with hash-seed sweeping, parser fuzzing, an RSS
  soak gate, full-suite Valgrind, compiler warnings, and XS ownership linting.
- Request errors, result coercion, Non-Null propagation, parser nesting and
  token limits, request-body limits, and alias/node limits are implemented.
- SDL type-system extensions are merged before schema construction, including
  interface inheritance and extension-specific duplicate checks.
- Federation 2 subgraph schemas, default-resolver method/coderef compatibility,
  and an opt-in introspection access policy are covered by regression tests.
- POD syntax and META.json validation pass locally.
- The execution checkpoint remains within its documented performance range:
  variable-bearing programs about 201k/s, dynamic direct JSON about 359k/s,
  fixed bundles about 650k-720k/s, and fixed-bundle direct JSON about 955k/s
  (three-sample medians/ranges on the development macOS arm64 host).

## Release blockers

### P0-1: complete executable document validation (completed)

The initial audit found that the following invalid documents were accepted.
They are now rejected by XS validation and retained as regression coverage:

```graphql
{ user }
query Q($x: Int, $x: Int) { hello(x: $x) }
{ hello(x: 1, x: 2) }
fragment F on Query { hello }
query Q { hello }
query Q($x: Int) { hello }
```

The completed work covers:

- leaf fields must not have selection sets and composite fields must have one;
- unique variable, argument, and fragment names;
- no unused variables and fragments;
- variables in allowed positions for ordinary field arguments as well as
  directives;
- values of correct type;
- overlapping fields can be merged;
- fragment and subscription-root edge cases.

The canonical AST stores arguments, variable definitions, and input object
fields in hashes. Validation-only parser diagnostics preserve duplicates
before overwrite without changing the public AST.

Implementation progress:

- completed: unique fragment names;
- completed: leaf field selections / composite field subselections;
- completed: no unused variables, including variables used through fragments;
- completed: no unused fragments, using transitive operation reachability;
- completed: duplicate argument/variable detection through a validation-only
  parser error sink, without changing the public canonical AST;
- completed: duplicate input object fields use the same validation-only parser
  diagnostics before the canonical hash representation overwrites them;
- completed: unused variable/fragment graph traversal moved from Pure Perl to
  XS; cached documents still bypass validation entirely;
- performance check: the existing kitchen-sink parser benchmark measured
  about 67k parses/s with locations and 84k parses/s without locations on the
  development macOS arm64 host after these changes;
- completed: variables in allowed positions for direct arguments, list items,
  and input object fields, including default-value exceptions, in XS;
- completed: built-in scalar literal validation uses SV flags directly in
  XS, avoiding a Perl method call per literal;
- completed: Enum literal shape and membership validation uses direct XS hash
  lookup against the compiled enum descriptor;
- completed: variable default values are checked against their declared input
  types using the XS literal validator;
- completed: executable directive validation now performs definition lookup,
  location/repeatability checks, argument validation, and selection traversal
  in XS; the validation facade no longer performs a second Pure Perl AST walk;
- completed: directive literals retain directive-specific errors, custom scalar
  callbacks use the compiled CV fallback, and fragment variable positions are
  validated in each operation context;
- completed: executable grammar and XS validation support directives on
  variable definitions, including constant directive arguments;
- completed: field merging conflicts are grouped by response key, expanded
  through named and inline fragments, and compared only across overlapping
  runtime type conditions in XS;
- performance: identical fields in a response-key bucket collapse to one
  representative per type condition, and comparison stops after the first
  conflict for that key, preventing quadratic same-key duplicate floods;
- completed: field response shape validation compares Non-Null/List wrappers
  and leaf type identity in XS, including mutually-exclusive type conditions;
- completed: compatible composite fields recursively validate their combined
  subfield selections in XS rather than validating each occurrence in isolation;
- performance: composite occurrences retain a linear merge list while semantic
  duplicates share one comparison representative, avoiding pairwise recursion;
- completed: executable definitions, literal container shapes, explicit null
  for Non-Null positions, subscription response-name grouping, and the ban on
  subscription introspection root fields;
- completed: `docs/validation-conformance.md` maps every stable September 2025
  executable-document rule to its primary regression coverage.

### P0-2: cost control beyond AST node count (completed)

`max_depth` and `max_nodes` defend against nesting and alias flooding. Native
runtimes now also enforce an XS weighted-cost walk with per-field `cost`,
per-list `list_size`, a configurable default list multiplier, early budget
termination, and cache-limit signatures. Resolver-side pagination limits are
still required because list size is a schema estimate rather than a runtime
row counter.

### P0-3: complete the query/mutation conformance profile (completed)

Section 3 schema-validation gaps and September 2025 executable descriptions
are implemented. Subscription execution is intentionally outside the 0.01
profile; ordinary, persisted, and PSGI execution paths reject subscription
operations instead of treating them as one-shot queries.

### P0-4: production-shaped load qualification

Run a prefork PSGI server with a real database pool and request-scoped
DataLoaders. Record cache-hit/miss mixtures, p50/p95/p99 latency, RSS and CPU
under concurrent load, slow/erroring resolvers, graceful restart, and a long
soak. Existing microbenchmarks establish excellent engine throughput but do
not yet constitute capacity planning for a deployed service.

## Release preparation

- `Changes` records the implemented 0.01 feature and hardening history.
- Older status documents are retained as explicitly marked historical records;
  this audit and the specification-conformance tables are authoritative.
- The production deployment guide covers prefork operation, timeouts,
  pagination/cost policy, rate limiting, logging, GraphiQL/CSP, and shutdown.
- State unsupported features prominently: ithreads, GET query execution,
  subscriptions, defer/stream, a Federation Gateway/Router, generic
  promise adapters, and variables with fixed bundles.
- Perl 5.44 and distribution/POD/minimum-version tests run in CI using the
  Docker Official Image for Perl. A native macOS job remains to be added.
- Consider GET query execution and stricter GraphQL-over-HTTP content
  negotiation for broad client and CDN compatibility.

## Recommended order

1. Qualify a realistic PSGI + database deployment under concurrent load.
2. Add a native macOS CI job and run the release candidate through the full
   distribution and robustness workflows.
3. Recheck Changes, the public POD, the migration/deployment guides, and the
   conformance tables before publishing 0.01 to CPAN.
