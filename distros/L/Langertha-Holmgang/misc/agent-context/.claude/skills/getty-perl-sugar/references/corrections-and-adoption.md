# Common misstatements, and adopting the pattern in an existing DSL

**Read when:** checking a design note or an existing caller-based DSL against this
skill, or planning its migration.

## Where the pattern comes from

The architecture was distilled from a production Moose task DSL — a class exporter,
a role exporter, a predicate module and a shared runner — and from a design note
describing it. `Example::Sugar` is an original teaching implementation with
explicitly documented differences, not a copy of that system and not a drop-in
replacement for any existing DSL. A design note is not a source audit: do not infer
that an improvement proposed here is already implemented by the project in front of
you. Inspect its source.

## Misstatements and the precise rule

| Common formulation | More precise rule |
|---|---|
| Steps are functions “on the class” | They are package-level declaration functions; bodies are stored callables, not automatically named methods. |
| A keyword executes nothing | It executes registration/validation code, but no domain work; loading the module can still execute arbitrary Perl. |
| Every forwarding function needs `goto &` | Caller-sensitive forwarding does; explicit owner/metaclass forwarding does not. |
| `with_meta` is for attribute keywords | It can also bind ownership for ordinary registration keywords. |
| Role lookup uses Moose composition order | Role discovery is not a documented workflow-order contract; define stable scheduling independently. |
| Collect all roles, then the class | Include parent-class declaration buckets if inheritance is supported; inherited roles alone are insufficient. |
| Validate duplicate keys during registration | Also reject collisions that appear only when owners are merged. |
| Wrap synchronous bodies in Futures for parallelism | Wrapping normalizes a result; an event loop or actual workers provide concurrency. |
| Group members need “the same” predicate | Define normalized data equality or shared identity; do not claim arbitrary callbacks are equivalent. |
| Existing result key means resume-safe | Only after checkpoint identity, result validity, and side-effect/retry policy are checked. |
| `make_immutable` / `no Moose` are cleanup | Class immutability, custom DSL export cleanup, and registry sealing are separate operations. |
| `enum_` avoids a Perl builtin | `int_` avoids `int`; `enum_` avoids imported-library namespace conflicts. |
| Nullability can be added by adjusting type | An enum/const constraint may still reject null; a non-mutating union handles this case. |
| A fixed step-count invariant always applies | Distinguish declared, active, remaining, and dynamic counts; derive the denominator from the actual plan. |

These corrections concern general design contracts. They are not findings about any
particular codebase.

## Deliberate choices in the reference implementation

The reference exporters use `with_meta`, not caller-sensitive `as_is` registration.
The core backend can therefore be tested independently. The registry is lexical
behind functions. Phase ordering uses `gather/analyse/score/render`; prerequisites
are per-declaration `requires => [...]`, not a class-level `step_requires` method.
The planner validates the DAG and rejects active-to-disabled prerequisites.

Predicate expressions such as `tier eq name` are rejected; reader names, equality
maps, and callbacks are supported. Same-instance reruns reuse successful results,
but there is no durable checkpoint adapter. `par_step`, `par_group`, `tool`,
`config_attribute`, `user_input`, and `validation_step` are not bundled keywords.
Their design guidance lives in dedicated references. Schema helpers are executable.

## Adoption sequence

Inspect the project's actual source and its dependency versions. Characterize behavior
with tests using representative tasks and roles. Preserve public syntax and stable
keys while extracting registration, predicates, planning, and execution into clear
boundaries. Change semantics only through an explicit compatibility layer or versioned
migration. Compare safe manifests and real execution outcomes before replacing the
old runner.

`DBIO::Candy` and `DBIO::Cake` are public examples of the same metadata-sugar idea
applied to schema declarations; they are an analogy, not this workflow pattern.
