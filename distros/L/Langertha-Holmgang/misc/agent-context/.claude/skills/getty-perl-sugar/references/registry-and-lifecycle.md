# Registry design and module lifecycle

**Read when:** implementing registration, handling reloads, or designing introspection.

## Keep three stores separate

A declaration registry is owner-scoped process memory. Instance state contains
results and status for one run. A checkpoint store is durable state with an explicit
run identity and consistency protocol. Combining them invites cross-request leakage
and accidental reuse of another task's output.

Prefer a lexical registry behind methods or functions over publicly writable
`our %STEPS`. Package globals are acceptable in a small existing implementation,
but a facade gives validation, instrumentation, and future migration one boundary.
Use an array to preserve local declaration order and a hash index for duplicate
lookups. A failed registration must not partially append or reserve a key.

Recommended descriptor fields are `key`, `label`, `owner`, local declaration index,
`body`, `predicate`, `phase`, `requires`, and an explicit semantic revision. Record
source file and line when the export boundary can capture them reliably. Do not
pretend a fixed `caller(2)` points to the declaration across all export strategies.

Validate argument count before converting options to a hash. Otherwise an odd list
can be truncated and repeated options can silently overwrite one another. Reject
unknown fields, missing bodies, invalid keys, duplicate local keys, malformed
conditions, and invalid dependency shapes while the declaration is registered.
Merged conflicts need a later composition-aware check.

## What “load-time” actually means

`use Module` performs loading and import during compilation of its surrounding
unit. Ordinary top-level statements inside the required module execute as that
module is loaded. A declaration is an ordinary function call when execution reaches
it; it is not intrinsically a compile-time language construct. Loading via `require`
can happen later.

Consequently, do not compile and cache a final plan in the exporter's `init_meta`:
subsequent `step`, `with`, or `extends` statements may not have run. Do not put
`make_immutable` in an early `BEGIN` block. Do not introduce import-time I/O because
“nothing executes until run”; the containing Perl module certainly executes code.

## Mutation and finalization policy

At lookup, copy descriptors and their mutable arrays/maps. Retain callable references
internally; do not attempt to serialize code. Public `steps()` or `manifest()` should
return detached data with opaque callbacks labeled explicitly. Returning copied
arrays whose nested descriptor hashes still alias the registry is insufficient.

A sealed registry rejects later declarations. A final plan can be an immutable
snapshot for one run even when the process permits other classes to be declared.
If the system supports hot reload, document generation counters, cache invalidation,
and how existing runs retain their original plans. Requiring a file again after
manipulating `%INC` is not a safe reload protocol by itself.

The reference implementation offers explicit `seal_owner`; it does not automatically
seal all application packages or cache class plans. Its executor uses a bound
snapshot. Operators should treat that internal snapshot as private.

## Processes, dynamic classes, and tests

A process-local hash is not shared coordination across workers or machines.
Long-lived processes can retain closures and dynamically generated package names.
Use lifecycle-managed ownership for disposable classes; do not clear live
registries globally merely to reset a test. Prefer isolated test processes or unique
package names. Anonymous and parameterized roles need explicit identity handling.

**Implementation:** `Registry.pm`; tests cover atomic rejection, defensive copies,
local duplicate detection, and explicit sealing.
