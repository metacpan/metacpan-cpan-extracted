# Practical recipes and extraction decisions

**Read when:** choosing the smallest implementation that solves the current task.

## Recipe A: replace a repeated setup loop

First write a table of step keys, inputs, output shapes, prerequisites, and side
effects. Move the loop's execution policy into a runner. Keep the step bodies as
ordinary domain functions where possible; declarations should bind those functions
to stable identities and metadata.

Implement `step` plus a minimal registry. Add local validation immediately. Provide
one concrete consumer and one negative test. Do not add async behavior, forms, or
checkpoint storage merely because the pattern can support them.

Acceptance: the class contains declarations rather than repeated orchestration;
registration invokes no body; duplicate keys fail; output behavior matches the old
implementation. Preserve stable keys before introducing resume.

## Recipe B: share work through roles

Add a role-facing exporter with the same backend. Make owner identity explicit.
Collect declarations after composition and include inheritance if it is part of the
supported object model. Keep role buckets unchanged across consumers.

Acceptance: two classes can consume the same role without leaking results or
mutating each other's plans. A diamond contributes the intended declarations once.
Late `with` is visible. Merged key collisions fail with both owners named. Ordering
comes from a documented policy, not the order in which files happened to load.

## Recipe C: make a CLI or admin view plan-aware

Expose a safe, detached manifest of the structural plan. A read-only “describe”
command must not execute bodies or evaluate arbitrary dynamic conditions. An input-
specific “plan” command may bind approved preflight predicates, and should say so.

Keep these commands separate from “execute.” Reuse the manifest for documentation,
UI layout, or agent inspection; do not maintain three copies of the workflow.
Record opaque bodies and callbacks honestly rather than claiming full static analysis.

Acceptance: inspection does not perform provisioning, reveal secrets, or trigger
lazy external builders. Output is deterministic and serializable. Code changes
require explicit revisioning rather than relying on a closure's memory address.

## Recipe D: add tool or field sugar

Extract schema constructors into a pure helper module. Give tool registration and
attribute metadata their own normalized contracts. Decide whether one canonical field
spec should generate both the wire schema and the UI projection.

Acceptance: constructors return fresh data, reject unknown options, serialize JSON
booleans correctly, and distinguish omitted values from null. Server-side validation
and authorization remain explicit even when forms or tools are generated.

## Recipe E: add durable execution only when required

Read `resume-and-idempotency` before adding persistence. Specify operation
identity, semantic revisions, input compatibility, uncertain side-effect recovery,
and ownership of concurrent writes. Add one persistence adapter behind a narrow
interface rather than database logic inside each declaration keyword.

Acceptance: injected crashes do not silently duplicate non-idempotent operations or
mark unperformed work complete. Corrupted/incompatible state is rejected. Resumed
progress counts successes once. State migration is explicit.

## What should be extracted first?

| Symptom | Extraction |
|---|---|
| Class/role exports duplicate validation | Shared registration backend |
| Condition semantics differ between count and run | Predicate evaluator and one bound plan |
| `run` mixes sorting, execution, logging, and storage | Planner, executor, observer, persistence adapter |
| Schema constructors inspect caller or task state | Pure schema helper module |
| Role order changes behavior unpredictably | Explicit owner policy and dependency planner |
| Forms and tool parameters drift | Canonical field spec with separate projections |

Each extraction should remove duplicated policy or create an independently testable
contract. More files alone are not an improvement.
