# Progress, events, and heartbeats

**Read when:** adding progress bars, an admin UI, metrics, or long-running task status.

## Derive totals from the same plan that will execute

A static declaration count, an active count for one input set, and an amount of
remaining work are different quantities. Expose them separately. A parallel group
contains logical leaf steps; counting the group as an extra completed step usually
makes the displayed denominator inconsistent.

For preflight-only conditions, bind the plan once and derive `active_total` from
that bound plan. Reuse its decisions during execution. A manually configured expected
count can serve as an assertion, but should not be a second authoritative source.
Report both the expected and computed values on mismatch before starting work.

For a dynamic gate, a fixed active denominator may not yet exist. Choose and document
one policy: count all declared steps and show skips, expose a dynamic total honestly,
or use a progress model based on known phases. Do not repeatedly evaluate dynamic
predicates merely to manufacture a stable number.

Distinguish `succeeded`, `failed`, `skipped`, `cancelled`, and `blocked`. “Terminal”
does not mean “successful.” A failed run can be finished without being 100% successful.
Retries increase attempt counters, not the number of logical steps. Resumed successes
count toward completion without generating fake execution durations.

## Define an event vocabulary

A useful event envelope includes schema version, run ID, monotonic sequence number,
step key, owner, attempt, event type, timestamp, and a bounded payload. Events might
be `run_started`, `step_started`, `step_succeeded`, `step_failed`, `step_skipped`,
`checkpoint_committed`, and `run_finished`.

Emit success only after the result has passed validation and the selected commit
boundary has completed. If an observer fails after a side effect succeeds, do not
rerun that side effect just to reproduce a log message. Prefer observers whose
failure policy is independent of execution, or a durable outbox when event delivery
must be coupled to checkpoint writes.

Use a monotonic clock for durations and wall-clock timestamps for external correlation.
Include a stable machine key in logs; localized labels are presentation, not identity.
Do not use result values or exception messages as unbounded metric labels.

## Heartbeat limitations

A heartbeat running on the same event loop cannot prove liveness while that loop is
blocked in synchronous code. A separate supervisor can observe process liveness,
but cannot necessarily tell whether useful work is progressing. Distinguish worker
health, lease renewal, operation progress, and application-level completion.

A timeout should identify the responsible layer: request timeout, subprocess limit,
step deadline, or overall run deadline. Cancellation requests and observed cancellation
are separate events. See `parallelism-and-futures` for adapter semantics.

## Public views

A UI can consume the manifest plus run events. Do not expose raw registry structures,
secret attributes, code references, complete environment variables, or full request
payloads. Truncate and redact errors without losing a stable error category and
correlation ID. Generate diagrams from safe manifests rather than importing arbitrary
untrusted classes into an administrator's process.

**Reference scope:** the example exposes counters and states, not an event bus,
heartbeat service, metrics exporter, or durable event stream.
