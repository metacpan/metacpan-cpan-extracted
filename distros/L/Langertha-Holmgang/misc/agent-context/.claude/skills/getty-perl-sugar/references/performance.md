# Performance without sacrificing the contract

**Read when:** optimizing load time, large plans, memory retention, or repeated runs.

## Measure distinct costs

Separate module loading and Moose initialization, declaration registration, role
traversal, plan compilation, predicate binding, body execution, result serialization,
checkpoint I/O, and event delivery. A faster step body may dwarf any registry change;
a service constructing thousands of tasks may instead expose repeated planning cost.

Use representative graph sizes, role depth, descriptor sizes, result payloads, and
run patterns. Measure cold and warm behavior. Report interpreter and dependency
versions, data shape, elapsed time, and memory assumptions. A unit-test runtime is
not a workload benchmark, and no speedup is claimed by this package.

## Optimizations with clear ownership

Use a per-owner key index to reject duplicates without scanning the whole local
array for every declaration. Retain ordered arrays for traversal. Resolve shared
metadata once per finalized class when the lifecycle permits safe caching.

Cache a structural plan only when the key covers composition and every relevant
registry generation. Bind instance-specific activation separately. Do not share
results, activation decisions, secrets, or mutable run state through a class cache.
A frozen class name alone does not version a mutable external registry.

For large graphs, replace repeated sorting of ready steps with a priority queue
using a deterministic priority key. A suitable heap-based Kahn traversal can target
`O(E + V log V)` ordering work, assuming constant-time adjacency/indegree operations.
Account separately for constructing descriptors and owner traversal.

The teaching planner repeatedly sorts its ready array. Its worst-case ordering work
can be on the order of `O(V^2 log V + E)`; it is intentionally simple, not a claim
of linear-time planning. Do not copy its implementation and advertise optimized
large-graph scheduling without measuring or replacing that queue.

## Copying and retention

Defensive copies protect the registry and results, but deep-copying large payloads
on every `result()` call can dominate execution. Consider immutable value objects,
read-only snapshots, or artifact references with content hashes. Make mutability and
ownership visible instead of removing copies silently for speed.

The example uses JSON round trips for detached result values and schema fragments.
That validates a narrow serialization contract but introduces encoding/decoding cost.
It is inappropriate for arbitrary Perl objects and intentionally rejects them.

Long-lived package registries retain their coderefs and captured lexical state.
Review closures for captured connection pools, request objects, and large buffers.
Dynamic package generation needs lifecycle management or a bounded cache. Avoid
strong cycles between executor and subject; the teaching executor stores no subject
reference, while the subject may own its executor.

## Parallel throughput

Tune concurrency against actual bottlenecks: API quotas, process slots, memory,
file descriptors, and downstream database limits. More Futures are not necessarily
more throughput. Put backpressure before launching work and separate queue time from
service time. Blocking calls in the loop can invalidate both throughput and heartbeat
expectations.

**Validation scope:** deterministic functional runs are included; no load, memory,
worker-pool, or production throughput benchmark was executed.
