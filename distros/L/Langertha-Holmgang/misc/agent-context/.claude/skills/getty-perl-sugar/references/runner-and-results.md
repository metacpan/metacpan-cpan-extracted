# Runner and result contracts

**Read when:** implementing execution, designing error handling, or debugging missing
or shared results.

## The runner's job

An exporter should not know how to emit progress or retry a remote operation.
A runner should coordinate a previously validated plan, per-run execution state,
a result store, and observers. The body receives the domain object; it can use
ordinary methods and request a predecessor's validated output.

Reserve a small runner API such as `run`, `result`, `has_result`, `results`, `steps`,
and `progress`. Check for collisions with existing application methods. If a class
needs to retain its own `run`, expose a differently named executor method rather
than silently replacing behavior.

For each active step, validate prerequisites, mark it running, invoke its body in
scalar context, validate the returned value, store the accepted result, and then
record success. Failures need the step key and owner plus useful original error
context. Avoid swallowing exceptions with a success-shaped empty hash.

## Results are not arbitrary Perl values

The reference body contract is an unblessed hashref containing JSON-compatible
values. An empty hash and false-valued fields are legitimate successes. A top-level
scalar, array, coderef, ordinary blessed object, or nested unserializable value is
not. A production schema may additionally require fields such as `markdown` and
`data`, versions, sizes, or typed errors.

Do not infer completion from truthiness. Use a validated success state and an
existing result record. In a constrained in-memory implementation, existence of a
validated result key is sufficient for that object's rerun behavior; it is not
sufficient to validate an arbitrary durable checkpoint.

`result('missing')` should fail with a useful diagnostic when the input is required.
An explicit `has_result` supports optional access. Return detached result snapshots
or immutable result values so consumers cannot corrupt stored outputs accidentally.
Large outputs can use content-addressed artifacts rather than repeatedly copying
large nested structures.

## State and failure policy

Distinguish `pending`, `running`, `succeeded`, `failed`, `skipped`, `cancelled`, and
`blocked` where the implementation needs them. Skipped work has not succeeded.
Retries count attempts, not new logical steps. Failure of one step may fail the run,
block dependent work, or activate a declared recovery branch; that policy belongs
in the runner, not in individual setup classes.

A schema-invalid result is a failed attempt, not a persisted success. Preserve
successful predecessors when an explicit retry is allowed. Whether a failed body
can safely run again depends on its side effects and idempotency, not on the fact
that it returned no accepted result.

## Reference scope

`Executor.pm` is synchronous and process-local. It freezes activation decisions
before execution, rejects reentrant use and reuse with another live subject, checks
prerequisites, records attempts, validates JSON-compatible results, and returns
copies. Calling `run` again on the same executor preserves successful results and
reattempts unfinished active steps. There is no automatic retry loop.

It does not implement durable persistence, input fingerprints, timeouts, cancellation,
leases, resource limits, or async bodies. Treat configuration as unchanged across
same-instance reruns. A new input set requires a new subject and executor. See
`resume-and-idempotency` before adapting this to production checkpoints.
