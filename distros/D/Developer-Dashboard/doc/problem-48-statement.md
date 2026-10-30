# Problem 48 — Full performance objective and evidence

## Problem statement

Accelerate every Developer Dashboard subroutine by at least 50× versus Developer Dashboard 5.88, evaluating MCE, FFI::Platypus, Inline::C, XS, SPVM, Memoize, and Perl's built-in `class`, `method`, `field`, and method/subroutine signatures. Preserve all behavior and prove each speedup with reproducible benchmarks and regression tests. The objective remains the full one; current evidence does not establish completion.

## What is established

- A source-line inventory finds 1,648 named `sub` declarations under
  `lib/Developer/Dashboard`; the v5.88 `HEAD` tree contains 1,624 by the same
  count. This excludes anonymous closures and is not an AST inventory.
- The original `dashboard version` median was 56.7 ms. NYTProf found eager `Pod::Usage` loading taking 18.6 ms inclusive on that command. Subsequent lazy imports, lightweight version access, and validated-PWD work reduced the latest 15-run median to 31.486 ms (about 1.80× faster). `paths` measured 71.309 ms versus 93.3 ms (1.31×); `ps1` measured 83.641 ms versus 109.5 ms (1.31×). These are command-level gains, not per-subroutine proof.
- A 210,000-round PBKDF2-HMAC-SHA256 Perl implementation measured 284 ms median. OpenSSL through FFI measured 29.9 ms median with identical digest output: about 9.5× for this one routine.
- The shared HTML body escaper now uses a compiled XS byte loop for ordinary scalars, retaining Perl fallback behavior when no object is built and for overloaded references. A warning-free staged Docker MakeMaker build passed exact byte/Unicode/NUL/UTF-8/taint-flag parity tests. On 1 MiB inputs, the production XS helper measured 12.63× faster and complete instruction highlighting measured 9.53× faster than the Perl reference across 21 rotated samples. This is one targeted routine result, not an all-routine claim.
- `PathRegistry::all_paths` now reuses exact path identities only for one aggregate call. A red-first test verifies no cross-call staleness, and a 51-pair Docker benchmark kept exact 1,171-byte JSON parity while measuring 0.576 ms without reuse versus 0.424 ms with it (1.36× for that routine). This narrow gain is not an all-subroutine result.
- Collector-backed `/system/status` syncs now share one ordered indicator-root snapshot and decode each status file once per sync, invalidating writes/deletions and discarding the cache before the next request. Red-first Docker tests verify one root discovery, one physical read per indicator, next-sync freshness, and collector retirement. Across 15 alternating runs with 50 collectors and exact response-byte parity, latency fell from 9.203 ms to 2.689 ms per request (3.42×); NYTProf showed 15,100 to 100 root resolutions and 15,000 to 5,000 status-file reads over 100 requests. This workload-specific gain does not establish the 50× all-subroutine target.
- Nested-skill inventory with `include_disabled` no longer stats each top-level `.disabled` marker twice. Red-first Docker tests cover the one-check contract and empty input. Exact result parity held across 51 paired 50-skill runs (0.599 ms to 0.496 ms, 1.21×) and 31 paired 250-skill runs (3.089 ms to 2.585 ms, 1.19×). The current full Docker gate passed 264 files / 23,296 tests with 100.0% across all four `lib/` coverage metrics (47,375 detail rows); nine optional/environment-dependent tests explicitly skipped. Post-gate `perlsec` passed. This narrow result does not meet the 50× target.
- An alternating Docker control measured 25 cold `dashboard version` starts at 32.424 ms median and 25 bare Perl starts at 1.263 ms median. A 50× reduction from the v5.88 command median of 56.7 ms would be 1.134 ms, below the interpreter-only median. Therefore, cold-process command startup cannot satisfy 50× in this runtime; the resident-runtime candidate needs full freshness and parity proof. This command-level finding does not substitute for the all-subroutine objective.
- The 15-pair MCE scaling benchmark verified exact ordered output at 50, 250, 1,000, and 5,000 configs. Four workers with a fresh pool per size measured cold ratios versus serial of 0.21×, 0.90×, 0.97×, and 0.89×; warmed ratios were 0.92×, 1.18×, 1.13×, and 1.18×. MCE module import is excluded. Cold one-shot MCE was slower at all tested sizes, so this does not justify production integration or approach 50×.
- A three-second Docker FFI boundary probe measured a Perl path accessor at 12.43 million calls/second versus 5.58 million calls/second for native `getenv` (same returned value; FFI was about 2.23× slower). This is not a one-to-one implementation comparison, but it shows native-call overhead makes blanket wrapping of tiny routines counterproductive.
- An Inline::C/XS wrapper around the same OpenSSL call measured 31.0 ms warmed versus 32.4 ms through FFI. Inline::C generates XS glue; this is not a further meaningful speedup.
- MCE improved a synthetic ten independent 300 ms job batch from 3.001 s to 0.906 s using four workers. In a 50-file path-alias JSON workload with exact output parity, serial was 1.125 ms versus 1.440 ms with four MCE workers warmed; the first MCE call was 4.944 ms. Real collector startup must remain fail-fast and sequential, so these results do not justify a production MCE change.
- SPVM and SPVM::Digest::SHA were tested in the isolated Docker environment. A 30,000-iteration HMAC loop with a Perl/SPVM crossing each round was 4.5× slower than Digest::SHA XS. A benchmark-only PBKDF2 loop compiled wholly inside SPVM also preserved exact output but ran at 0.54× the Perl reference speed (522.992 ms versus 284.853 ms at 210,000 rounds); SPVM load/compile was 48.842 ms. Neither path is retained in the application. Memoizing mutable filesystem or password-derived results is unsafe without explicit validity/security guarantees. Perl's built-in `class` syntax remains experimental on the tested Perl 5.40.1 and emits warnings.
- A fresh five-run Docker comparison with optional SPVM/FFI paths enabled again preserved identical digests: Perl median 287.180 ms, OpenSSL FFI 30.868 ms (9.30×), and SPVM 512.355 ms (0.56× Perl speed). SPVM load/compile took 54.430 ms, excluded from routine medians. This repeat confirms neither native route reaches 50× for PBKDF2 and SPVM is slower than Perl.
- A fresh MCE-enabled five-run Docker inventory benchmark preserved exact order for 50–5,000 JSON configs. Warm MCE/serial ratios were 0.82×, 0.93×, 1.02×, and 1.05× with four workers; cold map setup ranged from 5.171 ms to 182.417 ms. MCE's maximum measured gain was 5%, so it does not justify production integration or satisfy the target.
- A fresh NYTProf map of the byte-identical 100-skill/20-saved-nav route ranked `_nav_items_html` highest among renderer routines. A red-first regression proved its page-id lookup unnecessarily created a full `as_hash` result; `PageDocument::id` now reads only the identifier. Focused tests pass 625 assertions, and nine alternating million-read samples measured 5.56× versus `as_hash->{id}`. The matched v5.88/current route measured 58.338089 versus 0.367992 ms/request (158.53×) with identical output. These are one accessor and one route fixture, not proof of the 50× target for every subroutine.
- A subsequent NYTProf profile ranked the common flat `welcome` identifier in `PageStore::_validated_page_id` at 4.52 ms across 300 calls. A red-first Docker regression proved the canonical single-segment ASCII case can avoid general normalization without changing validation of prefixed, nested, Unicode, reference, whitespace, or unsafe ids. The PageStore suite passes 216 assertions; nine alternating million-call samples measured 2.04× for the fast path. This remains a specific helper result, not 50× across the module.
- A new red-first-tested Docker benchmark compares Perl, FFI, and an Inline::C-generated XS wrapper at the production PBKDF2 work factor. All digests matched over five runs: 287.413 ms Perl, 31.073 ms FFI (9.25×), 31.379 ms Inline::C/XS (9.16×); Inline compilation cost 610.263 ms. Inline::C provides no additional gain over FFI.
- A request-boundary Memoize test and benchmark preserve exact path identities and detect symlink retargeting. For 1,000 unique paths repeated twice, 15 Docker runs measured 7.705 ms uncached, 4.246 ms with the local request hash (1.81×), and 5.006 ms with Memoize (1.54×). Memoize is not adopted because its wrapper is slower than the current scoped hash.
- A resident path-context prototype reuses PathRegistry/Config while refreshing cwd, aliases, inventory, config files, and user Folder.pm results for every request. Exact output parity and config replacement, changed Folder.pm environment values, skill addition, and skill deletion all passed. The latest 50-skill, nine-run Docker recheck measured 23.184 ms for a fresh helper versus 3.525 ms resident (6.58×); an earlier check measured 6.41×. This remains a research prototype and does not approach 50×.

## Fresh 2026-10-14 benchmark confirmation

Two parity-checked Docker benchmarks were rerun on the current checkout. The
legacy parser was 116.72× faster than the v5.88 linear allowlist scan for
1,001 CODE sections across 21 alternating runs, with exact canonical JSON
parity. Static-body rendering was 90.04× faster than the v5.88-equivalent
Template Toolkit path across 21 alternating runs of 5,000 renders, with exact
Unicode output parity. Focused PageDocument and PageRuntime tests passed 105
assertions. These are results for two routines and specific inputs, not proof
of the 50× target for every subroutine.

## Root cause and practical meaning

NYTProf points to startup/module loading and filesystem/environment discovery in light commands, and to PBKDF2's repeated Perl loop in authentication. These have different remedies; no single mechanism speeds arbitrary subroutines. Many routines are getters, I/O-bound, mutating, or sequential. Applying a worker pool, cache, or native boundary indiscriminately can slow them down or change behavior.

The literal target is not currently met. A bare Perl process took 1.032–1.268 ms in the same container. A 50× speedup for `dashboard version` would require about 1.134 ms total, near that interpreter-launch floor. The 1,648-current-routine target also lacks a workload and before/after proof for each individual routine. This evidence disproves 50× for that CLI invocation on this runtime, but does not rule out 50× for some individually selected slow function.

Alternative compiler research found that B::C reduces startup parsing but not runtime cost, B::CC documents behavioral differences, and XS::JIT compiles hand-written C rather than translating Perl functions. Its published synthetic example shows 1.36× versus Inline::C, not the requested 50×. These routes are not retained as a whole-project implementation.

## Solution implemented so far

1. Add a lazy OpenSSL FFI adapter for helper-password PBKDF2, preserving the algorithm, salt, rounds, output, fallback, and visible errors.
2. Defer `Pod::Usage` loading until usage rendering is actually needed.
3. Do not parallelize collector startup because it changes tested fail-fast behavior. Do not retain duplicate Inline::C/XS or SPVM paths without a demonstrated gain.
4. Reuse the state-root account name only while the exact account-related environment values remain unchanged. In an isolated no-username environment, this reduced passwd lookups from 80 to 1 over 20 requests; the profiled route moved from 69.7 ms to 58.3 ms, which is an edge-case measurement, not a typical-route claim.
5. Wire one `IndicatorStore` into both `app.psgi` and its `Prompt`. A red-first test reproduced the missing-dependency startup failure; the corrected bootstrap now serves `/system/status` through its actual PSGI coderef in Docker.
6. Skip repeated state metadata writes only when the file is verified regular, owner-owned, mode 0600, and byte-identical; recreate missing data, repair stale/loose data, and reject symlinks. The actual 20-request route profile improved 4.25x under NYTProf, while the whole-project 50x target remains unmet.
7. Build the high-volume HTML escaper as a small XS extension, retaining the Perl reference for source-only runs and overloaded-reference inputs. The built helper and full instruction-highlighting benchmark preserve exact output; on 1 MiB input the production backend measured 12.63× and 9.53× respectively.

## New route under test: keep a validated runtime resident

A Docker prototype tested reusing the Perl runtime and path/config context for repeated `dashboard paths -o json` requests. Ten fresh CLI executions averaged 84.412 ms each. The same handler in a resident process took 5.636 ms/request while rebuilding aliases each time. With aliases loaded once into a reused context, recomputing `all_paths` and JSON each request took 1.018 ms/request and matched the current CLI's JSON output byte-for-byte (981 bytes), an experiment-level 82.9× reduction. A second prototype added a compiled C client and resident Perl Unix-socket server; 100 separate client launches averaged 0.514 ms/request and returned exactly the current CLI output, an experiment-level 164× reduction. This makes a persistent runtime a credible route to at least 50× for repeated requests.

It is not a shipped fix or a complete Problem 48 result yet. A synthetic Docker mutation check showed integer-second `stat` can miss a same-second directory addition; a high-resolution `Time::HiRes::stat` prototype detected config replacement, new top-level/nested skills, a new runtime layer, and changed environment. Deletion, disabled markers, symlinks, arbitrary files used by user `Folder.pm`, cross-platform behavior, refreshed response parity, and the high-resolution check's per-request cost remain unproven. This is targeted context reuse with explicit invalidation, not unrestricted memoization of mutable filesystem state.

## Remaining plan and gates

Continue profiling and identify any additional real hot path whose measured work could plausibly exceed the requested threshold; write a failing regression test before changing it. For each candidate, compare against the v5.88 behavior and benchmark fixed inputs repeatedly in Docker, then rerun functional/error-path tests. After the PathRegistry identity-scope change, the full Docker coverage gate passed 264 files / 23,292 tests with 100.0% statement, branch, condition, and subroutine coverage across `lib/` (47,360 detail rows). Nine environment/tooling-dependent tests skipped with explicit reasons. The SPVM fixture separately passed five assertions in the benchmark container with optional dependencies installed, and the required post-gate `perldoc perlsec` check succeeded. Security, integration, dependency, release, image, blank-install, and git delivery gates are still pending.

## Expected outcome

The honest evidence-backed outcome is faster measured hot paths with unchanged results and contracts. Current measured improvements include 1.80× for `dashboard version`, 1.31× for `paths`, 1.31× for `ps1`, 9.5× for PBKDF2, and 12.63× for the large-input HTML body escaper. Static template rendering and legacy section parsing exceed 50× only for their tested workloads. These measurements do not prove the stated 50× all-subroutine requirement; do not describe Problem 48 as complete unless additional proof changes that conclusion.

The latest full Docker verification passes 274 files / 24,063 tests with 100.0% statement, branch, condition, and subroutine coverage across `lib/` (47,861 detail rows and no stale uncoverable annotations). This closes the coverage gate for the current tree, not the 50× speedup requirement for every subroutine.

## How to prove it

- Run `d2 docker compose ... prove ...` in the isolated Problem 48 test project; preserve exact test output and container logs.
- Use NYTProf on representative real command paths and production routines; keep test-harness time separate from application time.
- For every claimed optimization, benchmark the same input and Perl/container against v5.88 and the candidate implementation, verify output parity, and report repeated-run medians.
- Demonstrate each of the 1,648 named routine speedups individually if retaining the literal “every subroutine” claim. The current measurement set does not do this.
- Run the remaining repository delivery gates before build/commit, including security, integration, dependency, version alignment, build/install, Docker image, and commit verification.

## Coverage status update (2026-10-14)

This update supersedes the earlier coverage shortfall recorded above. After
the PathRegistry identity-scope change, the full Docker run passed 264 files /
23,292 tests. The canonical gate reports 100.0% statement, branch, condition,
and subroutine coverage across `lib/` (47,360 detail rows, no stale
uncoverable annotations). Nine environment/tooling-dependent tests were
skipped with explicit reasons; the optional SPVM test separately passed all
five assertions in the benchmark container, and the required post-gate
`perldoc perlsec` check succeeded. The 50×
per-subroutine requirement and remaining delivery gates are still open.

## Latest gate after MCE benchmark addition (2026-10-14)

The full Docker test gate passed 265 files and 23,316 tests. Statement, branch,
condition, and subroutine coverage each measured 100.0% across `lib/` (47,375
detail rows). Nine optional/environment-dependent files and three MCE-only
assertions reported explicit skips; the focused MCE-enabled Docker test passed
11 assertions. Post-gate `perldoc perlsec` succeeded (29,990 bytes). This does
not demonstrate the 50× performance target.

## Resident-cache freshness evidence (2026-10-14)

Focused Docker tests now verify that reused PathRegistry/Config objects see
skills added or deleted between inventory scopes, creation/removal of
`.disabled` markers, replacement skill-config bytes, and runtime symlink
retargeting. The `Folder.pm` alias test also confirms that repeated calls
reevaluate user-defined methods after an environment value they read changes.
The two focused suites passed 326 assertions in total. These results establish
freshness of the existing readers for these mutations, not correctness or
performance of a persistent resident cache. Problem 48 remains open.

## Latest evidence update (2026-10-16)

Two additional saved-page route optimizations preserve the exact HTTP 200
response (10,042 bytes; SHA-256
`5b217655b90ff66db1d2fdb5a9d3e4aa6a4d4f05f073f1d7f9fc6ec40746d212`). Literal
raw nav skips runtime preparation and canonical-instruction serialization;
dynamic nav still uses the normal Template Toolkit/CODE path. A request-local
dashboards-root realpath map avoids repeated root resolution while retaining
per-candidate containment checks, secure no-follow opens, and fresh roots on
the next request. The matched route median moved from 0.927038 to 0.673630
ms/request across the intervening changes. A fresh matched 21-sample run
measured 3.758640 ms/request on v5.88 and 0.673630 currently (5.58x for this
fixture). It remains well below 50x.

The clean Docker coverage gate for the current code passed 283 files / 24,251
tests, with 100.0% statement, branch, condition, and subroutine coverage across
`lib/` (49,149 detail rows; no stale annotations). The required web/update,
static-file, and SSL security trio passed 466 assertions. The current benchmark
results and prior method inventory still do not prove 50x for every named
subroutine, and release/integration delivery gates remain open.
