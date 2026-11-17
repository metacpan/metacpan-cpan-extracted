# Resume, persistence, and side-effect safety

**Read when:** saving results between processes or retrying provisioning work.

## Separate three promises

Memoization avoids repeating completed work within one execution object. Resume
restores a compatible run after interruption. Exactly-once side effects require a
stronger protocol with the system receiving the side effect. A hash keyed by step
name provides none of the durable guarantees on its own.

A safe checkpoint identity should cover the workflow class and revision, normalized
plan and semantic step revisions, relevant input identity, result-schema revision,
and tenant or resource scope. A timestamp or package name alone is inadequate.
Do not persist raw secrets to compute this identity. Use protected secret version
identifiers or a suitable keyed digest where necessary, and keep digests out of
public logs when they could facilitate guessing.

## A minimal persistence contract

Store a run identifier, checkpoint schema version, plan identity, input identity,
and explicit per-step state. A successful record should include a validated result
or artifact reference, semantic revision, completion time, and any external
idempotency key. Store attempt information separately from logical step identity.

On resume, validate checkpoint structure and compatibility before executing anything.
Reject unknown successful keys, incompatible revisions, corrupted results, and
unsatisfied dependencies. Decide explicitly whether compatible partial state may
be migrated. An `exists $results->{$key}` check is useful only after this validation.

Do not restore arbitrary Perl objects or coderefs from an untrusted checkpoint.
Use a constrained data serialization format and validate size, depth, ownership,
and permissions. Loading metadata is not authorization to act on the recorded tenant.

## The crash window

Consider: a step creates a remote resource, then the worker crashes before committing
its result. On restart, the step appears unfinished. Repeating it may create a second
resource. Persisting success before making the call only creates the opposite bug:
a run can claim completion for an operation that never happened.

Use external idempotency keys, reconciliation against actual state, or a transaction
that genuinely covers both effect and checkpoint. For independent systems, design
compensation or an outbox/reconciliation protocol rather than promising a generic
atomic commit. Retrying a non-idempotent effect needs an explicit decision.

Differentiate “operation requested,” “operation observed successful,” and “result
committed” when those boundaries can diverge. A recovery procedure must examine
uncertain states instead of reducing all of them to “not done.”

## Workers and concurrency

A lease can establish temporary ownership, but an expired lease does not prevent a
stale worker from continuing. Use fencing where the downstream system supports it,
and record ownership transitions. Concurrent checkpoint writes require transactional
updates or compare-and-swap semantics; an uncoordinated JSON file is not a shared
worker database.

For local-file persistence, consider same-filesystem atomic replacement, durability
requirements, file and directory permissions, locking, and recovery of incomplete
writes. For database persistence, specify isolation and conflict handling. Neither
storage choice automatically solves external exactly-once behavior.

## Interaction with predicates and progress

Persist or reproducibly derive activation decisions from the same frozen inputs.
A newly disabled prerequisite must not be silently satisfied by an unrelated old
result. Count resumed successes as completed logical steps; failed attempts do not
increase the denominator. Validation-result reuse must use the same compatibility
rules as any other cached work.

**Reference limit:** only same-instance reuse is implemented. Durable resume,
checkpoint migrations, and multi-worker coordination are design guidance here;
no integration or crash-safety claim is made.
