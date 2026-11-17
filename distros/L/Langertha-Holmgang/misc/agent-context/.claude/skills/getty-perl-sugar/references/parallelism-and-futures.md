# Parallel declarations and Future semantics

**Read when:** implementing `par_step`, `par_group`, asynchronous bodies, or timeouts.

## A Future represents completion, not execution capacity

`Future->needs_all(@futures)` succeeds when all components succeed. Normal failure
propagates immediately and cancels remaining pending components; successful result
lists are concatenated in input order. `wait_all` instead waits for every component
to become ready and returns component futures. Choose based on the required failure
policy, not because both names contain “all.”

This does not make synchronous code concurrent:

```perl
my @futures = map { Future->done($_->($self)) } @bodies;
```

Each body finishes before its result is wrapped. Concurrency requires operations
that start without blocking the interpreter, a suitable event loop, or actual
worker processes/threads. CPU-heavy Perl does not become parallel because a Future
is returned. Blocking work can also stop heartbeats and timeout callbacks driven
by that same loop.

## Define the executor adapter contract

Choose one return shape: either a hashref normalized to a completed Future or a
Future that resolves to exactly one validated hashref. Catch synchronous exceptions
before building the aggregate. Validate asynchronous outputs after completion.
Never treat a Future object itself as the completed step result.

Each grouped result must retain its original step key. Do not rely on concatenated
values having fixed positions unless the one-result-per-child contract is enforced.
Keep strong references to the aggregate and required children until their lifecycle
finishes. Decide whether partial successes are committed individually or as an
all-or-nothing group, and reflect that choice in checkpoints.

A Future's cancellation is not evidence that a remote HTTP request, external command,
or provisioned resource has been undone. The adapter must define cancellation
propagation, cleanup, and the residual side effects it cannot reverse.

## Plan checks before scheduling

Only group independent work. Reject missing members, repeated or overlapping groups,
phase mismatches, and direct or transitive intra-group dependencies. `par_group` is
not a substitute for validating the dependency graph. Use a single group predicate
for a collective activation decision, or define per-member activation explicitly.

Apply concurrency and resource limits before launching work. Bound the number of
in-flight operations; creating every Future at once can already launch too much.
On failure, stop launching new work and drain/cancel started work according to the
adapter's contract. Distinguish fail-fast from collect-all-errors behavior.

## Event-loop ownership and testing

One layer must own the loop. Do not start nested blocking loops accidentally inside
an already asynchronous application. IO::Async exposes loop-bound futures, timers,
and an `await` facility for driving a future to readiness. An async application's
outer execution boundary should own that wait.

Test concurrency by recording that both operations started before either completed,
not only by asserting a small elapsed duration. Test failure propagation,
cancellation, result mapping, synchronous exceptions, invalid async results, and
maximum in-flight counts. A test containing only already-completed Futures does not
prove event-loop integration.

**Bundled status:** `t/80-future.t` tests the real Future contract; `t/90-io-async.t`
tests real timer overlap when dependencies are installed. The synchronous reference
executor intentionally has no parallel keywords or production async scheduler.
