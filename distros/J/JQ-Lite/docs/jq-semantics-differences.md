# jq semantic differences in JQ::Lite 2.x

JQ::Lite implements a useful jq-like language, but it is not a drop-in
implementation of every jq runtime semantic. This document records the
currently known **semantic** differences: cases where a filter is accepted by
both tools but its result or failure behaviour differs. It is a snapshot of
the 2.x behaviour, not a claim that unsupported jq syntax is supported.

The examples in the `jq` column describe jq 1.7 behaviour. The JQ::Lite
results are protected by `t/jq_semantic_differences.t`; the regression suite
does not require a jq executable.

## Decision statuses

Every inventoried item has one of the decision statuses requested for the v3
planning process:

- **preserve** — keep the JQ::Lite meaning, even though jq differs;
- **change in v3** — retain it throughout 2.x, but make jq compatibility the
  target of a separately reviewed v3 change;
- **undecided** — no v3 decision has been made. The 2.x behaviour remains
  regression-protected until that decision is made.

The status is a roadmap classification, not a runtime change in the 2.x
series. “Follow-up” deliberately uses topic names rather than inventing issue
numbers; it can be replaced by a concrete issue link when that work is filed.

## Inventory

### A. Preserved 2.x compatibility behaviour

These differences are observable existing behaviour on which 2.x callers may
rely. Changing them requires an explicit compatibility decision rather than
an incidental parser or filter refactor.

| Area | Example | jq | JQ::Lite 2.x | v3 status | Follow-up |
| --- | --- | --- | --- | --- | --- |
| Array `contains` | `[1,2,3] \| contains([1,3])` | `true` (recursive subset containment) | `false` (looks for one element equal to the complete argument) | **change in v3** | containment semantics |
| Nested object `contains` | `{"a":{"b":1,"c":2}} \| contains({"a":{"b":1}})` | `true` | `false` (nested values must be equal) | **change in v3** | containment semantics |
| Alternative operator | `false // 9` | `9` | `false` (only null, missing, or empty output selects the fallback) | **change in v3** | null and fallback semantics |
| Jagged `transpose` | `[[1,2],[3]] \| transpose` | `[[1,3],[2,null]]` | `[[1,3]]` (truncates to the shortest row) | **preserve** | none |

For recursive, order-insensitive array containment, JQ::Lite provides the
explicit `contains_subset(value)` alternative. It avoids changing the
established meaning of `contains(value)` in the 2.x series, but it is not a
drop-in implementation of jq's `contains`: it uses multiset counting, whereas
jq can satisfy repeated needles with one matching value, and it compares
scalars by their string forms, whereas jq keeps JSON scalar types distinct.
For example, `[1] | contains_subset([1,1])` is `false` although jq's
`contains([1,1])` is `true`; `["1"] | contains_subset([1])` is `true` although
jq's `contains([1])` is `false`.

### B. Arithmetic and type coercion

JQ::Lite commonly favours lossless pipeline processing and Perl scalar
coercion where jq reports a type error or applies a different overloaded
operation.

| Area | Example | jq | JQ::Lite 2.x | v3 status | Follow-up |
| --- | --- | --- | --- | --- | --- |
| Numeric coercion | `"1e3" * 1` | `"1e3"` (string repetition) | `1000` | **undecided** | arithmetic/coercion |
| Boolean arithmetic | `true + 1` | type error | `2` | **change in v3** | arithmetic/coercion |
| Vectorised rounding | `[1.2,"2.8","x"] \| floor` | type error | `[1,2,"x"]` | **preserve** | none |
| Lossless JSON parsing | `["1","true","bad"] \| fromjson` | type error (input is not a string) | `[1,true,"bad"]` (element-wise, invalid text passes through) | **preserve** | none |
| Regex scalar coercion | `42 \| match("2")` | type error | a match object for the string form `"42"` | **undecided** | type coercion |

This category is especially important when moving filters between the tools:
successful JQ::Lite output does not imply that jq will accept the same input
types. Conversely, jq operator overloading must not be assumed to use Perl's
numeric coercion in JQ::Lite.

### C. Comparison

| Area | Example | jq | JQ::Lite 2.x | v3 status | Follow-up |
| --- | --- | --- | --- | --- | --- |
| Equality across types | `"10" == 10` | `false` | `true` (numeric-looking strings compare numerically) | **change in v3** | comparison semantics |
| Ordering across JSON types | `false < 0` | `true` | `true` | **preserve** | none; regression parity guard |
| Array ordering | `[1,2] < [1,3]` | `true` (lexicographic ordering) | `false` | **change in v3** | comparison semantics |
| Missing-value comparison | `.missing == null` | `true` | `true` | **preserve** | none; regression parity guard |

Parity rows are included intentionally: they mark adjacent behaviour that was
checked during the inventory and prevent a future coercion fix from changing a
currently jq-compatible case by accident.

### D. Null, missing values, and paths

| Area | Example | jq | JQ::Lite 2.x | v3 status | Follow-up |
| --- | --- | --- | --- | --- | --- |
| Missing object field | `{}` with `.missing` | one `null` result | no results | **change in v3** | null/missing/path semantics |
| Path through a missing field | `{}` with `.missing.value` | one `null` result | no results | **change in v3** | null/missing/path semantics |
| Invalid array field path | `{"a":[]}` with `.a.value` | type error | no results | **undecided** | path error policy |
| Numeric index on an object | `{}` with `.[5]` | type error | one `null` result | **change in v3** | path error policy |

JQ::Lite therefore distinguishes a missing traversal (an empty result stream)
from an explicit JSON null in direct path output, even though comparisons such
as `.missing == null` currently treat them alike.

### E. Iterators and pipelines

| Area | Example | jq | JQ::Lite 2.x | v3 status | Follow-up |
| --- | --- | --- | --- | --- | --- |
| Array path projection | `[{"x":1},{"x":2}] \| .x` | type error | `1`, `2` | **preserve** | none |
| Projection after mixed iteration | `{"a":[{"x":1}],"n":3} \| .[] \| .x` | type error on the array | `1` (projects through the array and drops the scalar's missing value) | **undecided** | iterator/pipeline semantics |
| Iterator suffix | `keys[]` | same results as `keys \| .[]` | same results as `keys \| .[]` | **preserve** | none; regression parity guard |
| Comma plus iterator | `0, [4,5][]` | `0`, `4`, `5` | `0`, `4`, `5` | **preserve** | none; regression parity guard |

### F. Assignment and update

| Area | Example | jq | JQ::Lite 2.x | v3 status | Follow-up |
| --- | --- | --- | --- | --- | --- |
| Plain assignment | `{"a":1} \| .a = 2` | `{"a":2}` | `{"a":2}` | **preserve** | none; regression parity guard |
| Update assignment result | `{"a":1} \| .a \|= . + 1` | `{"a":2}` | `2` (emits the updated value, not the root) | **change in v3** | assignment/update semantics |
| Missing update target | `{"a":1} \| .missing \|= . + 1` | object with `"missing":1` | no results | **change in v3** | assignment/update semantics |
| Multi-result assignment | `{"a":0} \| .a = (1,2)` | two updated objects | no results | **undecided** | assignment/update stream semantics |

### G. Unsupported jq behaviour

Feature absence is distinct from a semantic conflict, but unsupported jq
constructs affect portability and are therefore tracked here as required by
the audit.

| jq facility | Example | JQ::Lite 2.x | v3 status | Follow-up |
| --- | --- | --- | --- | --- |
| User-defined functions | `def inc: . + 1; inc` | not implemented; currently evaluates to `null` | **undecided** | parser unsupported-syntax policy |
| Labels and `break` | `label $out \| break $out` | not implemented | **undecided** | control-flow coverage |
| Modules/imports | `import "x" as x; ...` | not implemented | **preserve** | none; outside lightweight scope |
| jq streaming parser mode | `--stream` | CLI option not implemented | **preserve** | none; outside current CLI scope |

### H. Explicit JQ::Lite extensions and migration aids

These names do not represent a conflicting jq meaning; they make JQ::Lite's
intent explicit or provide behaviours useful to existing pipelines.

| Extension | Purpose | v3 status | Follow-up |
| --- | --- | --- | --- |
| `contains_subset(value)` | Recursive, order-insensitive multiset containment; unlike jq, duplicate needles require duplicate matches and scalar comparison coerces to strings | **undecided** | reconcile its semantics and name if `contains` changes in v3 |
| `to_number()` | Lossless/vectorised numeric conversion, distinct from strict `tonumber()` | **preserve** | none |
| `flatten_all()`, `flatten_depth(n)` | Explicit flattening variants | **preserve** | none |
| Statistical and convenience helpers | `avg`, `median`, `mode`, `percentile`, `variance`, `stddev`, `clamp`, and the other extensions listed in the function reference | **preserve** | none |

## What this inventory does not cover

- The unsupported-behaviour table is representative rather than a complete
  list of every jq built-in or command-line option not implemented by JQ::Lite.
- CLI diagnostics are governed by the stable CLI contract; exact jq error text
  is not a JQ::Lite compatibility promise.
- Object key order is not compared because JSON object ordering is not a
  portable semantic guarantee.
- jq may evolve after 1.7. When this inventory is updated, jq-version changes
  and JQ::Lite behaviour changes should be reviewed separately.

When a new difference is found, add it to the appropriate category and add a
dependency-free regression assertion for the current JQ::Lite behaviour. A
future behaviour change should be proposed separately, with the relevant 2.x
compatibility impact called out explicitly.
