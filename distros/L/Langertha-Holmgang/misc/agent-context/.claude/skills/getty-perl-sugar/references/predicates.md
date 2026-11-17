# Predicates: a small contract, not a hidden language

**Read when:** adding `step_if`, comparing conditions, or calculating active steps.

## Normalize once

Keep predicate interpretation in a separately tested module. The bundled contract is:

| Representation | Meaning |
|---|---|
| `undef` | Unconditionally active |
| `'deep'` | Call a trusted parameterless reader and use Perl scalar truthiness |
| `{ tier => 'pro', region => 'eu' }` | All named readers must string-equal their expected values |
| `{ optional_value => undef }` | The reader must return an undefined value |
| `sub { ... }` | Trusted opaque callback receiving the subject and returning a scalar |

Map values cannot contain nested references. An empty map is rejected rather than
silently meaning “always true.” A missing reader is an error. Reference-valued
results are rejected so a Future or object does not accidentally become truthy.
The reference's scalar contract also excludes blessed JSON boolean objects; use
ordinary scalar readers or explicitly extend and test the normalization rules.

String equality in a map is a deliberate policy: `1` and `'1'` compare alike;
`undef` and `''` do not. Numeric comparisons, containment, dates, regular expressions,
and nested paths require separately named operators or a callback. Document them
before expanding the accepted data shape.

## Do not evaluate source text

Existing DSLs sometimes accept a string form such as `tier eq name`. Do not implement
it with Perl string `eval`. Either preserve it using a bounded, documented grammar
with tokenization and explicit comparison operations, or replace it with the map
form through a compatibility migration. The teaching implementation rejects such
expression strings. That is intentional, not a drop-in compatibility claim.

Even a safe parser does not make arbitrary method dispatch safe for untrusted input.
Restrict readers to an allowlist or metadata-identified attributes at that boundary.
An identifier-shaped method name is syntax validation, not authorization. Predicate
callbacks are application code and cannot be sandboxed by checking their type.

## Static and dynamic conditions

Preflight predicates depend only on frozen run configuration and can be evaluated
before work starts. Dynamic predicates depend on prior results or changing external
state. They belong at an explicit runtime gate with a defined scheduling policy.
Do not evaluate a callback twice merely to count steps, then again to execute them.
A changing decision can invalidate the progress denominator and dependency graph.

“Pure” is a contract, not something a coderef type check proves. Require no domain
I/O, no mutation, no executor invocation, and no result reads for preflight callbacks.
Use a serializable normalized condition for admin forms and planner explanations
where possible; label callbacks opaque rather than pretending to decode them.

## Predicate equality

Data predicates can be compared after normalization, using sorted keys and an explicit
policy for undefined values and scalar types. Two independent callbacks cannot in
general be proven semantically equivalent by comparing their source or addresses.
The same reference means identity within that process, not a stable persisted ID.

For all-or-nothing parallel activation, prefer a single predicate attached to the
group and evaluated once. An implementation that insists on matching per-step
conditions should reject uncertainty instead of claiming equivalence.

**Implementation:** `Predicate.pm`; planning tests exercise false branches, missing
readers, undefined comparisons, opaque manifests, and one-time binding.
