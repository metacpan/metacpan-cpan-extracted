# Compile a plan before executing it

**Read when:** adding phases, prerequisites, plan inspection, or concurrency groups.

## Structural compilation

Normalize declarations into a flat set of stable step identities with provenance.
Detect duplicate keys after merging all owners. Resolve each prerequisite to a
known step. Reject self-dependencies, duplicate dependency entries, cycles, and
unsupported options before invoking any body.

Phases are coarse ordering constraints. The example uses `gather`, `analyse`,
`score`, and `render`; these names are a policy choice, not a Perl/Moose feature.
A step in an earlier phase may not require a step in a later phase. Reject this
inversion rather than silently overriding a declared phase barrier.

Within a phase, use a stable topological order: only prerequisite-free steps are
ready, and ties use explicit owner order followed by local declaration index.
If no prerequisites exist, this reduces to deterministic phase/declaration order.
If the graph contains a cycle, produce a diagnostic naming unresolved keys; a
production diagnostic should identify an actual cycle path as well.

The example uses straightforward repeated sorting of ready steps because the
teaching graphs are small. It is not an optimized scheduler. A heap-based ready
queue is appropriate when measured plan sizes justify it.

## Binding to a run

A structural plan contains every declaration. A bound plan adds activation decisions
for one immutable set of run inputs. Evaluate eligible preflight predicates once,
store the decisions, then validate the active graph. An enabled step whose required
producer is disabled is invalid unless the DSL explicitly defines another policy.

Do not silently treat a missing result as an empty value or auto-enable the producer.
Optional prerequisites need their own semantics: fallback value, optional input,
or explicit branch-aware join. A result-reading predicate is not a preflight
predicate; support it as a dynamic gate and update progress semantics accordingly.

The example supports only preflight predicates. Predicate callbacks must not call
`result()`, run the executor, or depend on state that changes during execution.
Static `manifest()` does not invoke them. Binding can fail, and must complete before
the first body executes.

## Parallel groups are plan nodes, not mutations to a role

If preserving `par_group qw(a b c)`, collect group declarations as metadata and
resolve them after all steps are known. Never destructively remove or rewrite steps
in a shared role bucket just because one consuming class groups them.

Reject unknown group members, duplicate membership, overlapping groups unless
explicitly supported, incompatible phases, and dependencies between members. Check
transitive paths too: a dependency routed through an external node can still make
a single simultaneous group impossible. A group is not a way to bypass the DAG.

The reference executor does not implement groups. Its registry deliberately rejects
unknown group-related options rather than accepting declarations it cannot honor.
See `parallelism-and-futures` before adding such an adapter.

## Inspectable output

A useful manifest exposes schema version, owners, keys, labels, phases, prerequisites,
revision, activation state when bound, and an honest predicate description.
Keep source paths relative or redact them in public views. Do not serialize coderefs,
credentials, or arbitrary object internals. Stable manifests support documentation
and review; they are not complete semantic hashes of executable code.

**Implementation:** `Plan.pm`; this file's ordering and activation rules are original
reference-design choices, not claims about any existing implementation.
