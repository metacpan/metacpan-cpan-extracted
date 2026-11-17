# Architecture: declare structure, centralize execution

**Read when:** deciding whether sugar belongs in a design, or separating a large runner.

## The useful abstraction

A declarative workflow describes a domain object with named operations. Exported
functions populate metadata; a common executor interprets that metadata. Repeated
control flow becomes a policy implementation rather than being copied into every
consumer's `run` method. The point is inspectable structure and reusable behavior,
not a shorter spelling of a loop.

A task class can still have attributes, helper methods, and meaningful domain logic.
Only orchestration policy moves out. A step body can call a tested service object or
an ordinary method. A class containing hundreds of lines of inline anonymous
subroutines is not automatically cleaner than one with well-named helpers.

`step 'Probe' => probe => sub { ... }` is conceptually a function call that creates a
record. It does not define a method named `probe`. Registry data can contain a
coderef, but the coderef's behavior is not inspectable data. The same distinction
applies to arbitrary predicates. A plan viewer can describe their presence and
identity without understanding their semantics.

## Three distinct stages

| Stage | Inputs | Responsibilities | Must not do |
|---|---|---|---|
| Registration | Declaration arguments, owner | Normalize shape, validate local options, retain provenance | Network calls, provisioning, step execution |
| Compilation and binding | Composed owners, then run inputs | Detect collisions, order dependencies, evaluate permitted preflight conditions | Execute step bodies, mutate source buckets |
| Execution | Bound plan and per-run state | Invoke bodies, validate outputs, commit completion, emit events | Redefine the DSL or silently repair an invalid plan |

Compilation is structural. Binding is instance-specific and may evaluate trusted
predicate callbacks. Do not claim that binding is side-effect-free unless callbacks
and readers are required to be pure. A static manifest must not evaluate them.

## Recommended extraction boundaries

Keep a class exporter and a role exporter thin. Both should call the same
registration backend. A registry owns declarations; a planner owns dependency and
ordering policy; a predicate evaluator owns condition semantics. A runner coordinates
an executor, persistence adapter, and observer rather than implementing each inline.
Schema constructors should be pure functions in a separate module. Attribute traits
belong with metadata integration, not inside the scheduler.

These are responsibility boundaries, not a command to create a separate distribution
for each concern. For a small flow, several responsibilities may remain in one file
with independent functions. Extract a module when it has its own contract, tests,
consumers, or rate of change.

The reference implementation deliberately separates a core-only backend from its
Moose adapters. This allows testing actual planning and execution without claiming
that tests of those layers verify Moose import or role-composition behavior.

## When not to use this pattern

A two-step routine with no reuse, introspection, conditional structure, or lifecycle
policy can remain a method. Conversely, a two-step workflow requiring durable
checkpoints and administrative introspection may justify declarations. A fixed
threshold such as “five steps” is a heuristic, not an architectural rule.

Do not replace an established task engine merely to obtain a preferred syntax.
A thin DSL that emits that engine's existing definition format may be sufficient.
Do not invent parallel and persistent semantics before there is a concrete need.

**Basis:** original engineering guidance distilled from a production Moose task DSL.
