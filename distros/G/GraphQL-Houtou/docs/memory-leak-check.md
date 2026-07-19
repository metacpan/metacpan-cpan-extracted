# Memory Leak / Robustness Check

This document describes the repeatable memory-safety workflow for
`GraphQL::Houtou`'s XS-heavy code paths.

## Layers

1. **CI (`.github/workflows/robustness.yml`)** — runs on every push/PR:
   - `asan`: full test suite built with AddressSanitizer
     (`detect_stack_use_after_return=1`, `PERL_DESTRUCT_LEVEL=2`).
     Catches heap corruption and stack-use-after-return (the class of bug
     fixed in PR #22). `detect_leaks` stays off because perl's own arena
     bookkeeping drowns LSan.
   - `soak`: `util/soak-test.pl` with mixed request patterns and an RSS
     growth gate (see below).
   - `lint-xs-ownership`: `util/lint-xs-ownership.pl` static patterns.
2. **Local harness (`util/leak-check.pl`)** — stages a copy of the repo,
   builds it, and runs the active-suite cases under a platform leak checker
   (`leaks(1)` on macOS, ASan elsewhere).
3. **ithreads guard** — all XS handle classes define `CLONE_SKIP = 1` so
   ithread clones drop raw-pointer handles instead of double-freeing them.
   ithreads are otherwise unsupported (see POD CAVEATS).
4. **Frame live counters** — the XS keeps allocated-minus-released counts
   for block frames and path frames, readable via
   `GraphQL::Houtou::XS::VM::debug_frame_live_counts_xs()`. Both must be
   zero whenever no request is executing and no promise is pending; a
   positive residue after a completed request is an orphaned frame. This
   reproduces valgrind-class leaks deterministically on macOS (no
   valgrind needed) and is asserted per scenario by
   `t/54_frame_leak_regression.t`. The R5 leak hunt (2026-07-18) used
   these counters to pinpoint the fast-lane croak path-frame leak and the
   abandoned-request reference cycle. The permanent regression coverage is
   retained in `t/54_frame_leak_regression.t`.

## Soak test

```sh
perl -Iblib/lib -Iblib/arch util/soak-test.pl \
  [--iterations N] [--warmup N] [--max-growth-kb KB] [--scenario name]
```

Simulates a prefork web worker: warmup, snapshot RSS, run N mixed
requests, assert RSS growth stays under the gate. Scenarios:

- `varying_variables` — fresh variables every request
- `program_cache_eviction` — distinct query strings beyond the cache max
- `specialized_directives` — runtime directives with varying variables
- `resolver_error` — resolver die captured into the errors envelope
- `escaped_die` — coercion die propagating out of execute (croak path)
- `async_promise` — Promise::XS-backed resolvers
- `persisted_bundle` — precompiled native bundle execution

## Known per-scenario growth (2026-07-19, 4000 iterations after warmup)

| scenario | growth | status |
|---|---|---|
| varying_variables | +16 KB | clean |
| specialized_directives | +32 KB | clean |
| persisted_bundle | +16 KB | clean |
| escaped_die | +0 KB | fixed in the Phase B batch (was +5472 KB) |
| resolver_error | +16 KB | fixed (was +496 KB, ~125 B/req, on 2026-07-05) |
| async_promise | +16 KB | fixed (was +1696 KB, ~425 B/req, on 2026-07-05) |
| program_cache_eviction | +0 KB | fixed (was +432 KB, ~110 B/req, on 2026-07-05) |

The three formerly open scenarios re-measured at allocator-noise level
after the R5 valgrind pass and the frame-lifecycle fixes pinned by
`t/54_frame_leak_regression.t`.

Two cross-cutting leaks were found and fixed while attributing the table
above (both pre-existing on main):

- the parser leaked one empty location hash per parse
  (`gql_make_current_location` abandoned a fresh HV on its EOF fallthrough)
- `cursor_restore_copy` zeroed the live cursor's refcount at every block
  exit (it delegated to `snapshot_copy`, whose `Zero(dst)` wiped it); the
  next unsigned decrement underflowed and the 48-byte cursor struct leaked
  on every exec-state request across all scenarios

The CI gate (`--max-growth-kb 2048` over 20k mixed iterations) is
calibrated against the clean baseline: the full mixed run measures
+488 KB on the Linux CI runner and +448 KB on the macOS development
host (2026-07-19), so 2048 KB leaves >4x headroom for platform noise
while still catching a reintroduced per-request leak of ~80 B/req.

## Local harness cases

```sh
perl util/leak-check.pl                 # all cases
perl util/leak-check.pl --case promise  # focused
perl util/leak-check.pl --backend leaks # macOS default
```

Cases: `parser_public`, `execution`, `vm_execute`, `promise`, `aliases`,
`persisted`, `oneof`, `croak_safety`, `soak` (short profile).

## History

- 2026-04-05: original harness pass on the pre-runtime-reboot suite
  (t/03, t/04, t/11, t/12 — since removed; see git history under
  `legacy-tests/`).
- 2026-07-05: cases refreshed to the active mainline suite; soak harness,
  ASan CI gate, and CLONE_SKIP guards added (performance plan Phase B).
