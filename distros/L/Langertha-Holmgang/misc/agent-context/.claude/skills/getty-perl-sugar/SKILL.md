---
name: getty-perl-sugar
description: Use when designing a new Perl DSL or sugar — Moose::Exporter keywords, declarative structures, metadata registries. Not for using an existing one.
---

# Getty Perl Sugar

For the start of a structure: planning a new DSL, keyword exporter or declarative
layer in Perl, so it is built right from its first keyword. Once the structure
exists, using or extending it follows the project's own code, not this skill.

Turn repeated domain structure into declarations; keep execution policy in one place.
The bundled `Example::Sugar` shows the mechanism; it is not a module to depend on,
and project code follows `getty-perl-core` and `getty-perl-moose`.

## Start here

Read [architecture](references/architecture.md), then only the references the design
needs (table below). For a new DSL, read `Sugar.pm`, `Sugar/RoleDSL.pm` and
`Sugar/Owners.pm` under `examples/reference/lib/Example/` first: class entry point,
role entry point, and owner collection across parents and roles.
Replacing an existing caller-based DSL, start with the
[correction and adoption map](references/corrections-and-adoption.md).

Inspect the repository's actual exporters, consumers, role composition, Perl/Moose
versions, and tests before changing its public syntax. A design note about the
project is not a substitute for source inspection.

## Working procedure

1. Identify repeated orchestration and the smallest useful domain vocabulary. Keep a
   plain function or method when there is no meaningful metadata or reuse benefit.
2. Specify descriptors first: stable keys, labels, owners, bodies, conditions, phases,
   prerequisites, result shapes, and versioning. State what is inspectable and opaque.
3. Separate declaration registration, plan compilation/binding, and execution. Validate
   local shape while registering; validate cross-owner conflicts and dependencies after
   composition; validate results before recording success.
4. Preserve existing syntax. For new Moose sugar, prefer `with_meta` and pass `$meta->name`
   into a shared registration backend. For caller-sensitive `as_is` exports, capture
   the owner at the boundary or use a transparent `goto &target` shim.
5. Define composition and scheduling independently. Include inherited class declarations,
   deduplicate role owners, reject merged key collisions, and establish deterministic
   phase/dependency ordering. Do not treat `calculate_all_roles` as a workflow-order API.
6. Add phases, prerequisites, conditions, parallelism, persistence, form metadata, or
   tool schemas only when needed. Without them the minimum is a registry, owner
   collection, and a merged-key check before the first body runs — no planner.
   Each addition needs an explicit contract, negative tests, and observability.
7. Run the relevant tests and report exactly what passed, failed, or was skipped.
   Never describe a dependency-gated test as an executed integration test.

## Non-negotiable boundaries

Declaration keywords register and validate; they do not perform domain I/O or run step
bodies. Loading a Perl module is nevertheless code execution, not safe data parsing.

`step` is an exported declaration function, not a generated instance method. The
runner invokes the stored body with `$self`; bodies may delegate to ordinary methods.

Keep registries separate from instance results and durable checkpoints. Never mutate a
shared role bucket while composing one consumer. Never expose live registry hashes as
public introspection data. Keep bodies and arbitrary predicates explicitly opaque.

Reject unknown options, missing coderefs, duplicate keys, unknown dependencies, cycles,
phase inversions, and incompatible active prerequisites before side effects begin.
Do not `eval` predicate strings. Do not infer semantic equality of separate callbacks.

A Future is not an execution pool. A cached result is not an exactly-once guarantee.
An immutable Moose class is not a frozen external registry. Schema metadata is not
authorization, and UI hints are not server-side validation.

## Example shape

```perl
use Example::Sugar;
step 'Collect inputs' => inputs => sub { return { count => 3 } };
step 'Summarize' => summary => sub {
  return { count => $_[0]->result('inputs')->{count} };
}, phase => 'render', requires => ['inputs'];
no Example::Sugar;
__PACKAGE__->meta->make_immutable;
```

This syntax belongs to the bundled reference implementation, not to any existing
project's API. See [the implementation guide](examples/reference/README.md).

## References

Routes — new DSL: architecture → exporters → registry → planning → the example.
Async or durable: planning → predicates → Futures or resume → observability →
security. Agent-facing inspection: planning manifests → tool schemas → security.

| Reference | Read when |
|---|---|
| [architecture](references/architecture.md) | Whether a DSL is justified and what belongs in each layer |
| [exporters-and-caller](references/exporters-and-caller.md) | Class/role entry points, `with_meta`, `as_is`, `goto`, cleanup |
| [registry-and-lifecycle](references/registry-and-lifecycle.md) | Validation, load timing, defensive copies, sealing, reloads |
| [composition-and-inheritance](references/composition-and-inheritance.md) | Role discovery, parent buckets, diamonds, order, conflicts |
| [planning-and-dependencies](references/planning-and-dependencies.md) | Phases, DAG checks, binding, group validation, manifests |
| [predicates](references/predicates.md) | Readers, maps, callbacks, purity, equality, safe parsing |
| [runner-and-results](references/runner-and-results.md) | Runner API, state, errors, output validation, same-instance reruns |
| [parallelism-and-futures](references/parallelism-and-futures.md) | Real concurrency, aggregation, cancellation, loop integration |
| [resume-and-idempotency](references/resume-and-idempotency.md) | Durable resume: checkpoint identity, crash windows, leases |
| [progress-and-observability](references/progress-and-observability.md) | Active counts, dynamic gates, events, heartbeats, redaction |
| [attributes-and-forms](references/attributes-and-forms.md) | Traits, UI projections, validation boundaries, secret fields |
| [tool-schemas](references/tool-schemas.md) | Pure helpers, nullable enum, dialects, provider adapters |
| [validation-and-localization](references/validation-and-localization.md) | Preflight reuse, freshness, message IDs, deferred translation |
| [security-and-trust](references/security-and-trust.md) | Loading code, authorization, untrusted inputs, tool dispatch |
| [testing-and-debugging](references/testing-and-debugging.md) | Negative tests, caller debugging, integration gates, determinism |
| [performance](references/performance.md) | Measurement, safe caching, planner complexity, backpressure |
| [corrections-and-adoption](references/corrections-and-adoption.md) | Common misstatements, migrating an existing DSL |
| [recipes](references/recipes.md) | Incremental adoption and what to extract first |

## Deliverable contract

Provide the domain contract, chosen module boundaries, public declaration example,
ordering/conflict policy, focused tests, and compatibility notes. Separate proposed
production extensions from implemented behavior.
