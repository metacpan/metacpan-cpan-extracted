# Composition, inheritance, and deterministic owner discovery

**Read when:** reusing declarations in roles, supporting subclasses, or fixing
surprising execution order.

## Discovery is not scheduling

`calculate_all_roles` returns unique attached role metaclasses. Its documented
contract does not promise the business execution order of your workflow.
`calculate_all_roles_with_inheritance` also includes ancestor roles, but does not
thereby collect your separate parent-class declaration buckets.

Define your own owner-discovery policy and schedule the merged declarations
separately. Retain owner provenance so collisions can identify both sources.
Do not use Perl hash iteration, module load order, or coderef addresses as a
persistent ordering key.

The teaching adapter uses this explicit policy:

1. Visit classes in base-first reverse linearized inheritance order.
2. At each class, visit discovered role names in lexical order, deduplicated globally.
3. Append that class's own declaration bucket, then let the planner apply phases
   and prerequisites.

This policy is deterministic; alphabetical role order is not meaningful domain
ordering. Declare a phase or dependency whenever relative order matters. For
multiple inheritance, review the chosen reverse-MRO policy rather than presenting
it as Moose composition precedence. `linearized_isa` is a metadata facility, not
a workflow schedule.

An alternative is explicit DSL-level role priorities or an explicit ordered source
list. That adds API surface but avoids giving unrelated names accidental ordering
significance. Record and test whichever policy the project chooses.

## Composition edge cases

A role used through two paths in a diamond should normally contribute its
owner-scoped declarations once. Distinct parameterized role instances may need to
contribute separately. Do not deduplicate them merely because they share a
human-readable base name.

Moose method aliases and exclusions act on methods. Your side registry is not
automatically renamed or filtered when a role method is aliased or excluded.
Either add explicit DSL-aware renaming/exclusion semantics or reject unsupported
combinations. A role's method-conflict handling does not detect collisions between
step keys stored only in your registry.

Two roles declaring the same key, a role and its consuming class declaring the same
key, and a parent and child declaring the same key all require an explicit policy.
The safe default is a composition error. “Last writer wins” can change resume
identity silently. If overriding is needed, make it explicit, retain replaced
provenance, and include it in plan versioning.

## Lookup timing and caching

Resolve after composition, not when a role first declares its steps. A reusable
role's metadata must remain unchanged when different classes consume it. Repeated
lookup must not append the role's declarations again.

A finalization step can resolve all owners once. A cache key must cover owner
registry generations and composition changes, not only the consuming package name.
Inherited metadata and dynamically applied roles can invalidate cached plans.
The bundled implementation recomputes structural plans rather than pretending to
implement a correct dynamic cache.

**Tests:** core tests verify explicit source deduplication and merged conflicts.
`t/70-moose.t` separately verifies real role ownership, late `with`, class cleanup,
instance isolation, and inherited class declarations when dependencies are present.
