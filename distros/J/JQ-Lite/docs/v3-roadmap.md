# JQ::Lite 3.0 roadmap

## Purpose

JQ::Lite 3.0 is the compatibility boundary for correcting selected runtime
semantics that cannot change safely in the stable 2.x series. Its goal is not
to implement every jq feature. It is to make the supported language more
predictable, move deliberately toward jq 1.7 where that benefits portable
filters, and preserve the lightweight, pure-Perl deployment model.

The current behaviour and the decision status of every known difference are
recorded in the [2.x semantic differences inventory](jq-semantics-differences.md).
That inventory is the source of truth for scope: this roadmap does not silently
turn an `undecided` item into a commitment.

## Compatibility policy

- The 2.x CLI and Library API contracts remain unchanged. Semantic corrections
  listed here are 3.0 changes and must not be backported to 2.x.
- The documented public Library API (`new` and `run_query`) remains supported.
  Version 3 changes query-language semantics, not the shape of those entry
  points.
- jq 1.7 is the comparison baseline for changes marked **change in v3**.
  Exact jq diagnostic text and unsupported jq facilities are not compatibility
  promises.
- Existing JQ::Lite extensions remain available unless a separate proposal
  documents their replacement and migration path.
- Every intentional incompatibility requires focused tests for both the new
  result and the migration guidance described below.

## Committed semantic changes

The following inventory items are approved for the 3.0 compatibility break.
They should be implemented as independently reviewable changes rather than as
one parser rewrite.

### Containment

- Make `contains(value)` use jq-style recursive containment for arrays and
  objects.
- Keep 2.x `contains_subset(value)` unchanged until its **undecided** status is
  resolved. It must not be presented as an exact alias for the new `contains`.

### Null, fallback, and paths

- Treat both `false` and `null` as absent for the `//` alternative operator.
- Emit `null` for a missing object field and for continued traversal through a
  missing field.
- Reject a numeric index applied to an object instead of returning `null`.

The error policy for other invalid paths remains undecided and is not implied
by these changes.

### Arithmetic and comparison

- Reject boolean operands in arithmetic expressions.
- Keep JSON scalar types distinct for equality, so a numeric-looking string is
  not equal to a number.
- Compare arrays lexicographically using jq-compatible value ordering.

Numeric-string arithmetic and regex scalar coercion remain undecided. Their
current behaviour must not change as a side effect of the committed work.

### Assignment and update

- Make update assignment (`|=`) emit the updated root value.
- Allow update assignment to create a missing target using the same input
  semantics as jq.

Multi-result assignment remains undecided and requires a separate design.

## Explicitly preserved scope

The following choices continue in 3.0 unless separately reconsidered:

- vectorised `floor`, `ceil`, `round`, `fromjson`, and related lossless helpers;
- array path projection;
- JQ::Lite convenience and statistical functions;
- truncating jagged `transpose` behaviour;
- the absence of modules/imports and jq's streaming parser mode; and
- the pure-Perl implementation and Perl 5.14 minimum.

Iterator suffixes, plain assignment, cross-type ordering, and missing-value
comparison already match the audited jq cases and are regression guards, not
3.0 work items.

## Undecided items and decision gates

An undecided behaviour may enter 3.0 only after a focused proposal includes:

1. examples of jq 1.7 and JQ::Lite 2.x behaviour;
2. known compatibility impact on existing filters;
3. the proposed result and error policy;
4. migration guidance; and
5. dependency-free regression tests.

This gate applies to numeric-string arithmetic, regex scalar coercion, invalid
path errors, mixed iterator pipelines, multi-result assignment, unsupported
parser syntax, control flow, and the future role of `contains_subset`.
Unresolved items retain their 2.x behaviour in 3.0.

## Delivery sequence

1. **Freeze the baseline.** Keep the 2.x inventory and regression tests intact.
2. **Build shared semantics.** Use the internal `JQ::Lite::Value` type and
   comparison primitives, then introduce path-result primitives, without
   changing public behaviour.
3. **Land isolated changes.** Implement containment, fallback/path,
   arithmetic/comparison, and update-assignment changes in separate reviews.
4. **Publish migration notes.** Provide before/after examples and replacements
   for filters whose output or failure mode changes.
5. **Validate the release candidate.** Run the full Perl test suite on all
   supported Perl versions and differential tests against jq 1.7 for every
   committed compatibility case.

## Migration guidance

Applications that need one code path across 2.x and 3.x should avoid relying
on the changed edge cases until they can require 3.0. Some changed semantics,
including the result of update assignment, cannot be normalized by appending a
filter that works in both major versions; those cases require version-aware
application logic. In particular:

| 2.x-dependent filter | 3.0-safe migration approach |
| --- | --- |
| `contains(...)` expecting exact array elements or nested object equality | express exact equality explicitly before upgrading |
| `false // fallback` expecting `false` | use an explicit null test when `false` is data |
| a missing path as an empty output stream | use `empty`/selection explicitly rather than relying on implicit dropping |
| arithmetic with booleans | convert the boolean to the intended number explicitly |
| equality between numeric strings and numbers | normalize both sides explicitly with `tonumber` or `tostring` |
| `path |= filter` expecting only the updated leaf | no single appended filter preserves this result in both versions; keep the original filter on 2.x, and only after requiring 3.0 append the path projection or select the leaf in version-aware application code |

Release notes must include concrete, executable examples for each committed
change. Library consumers should also review code that assumes `run_query`
returns no value for a missing field; in 3.0 that query returns one JSON null.

## 3.0 release criteria

JQ::Lite 3.0 is ready only when:

- every **change in v3** inventory row is implemented or explicitly deferred
  with a documented reason;
- every changed behaviour has jq 1.7 differential coverage and a direct
  JQ::Lite regression test;
- all preserved and still-undecided inventory rows remain covered;
- CLI and Library API contract suites pass unchanged;
- migration notes cover every intentional output or error change; and
- the complete distribution test suite passes on the supported Perl range.
