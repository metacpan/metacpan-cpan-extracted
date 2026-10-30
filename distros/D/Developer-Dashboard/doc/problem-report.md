# Problem Report

Problems are listed in numeric order. This file is the current status index;
`doc/problem-report.txt` retains the historical investigation and release log.
Statuses distinguish functional verification from release/commit delivery.

### Current Problem 48 optimization status (not a problem-list entry)

The fresh profile identified repeated pretty-JSON construction in the
configuration snapshot environment signature. The method now builds a
versioned length-prefixed internal comparison key while preserving distinct
missing, undefined, and defined environment values. Red-first tests in
`t/03-web-app.t` pass (527 assertions); nine alternating 30,000-call Docker
samples measured a 1.34x helper improvement. End-to-end route impact is not yet
established. Seven paired 200-request route samples preserved HTTP 200 and the
same response hash; medians differed by 2.2%, but only four pairs favored the
new signature and per-pair ratios ranged from 0.89x to 1.06x. No stable
route-level gain is claimed. The all-subroutine 50x target remains open.

The warmed route profile showed 100 `runtime_root` calls and 600
`runtime_layers` calls across 100 requests. `runtime_root` now reuses the
deepest root only within the active operation snapshot; red-first tests verify
unscoped calls still see filesystem changes. Nine Docker microbench samples
measured 1.72x accessor speedup, but paired end-to-end route samples showed no
stable improvement, so no route-level gain is claimed.

NYTProf found host normalization in `_top_context_html` among repeated costs.
Characterization tests pin its existing lowercase-scheme and unsupported-scheme
semantics. Prefix checks plus one `index` truncation measured 1.32x faster over
nine alternating Docker samples with exact helper output parity. The matched
saved-page route response remained byte-identical, so no route gain is claimed.
This is one measured hotspot improvement; Problem 48's all-subroutine 50x
objective remains open.

An environment-signature memoization candidate was also tested against the
fresh profile's `_request_config_snapshot` cost. Nine alternating Docker runs
measured the candidate at 0.85x the existing JSON implementation (slower), so
it was removed instead of retained. A separate red-first regression exposed a
stale prompt-summary case: when `/system/status` synchronized changed collector
indicators before the next page render, that render could reuse old summary
text. Collector sync now invalidates the cached summary; the Dancer route and
status-cache tests pass after the fix.
The combined focused Docker rerun passed 1,101 assertions. The warmed route
measured 0.362170 ms/request afterward with exact 19,341-byte response parity;
the timing is within variation and is not a performance claim.
The subsequent full Docker coverage gate passed 285 files and 25,293 tests with
100.0% statement, branch, condition, and subroutine coverage across `lib/`
(51,645 detail rows; no stale uncoverable annotations). Optional browser,
Windows QEMU, CPANTS, POD, and audit-tool checks were skipped because their
external requirements were unavailable; the 50x all-subroutine objective
remains open.

Release verification found that the 6.00 tarball included the generated
`cover_db-p48-focus` database: the gather/prune patterns handled the default
name and underscore suffixes but not hyphen suffixes. Red-first assertions in
`t/15-release-metadata.t` reproduced the missing coverage for both named
patterns and the stale built archive. Gather, prune, and manifest-skip rules
now cover hyphenated and underscored names; archive-level assertions reject
any matching member. The rebuilt 6.00 archive contains none, `t/15` passes
5,756 assertions, and the blank-container `cpanm` installation plus integration
run passes.

Expected outcome: exact existing HTML bytes and UTF-8 flags, with dense long
text using the native body escaper and plain/short text avoiding its dispatch
overhead. The profile identified `PageDocument::_html`'s repeated substitutions
as a hot helper. A red-first Docker test first failed because the method did
not delegate dense text to the shared escaper. The implementation now selects
the XS path only for text at least 64 characters long with four or more body
metacharacters in its first 16 characters; plain and sparse text keeps the
original Perl substitutions and double-quote behavior. Steps to reproduce and
verify: `d2 docker compose exec dev prove -lv t/72-pagedocument-coverage.t`,
then run the compiled-XS microbenchmark in the Problem 48 research log. The
fallback and compiled-XS focused suites pass; exact byte and UTF-8 parity was
verified. Seven alternating Docker samples measured 11.29x for a 384-character
dense fixture, 1.09x for a short plain value, 1.06x for long plain text, and
0.94x for short quote-heavy text (near parity/no material improvement). The
source-only fallback also preserved bytes and measured 1.08x for a short plain
value, 0.85x for short quote-heavy text, 1.11x for long plain text, and 1.34x
for dense input. No route-level speedup is claimed. Problem 48's 50x target
for every subroutine and full delivery cycle remain open.
The first plain MakeMaker `make` failed while fixing the `d2` script because
`/root/perl5` supplied a flat-architecture Storable binary mismatched with
system Perl 5.40.1. The extension then compiled successfully when the build
was run with only the active versioned local-lib path in `PERL5LIB`; focused
compiled-XS suites passed. This resolves the reproduction for the experiment,
not the broader blank-container install/build gate or cross-platform build
verification.

The current PageStore reader also avoids three legacy-icon repair expressions
when its decoded instruction contains no U+FFFD. Docker tests preserve each
repair context and unrelated replacement text. Seven alternating direct
samples measured 1.32x–1.98x on ordinary input, while malformed icon repair
measured 0.93x; the exceptional repair path is slightly slower. A fresh matched
100-skill/20-saved-nav route benchmark retained HTTP 200 and exact 18,792-byte
response parity: the latest rerun measured v5.88 at 69.971821 ms/request,
current source-only at 0.717950 ms/request (97.46x), and compiled XS at
0.773010 ms/request (90.52x). The compiled route sample was slightly slower
than source-only; no XS route gain is claimed. These are route-specific
results. Problem 48 remains in progress because the
all-subroutine 50x target and remaining full delivery gates are unproven.

The first blank Docker tarball-install run exposed two packaging-only test
assumptions: a dispatcher path-filtering assertion required optional
`FFI::Platypus`, and the saved-page benchmark expected a fixed response hash
that changed under the extracted distribution root. The reproduced failures
were fixed by injecting the existing deterministic watcher in the unit test
and comparing route modes to the same run's default hash. The focused Docker
rerun passes 425 assertions; a rebuilt tarball install is still required to
close this gate. Problem 48 remains in progress.

The 5.99 blank Docker `cpanm` rerun then exposed two benchmark assertions
that required native watcher-backed scan and containment counts. In the blank
environment FFI is intentionally absent, so the correct fallback returned
identical HTML but scanned nine times and performed 36 containment checks.
The route benchmark now prints actual watcher availability and snapshot hits,
has a `--no-native-watch` control, and conditions only optimization-count
assertions on backend availability; response parity remains required in both
modes. Focused Docker suites pass 432 assertions. The rebuilt 6.00 tarball
install is not yet verified; Problem 48 remains in progress.

The follow-up security gate then found a related runtime failure: skill-page
requests can change the working directory before the optional watcher is first
loaded, causing a relative `@INC` entry to miss the module and return HTTP 500.
The app and skill dispatcher now resolve the lazy module from their captured
absolute source locations and preserve an already-loaded `%INC` entry. The
existing Dancer route regression reproduced the 500 before the fix; focused
Docker tests now pass 722 assertions across `t/08`, `t/41`, and `t/673`.
The rebuilt 6.00 tarball install remains outstanding.

The latest full Docker coverage gate passed all 285 test files and 25,229 tests
with statement, branch, condition, and subroutine coverage at 100.0% across
`lib/` (51,571 detail rows; no stale uncoverable annotations). The final run
includes red-first assertions for both undefined-input guards in the new
single-section parser. The prior watcher warning was captured by a red-first assertion;
malformed optional page lists are rejected before identity checks, and mocked
fallback scenarios clear the saved HTML snapshot. The new single-section
parser was also tested red-first: the focused suite failed because the fast-
path helper was absent, then passed after implementation.
Reproduction and verification commands are:

```sh
d2 docker compose exec dev prove -lv t/72-pagedocument-coverage.t
d2 docker compose exec dev perl script/problem48-saved-page-route-benchmark --nav-fragments 20 --skill-nav-fragments 100 --iterations 100 --runs 9
```

The parser preserves the same result on six representative inputs. Nine
alternating 500,000-call measurements for a simple TITLE/HTML input were
1,860.772 ms before and 993.799 ms after (1.87x). A current route rerun kept
HTTP 200 and the exact response hash at 0.340998 ms/request, but it was not
paired with a pre-change build and is not attributed to this parser. Problem
48's universal 50x target and remaining delivery gates remain open.

The source-only `HtmlEscape` fallback also now performs its three substitutions
in the public routine rather than dispatching through a second helper. Red-first
Docker coverage failed on the old helper call; source-only and compiled-XS
tests now pass for escaped strings, undef, and overloaded references. Twenty-
five alternating 500,000-call measurements for ordinary text improved from
175.998 ms to 135.123 ms (1.30x) in the source-only fallback. This is not a
route-level result and does not meet the 50x target. The first gate run found
one uncovered defined-input branch in the reference helper; a regression was
added and the complete rerun passed all four lib/ coverage metrics at 100.0%
(51,571 detail rows). Problem 48 remains in progress.

The current-source 100-skill/20-saved-nav route was rerun in Docker with 100
requests per sample over nine samples. It returned HTTP 200 and the same
18,792-byte response hash as the v5.88 baseline; current measured 0.420060
ms/request versus 135.065870 ms/request (321.54x for this route only). This
cumulative route measurement is not attributed to the fallback change and does
not establish the required 50x for every routine. A NYTProf-led attempt to
shorten `PageStore::_normalized_page_id` was rejected: a boundary regex measured
0.45x, while a character-boundary check measured 1.00x against the existing
method. No ineffective code was retained.

## Problems 1–11: Initial dashboard and skill runtime

### Problem 1: Forward saved bookmark URLs and merge request query parameters (2a09c53b) — done
Saved URLs redirect while preserving saved query keys, allowing request keys to override matching values and append new ones. Regression coverage: `t/03-web-app.t`, `t/104-skilldispatcher-coverage.t`, `t/131-bookmark-url-encoding.t`.

### Problem 2: Resolve skill-aware Template Toolkit includes (2a09c53b) — done
Skill pages can include local dashboard fragments and explicit skill dashboard paths. The include allow-list now covers the owning skill dashboard root. Regression coverage: `t/08-web-update-coverage.t`, `t/20-skill-web-routes.t`.

### Problem 3: Render supplied data in saved Ajax code templates (2a09c53b) — done
Ajax handler source is rendered with its supplied Template Toolkit data before it is stored and executed. Regression coverage: `t/12-legacy-helper-coverage.t`, `t/85-zipper-coverage.t`.

### Problem 4: Keep dashboard-owned init helpers private (f561a7e0) — done
Built-in staged helpers belong under `cli/dd`, separate from user `cli` files. Historical pre-fix and current Docker staging checks are recorded in the text audit; `t/30-dashboard-loader.t` covers the current behavior.

### Problem 5: Inherit nested skill CLI environment and runtime layers (2a09c53b) — done
Parent-to-leaf skill `.env`/`.env.pl` and DD-OOP runtime layers reach the nested command. Regression coverage: `t/19-skill-system.t`, `t/87-envloader-coverage.t`, `t/104-skilldispatcher-coverage.t`.

### Problem 6: Add the owning skill `lib/` to `@INC` (2a09c53b, bc516b29) — done
The active skill library is first in `@INC` for CLI and dashboard CODE execution. Regression coverage includes actual Docker CLI and dashboard requests: `t/20-skill-web-routes.t`, `t/76-web-dancerapp-coverage.t`, `t/104-skilldispatcher-coverage.t`.

### Problem 7: Complete `cli/__init__` by the bare skill name (2a09c53b; nested follow-up 5.36) — done
Completion exposes `foo`, not `foo.__init__`; nested initializers resolve deepest-first without shadowing explicit commands. Docker regression: `t/39-cli-suggest-complete-coverage.t`, `t/104-skilldispatcher-coverage.t`.

### Problem 8: Load invocation-directory env files outside home/project roots (2a09c53b) — done
`d2` loads the current directory `.env`/`.env.pl` independently of home/project ancestry. Pre-fix and current checks are recorded in the text audit; regression coverage: `t/06-env-overrides.t`, `t/87-envloader-coverage.t`, `t/79-perlenv-coverage.t`.

### Problem 9: Remove the confusing `d2 ticket` alias (2a09c53b) — done
`workspace` is the public command and `ticket` is no longer advertised as a competing command. Regression coverage: `t/39-cli-suggest-complete-coverage.t`, `t/69-cli-complete-coverage.t`, `t/91-cli-ticket-coverage.t`.

### Problem 10: Resolve arbitrarily nested skill CLI names (regression guard 2a09c53b) — behavior verified; supplied example inconsistent
An equivalent four-segment command resolves in Docker. The original example names `a.b.c.d` but omits the `c` skill directory; the discrepancy and audit are documented in `doc/problem-report.txt`.

### Problem 11: Let invocation cwd env override skill defaults (2a09c53b) — done
Environment precedence applies cwd values after inherited skill defaults. Regression coverage: `t/20-skill-web-routes.t`, `t/06-env-overrides.t`.

## Problems 12–19: Skill aliases, Docker, and dashboard behavior

### Problem 12: Resolve skill-qualified workspace aliases (7b0974e6; follow-ups 5.44, 5.47, and 5.48) — done in 5.48
Configured and Folder.pm aliases work at nested depths with `workspace -c`. The current follow-up maps dotted logical workspace refs such as `ch.docker` to tmux's underscore-normalized session name, verifies session ownership, and confirms duplicate-create races before reuse. Docker tests: `t/91-cli-ticket-coverage.t`; exact behavior is recorded in `doc/problem-report.txt`.

### Problem 13: Import DataHelper in saved-page CODE automatically (7b0974e6) — done
Dashboard CODE receives standard DataHelper imports without repeated declarations. Regression coverage: `t/76-web-dancerapp-coverage.t`, `t/99-pageruntime-coverage.t`.

### Problem 14: Load skill Dashboard extensions at web startup (7b0974e6; refined 874d8df6) — done
Skill `lib/Dashboard.pm` routes/settings load once at startup and run behind dashboard authorization. Regression coverage: `t/20-skill-web-routes.t`, `t/30-dashboard-loader.t`, `t/76-web-dancerapp-coverage.t`.

### Problem 15: Support opt-in Docker development Compose overlays (b5e7ac4a) — done
Base Compose files load consistently; development overlays require the marker and disable markers exclude a service. Regression coverage: `t/05-cli-smoke.t`, `t/10-extension-action-docker.t`, `t/94-dockercompose-coverage.t`.

### Problem 16: Merge Folder.pm aliases into path lookup and completion (11aaaa1f) — done
Skill Folder methods and `__list__` provide read-only aliases while config aliases remain writable and take precedence. Regression coverage: `t/90-cli-paths-coverage.t`, `t/97-pathregistry-coverage.t`, `t/205-skill-depth-alias.t`.

### Problem 17: Report present-but-empty skill dependency manifests accurately (6dcbfe35) — done
An existing empty manifest is not reported as missing. Regression coverage: `t/19-skill-system.t`, `t/102-skillmanager-coverage.t`.

### Problem 18: Inject bookmark HEAD content into the document head (6dcbfe35) — done
Bookmark `HEAD:` content is parsed, serialized, and rendered inside `<head>`. Regression coverage: `t/72-pagedocument-coverage.t`.

### Problem 19: Preserve skill Dancer hooks, variables, and startup loading (874d8df6) — done
Skill hook variables are visible in page/Ajax CODE, explicit response headers survive defaults, and Dashboard extensions load once at startup. Regression coverage: `t/20-skill-web-routes.t`, `t/30-dashboard-loader.t`, `t/76-web-dancerapp-coverage.t`.

## Problems 20–29: Coverage, runtime, and CLI

### Problem 20: Bring repository-wide Perl coverage to 100% — complete; verified 2026-10-03
The four-metric library coverage gate has reached 100.0% statement, branch, condition, and subroutine coverage. This problem is distinct from coverage work performed during other numbered cycles; current verification evidence is appended below.

### Problem 21: Discover both runtime roots together (23981132) — done in 5.25; reverified in 5.30
`.d2` and `.developer-dashboard` participate independently at each active layer with documented lookup/write precedence. Docker regression: `t/25-d2-alias.t`.

### Problem 22: Keep `ddfile.local` dependencies private to their owning skill (23981132) — done in 5.25; reverified in 5.30
Local dependencies install under the owner skill's `skills/` tree with traversal/symlink protections. Docker regression: `t/102-skillmanager-coverage.t`.

### Problem 23: Remove PAX from Developer Dashboard (bb14a6fe) — done in 5.29; reverified in 5.30
The compiler/cache/helper and PAX-specific release path were removed; standard commands and archive contents were checked. Docker regression: `t/264-pax-removal-contract.t`.

### Problem 24: Require patched Pod::Text for CLI help rendering — done in 5.34
The declared dependency floor prevents clean installs from selecting the vulnerable Pod::Text release. CI advisory and blank-container package evidence are recorded in `doc/problem-report.txt`; regression coverage: `t/108`, `t/181-podlators-security-floor.t`.

### Problem 25: Keep Dashboard help on internal CLIs and preserve external CLI help — done in 5.53
Help metadata and completion include nested actions/options; delegated grep, Docker Compose, and dotted skill-command help pass through to their owning CLIs. The private `skills _exec` dispatch sentinel is not treated as a public help action. Focused Docker regressions passed, including native `--help`, `-h`, and `help` pass-through. The full D2 suite passed 258 files / 22,403 tests. The 5.53 blank-environment integration run passed with plain `cpanm` test execution. The 5.53 image was built and checked with both `d2 version` and `Developer::Dashboard::VERSION` reporting 5.53. The configured base image initially exceeded the overlay mount-option limit; a disposable flattened base allowed the required Compose build. The base also carried an older module at an unversioned path, so the disposable image build removed only that stale module copy before installing the 5.53 archive. No repository Dockerfile change was retained. Commit `1dc5c062` had narrowed `.gitignore` to `.claude/`; the required `nytprof.out`, `nytprof/`, `.worktrees/`, and `dogfood-output/` patterns have been restored alongside it, and the release metadata gate passes. Tests include `t/265-cli-help-completion-contract.t` and `t/266-cli-help-dispatch.t`.

### Problem 26: Preserve full branch labels in `ps1` across all shells — done in 5.37/5.38
Branch names retain slashes; `origin/` is removed only when an equivalent local branch exists. Full evidence is in the historical report.

### Problem 27: Restore `of` content grep and complete Perl `@INC` lookup (78d6573d; package follow-up) — done
`d2 of grep` searches content safely via argv and module lookup traverses every `@INC` root. Focused tests cover matches, errors, print mode, editor dispatch, and multiple roots.

### Problem 28: Resolve collector working-directory path aliases (78d6573d) — done
Collector `cwd` accepts config aliases and skill Folder.pm aliases, with config-first precedence. Regression coverage: `t/103-collectorrunner-coverage.t`.

### Problem 29: Determine whether stopping a collector stops its child processes — investigation pending
The requested Docker reproduction and verified stop-propagation result are missing from the tracked report. Do not infer process-tree behavior from dispatcher shutdown; complete an isolated container investigation before marking done.

## Problems 30–39: Collector, marker, completion, and Compose behavior

### Problem 30: Repair config.json collector cron scheduling — done in 5.44
Five-field cron expressions support names, lists, ranges, steps, crontab day matching, and per-minute deduplication; missing/invalid schedules fail visibly. Regression coverage: `t/103-collectorrunner-coverage.t`.

### Problem 31: Honor Docker service markers at every layer — done in 5.44/5.45
Markers are discovered and removed across active service layers; newly written markers use the selected home runtime. Regression coverage: `t/10-extension-action-docker.t`, `t/361-dockercompose-coverage.t`.

### Problem 32: Separate command/path completion and make cdr completion responsive — done in 5.48
Root command completion no longer mixes path aliases; `workspace` completion includes configured and Folder.pm aliases. `cdr` completion lists direct children and narrows one directory level per entered term. Docker regressions: `t/69-cli-complete-coverage.t`, `t/90-cli-paths-coverage.t`; measured fixture returned 40 candidates in 0.131 seconds.

### Problem 33: Keep an unregistered first `cdr` word as a search pattern — done in 5.48 (existing behavior regression-guarded)
If the first `cdr` word is not a registered alias, it remains a search term and participates in later TAB narrowing. Current implementation already preserves it; new targeted assertions in `t/90-cli-paths-coverage.t` verify resolution and `t/69-cli-complete-coverage.t` covers completion behavior. No production code change was needed for this report item.

### Problem 34: Limit automatic Compose services to the local Compose project — implementation done in 5.48/5.54/5.55; runtime verified
When cwd contains a supported Compose file, it is the base and only runtime services declared by that file are automatically merged. Explicit service selection remains possible, and runtime discovery is unchanged when no local base exists. Follow-up: operational commands previously lost the invocation project directory after merging layers into a temporary file. The final command now retains that directory, and explicit `--project-directory` remains authoritative. A further audit found the public helper called `resolve()` and directly executed the unresolved `-f` stack, bypassing the materialization logic entirely; the earlier `run()` tests therefore did not cover the real CLI path. The helper now routes non-dry-run operations through a streaming materializing runner, which holds the merged file until Compose exits. Regression tests cover the actual helper dispatch and `up`, `build`, and `down` execution, including merged-file availability during execution. An isolated real Compose project and the 5.54 release evidence are recorded in `doc/problem-report.txt`; this 5.55 follow-up was verified with Docker Compose stubs in the isolated dev container because that container does not include the Docker CLI. The ignored local Dockerfile/version caveat from the 5.54 image build remains recorded in the historical evidence below.

### Problem 35: Configure a real Dist::Zilla releaser for `dzil release` — done in 5.50
`dist.ini` now configures `Dist::Zilla::Plugin::UploadToCPAN`, so an explicit `dzil release` has a real PAUSE upload action. The release-metadata test failed before the stanza and passes after it; `dzil authordeps` lists the plugin, Dist::Zilla resolves it as a `-Releaser`, and `dzil build` succeeds and produces `Developer-Dashboard-5.50.tar.gz`. The matching Docker image built successfully and reports version 5.50. A fresh blank Docker environment installed the tarball with `cpanm` (without `--notest`) and completed its full integration script. The release command was not run, so no package was uploaded.

### Problem 36: Merge project and home skill commands in shell completion — done in 5.53
When a project and home runtime both contain a skill with the same name, `d2 <skill>.<TAB>` includes commands from both layers, with shared command names listed once. The isolated Docker regression `t/804-skill-completion-layer-merge.t` failed before the fix because completion resolved each discovered skill name back to only the winning project root; it now enumerates all participating skill roots. The full D2 suite passed 258 files / 22,403 tests, including the layered-skill completion regression. Earlier 5.52 all-metric coverage passed 258 files / 22,897 tests with 100.0% statement, branch, condition, and subroutine coverage (45,356 detail rows). Version 5.53 is built, the blank-environment integration run passed, and the runtime image reports 5.53.

### Problem 37: Avoid false watchdog restarts during cron quiet hours — implementation and package verification complete in 5.56
Reproduction: with a cron collector configured as `0 7-8 * * *`, seed its last completed execution as old while the scheduler loop remains live with a fresh heartbeat, and set its watchdog restart count to the threshold. Before the fix, the watchdog stopped the healthy loop, incremented the count, and raised `attention_required` with “stopped unexpectedly too many times within 300 seconds.” The warning was triggered because the watchdog interpreted expected time between cron runs as stalled execution. Cron collectors now use scheduler heartbeat age for stall checks; interval collectors continue using last execution progress. Focused Docker tests passed (2 files / 1,005 assertions); the instrumented full suite passed (258 files / 22,497 tests) with 100.0% statement, branch, condition, and subroutine coverage. Required security web tests passed (3 files / 459 tests). `dzil build`, `d2 docker.images.build`, and blank-environment `cpanm` integration all passed. The image's existing `/root/perl5` 5.54 module shadows its newly installed 5.56 system-library module, so the running-image version probe remains a documented environment caveat, not a Problem 37 code fix. See the detailed chronology in `doc/problem-report.txt`.

## Cross-problem verification note (2026-10-03)

Problems 12, 32, 33, and 34 were verified in the isolated `dd-problem32` Compose
development container. Focused regressions passed: 3 files / 359 assertions
(`t/90`, `t/91`, `t/94`); `t/69` passed 71 assertions after adding the missing
defensive-branch case; `t/590` passed 17 assertions after its mocked resolver
was updated to return production `compose_root`. The final 5.48 instrumented
suite passed 257 files / 22,372 tests. The four-metric gate exited successfully
with 100.0% statement, branch, condition, and subroutine coverage (45,335
detail rows; no stale annotations). Devel::Cover printed warnings for
temporary skill fixture sources removed during tests; the gate returned
success, but the run is not described as warning-free.

Problem 12's duplicate tmux-session reproduction and all four problems' final
Docker checks are captured in the detailed chronological audit in
`doc/problem-report.txt`. Functional and coverage verification are complete.
`dzil build` produced `Developer-Dashboard-5.48.tar.gz`; the matching Docker
image built and reported `d2 version` 5.48. The blank-environment integration
container installed that tarball with `cpanm` (without `--notest`) and completed
its full integration script successfully. The 5.49 documentation refresh
changed only release metadata and report content. Its full Docker coverage rerun
passed 257 files / 22,732 tests and the four-metric gate at 100.0% across all
metrics (45,335 detail rows, no stale annotations); temporary fixture digest
warnings remain visible. `dzil build` produced `Developer-Dashboard-5.49.tar.gz`;
`d2 docker.images.build` completed and a fresh image returned `d2 version` 5.49.
The blank-environment Compose run installed that archive with `cpanm` (without
`--notest`) and the full integration script passed. The release gates and
problem fixes are committed; no push was performed.

### Problem 38: Normalize merged Docker Compose YAML encoding — done (5.63)
Expected: every Docker Compose operation first materializes the effective base and overlays with `docker compose config`, then runs the requested verb against that merged file. Re-audit found a second root cause after the earlier fixes: `resolve()` parsed each local base with `YAML::XS::LoadFile` before materialization, so an isolated Windows-1252 byte in source `compose.yaml` failed with `invalid leading UTF-8 octet` before Compose could produce its merged config. A red-first Docker regression writes a raw `0xA3` into a local base, reproduces that failure before any Compose invocation, then verifies the fix uses a normalized in-memory copy for service discovery, leaves the source file untouched, runs `config` first, and passes a valid UTF-8 merged file to the requested operation. The zero-explicit-file operation-order case and all config/up/down/build/ps/logs materialization paths remain covered; non-Compose commands stay direct. Docker coverage passed 258 files / 22,550 tests with statement, branch, condition, and subroutine metrics all 100.0% (45,519 detail rows, no stale uncoverable annotations). The focused release/Compose tests passed 5,965 assertions and the focused web security trio passed 459. `dzil build`, image build/version verification, and blank-environment `cpanm` installation without `--notest` plus its full integration script passed. The coverage image lacked optional browser/QEMU/kwalitee tools and `cpan-audit`; those checks were skipped by the gate. Devel::Cover emitted visible warnings for temporary fixtures removed before report digestion. Final release metadata is 5.63 because the image build guard rejects reusing 5.62; the original `/tmp/here.yml` was not read or used as a fixture.
### Problem 39: Numbering gap — no problem description recorded (status: unassigned)
The supplied problem sequence and repository records contain Problem 38 followed by Problem 40, with no Problem 39 description, capture, expected outcome, or implementation request found. This entry records the gap without inventing a bug or claiming a fix. If Problem 39 was assigned elsewhere, its source report is needed before this slot can be classified further.

## Problems 40–44: Compose and runtime environment behavior

### Problem 40: Resolve the base Compose service list before loading service overlays — done (5.65)

Expected: for every real Compose operation, run `docker compose config` first
using the local base and configured non-service layers. Parse that resolved
output's `services` map, then search active home, project, and nested-skill
Docker config roots for only those service names. Apply disabled and
development markers before materializing the selected overlays and executing
the requested operation. Explicit `--project-directory` and user `-f` inputs
must be preserved without relying on a calculated argv offset.

Root cause: execution previously called `resolve()` before Compose, where
service files were selected from raw local YAML and names inferred from command
arguments. `_materialized_command` then sliced the composed argv using
`2 + 2 * number_of_files`, assuming every generated `-f` pair was a contiguous
prefix. The initial config therefore contained overlays for services that had
not been established by Compose, and option/file arguments made the positional
slice fragile.

Reproduction: in an isolated Docker dev container, create a base compose file
with `source_only` and `blocked`, a configured non-service overlay defining
`present`, home and nested-skill `present/compose.yml` files, a `blocked`
service folder with `disabled.yml`, and a `present/develop.yml` marker with
development overlays. Invoke the resolver with an explicit project directory,
an extra `-f` file, and `build ghost`; make the Compose stub's first `config`
output list `present` and `blocked`. Before the fix, the red assertions showed
only two calls, the first call already contained both `ghost` and `present`
service folders, and there was no later config call selecting overlays from
the first output. The test also forced the raw YAML service parser to die,
proving that execution must not consult it before Compose.

A follow-up red test covered projects without a conventional Compose filename
where the only base is supplied through `-f`. Before the correction, the first
config call preloaded runtime service folders and omitted the selected skill
environment; two assertions failed. `resolve()` now parses leading Compose
options to detect explicit `-f`/`--file` inputs and defers service lookup for
that case too. The fixture then passed with only the explicit base in the first
call, matching overlays in the later config, and service environment applied
only after Compose returned its base service map.

Fix and verification: execution now defers service discovery. It explicitly
constructs a base-config argv, parses the resolved service map, gathers only
matching service files with existing layered marker logic, and materializes
the final config only when service overlays were found. Compose-returned names
must be valid single path segments; empty names, `.`/`..`, and path separators
are rejected before runtime lookup. Argument parsing separates global
options, explicit base files, project directory, and the requested operation
instead of slicing `@full`. The six changed focused regressions (`t/05`,
`t/10`, `t/11`, `t/30`, `t/94`, and `t/266`) first passed 2,105 assertions;
after the 5.64 metadata update, all seven focused files including
`t/15-release-metadata.t` passed 7,540 tests. The resolver file independently
passed 305 assertions, including the explicit-file-only base case. The fresh
full Docker coverage gate passed 258 files / 22,609 tests with 100.0%
statement, branch, condition, and subroutine coverage (45,787 detail rows; no
stale uncoverable annotations). The required focused
web-security trio passed 459 tests. The 5.65 tarball passed CPANTS kwalitee
at 100% (7/7 assertions) and the source POD gate (348 files, 355 assertions).
`dzil build` produced `Developer-Dashboard-5.65.tar.gz`; the image build
succeeded and a one-off Compose run reported `dashboard version` as `5.65`.
The blank-environment container installed the tarball using `cpanm` without
`--notest`, then its complete installed-runtime integration script passed.
`perlsec` was reviewed from the container's `perlsec.pod` with `pod2text`
because the image's `perldoc` has no formatter.
Required security searches found no Problem 40 shell-string execution or
production use of a forbidden library; broad search hits were existing audit
expressions and test fixtures. Devel::Cover warnings for temporary generated
fixture files removed during tests remain visible in its report output, while
the coverage gate exits successfully and reports all four metrics at 100.0%.

### Problem 41: Remove Docker from built-in indicators — done (5.67)

Expected: core indicator refresh works on systems without Docker and does not
probe for the `docker` executable or create a Docker indicator. A Docker status
indicator remains supported when the user explicitly defines a Docker
collector. Legacy persisted core Docker records should be removed without
deleting customized or collector-owned records with the same name.

Root cause: `refresh_core_indicators()` in
`Developer::Dashboard::IndicatorStore` called `command_in_path('docker')` and
persisted a `docker` indicator at priority 20. The configured collector in the
operator's home config uses the same name, so both behaviors converged on one
record and made Docker appear first in the prompt.

Reproduction: run `d2 ps1` in a shell without tmux indicator suppression, or
unset `TMUX`, `WORKSPACE_REF`, `TICKET_REF`, and
`DEVELOPER_DASHBOARD_TMUX_STATUS` for the command. Before the change, core
refresh probes for Docker and creates a whale status even with no configured
Docker collector. The focused Docker test reproduced the old behavior by
replacing the executable probe with a fatal test stub; the first red run exited
early at that probe. A second fixture seeds the exact old core record and
checks that core refresh removes it while preserving a collector-managed
`docker` record.

Implementation removes the executable probe and built-in status write. Core
refresh recognizes and removes only the former exact built-in record signature;
customized and collector-managed Docker indicators remain intact. The focused
Docker regressions pass after the change.

Safety regression: three red assertions exposed missing writer-lock protection
and invisible lock failures in cleanup. Cleanup now acquires the same lock as
status writers before reading ownership. Rerunning both focused test files in
Docker passed 1,042 assertions, including layered/custom collector preservation
and visible filesystem failures.

Container setup correction: the first full run hit Git's dubious-ownership
guard for the bind-mounted `/work` checkout, failing four tracked-document
assertions. A disposable Compose test definition adds `/work` to Git's
safe-directory list inside the test container only. The affected integration
asset tests and indicator tests then passed 491 assertions; the full gate was
restarted with that same isolated setup. Host Git settings were not changed.
The release-metadata gate then caught a stale main-POD version and a disallowed
word in the new testing guidance. Both were corrected; README was regenerated
from POD. Release metadata, integration assets, and indicator regressions passed
5,913 assertions before the next full run.

Security applicability review (ASVS V1–V14): V1/V11 preserve the opt-in
indicator contract; V5 uses a fixed name and presentation signature, not
user-supplied command or path text; V7 reports lock/open/remove errors;
V8/V12 preserve configured records and serialize filesystem cleanup; V14
removes an unwanted default without changing configuration. V2/V3/V4,
V6/V9/V10/V13 introduce no authentication, session, authorization,
cryptography, communication, executable-code, or API changes. Top 10 review:
A04/A05/A08/A09 apply to safe defaults, data ownership, concurrent writes,
and visible failures; A01/A02/A03/A06/A07/A10 have no new access-control,
crypto, injection, dependency, authentication, or outbound-request surface.
Required source searches found only existing audit expressions, documentation,
and synthetic test fixtures for prohibited/sensitive patterns; no new raw SQL,
shell execution, dependency, or credential data was added.

Verification: the complete Docker suite passed 258 files / 22,645 tests and
the library report reached 100.0% statement, branch, condition, and subroutine
coverage (45,841 detail rows, no stale uncoverable annotations). Devel::Cover
also printed missing-digest diagnostics for temporary test-generated helpers
that had already been removed; the canonical gate exited 0 and confirmed the
complete library metrics. The focused security/web trio passed 459 assertions;
the release kwalitee, source POD, and release-metadata gates passed 5,783
assertions, including 100% kwalitee. The final 5.67 archive contains no
`cover_db`. The blank Docker environment installed the same 5.67 release code
with `cpanm` and its normal test execution (no `--notest`); the complete
installed-runtime integration runner reported success. The installed Perl
`perlsec` documentation was reviewed after the gate. No new command execution,
dependency, SQL, endpoint, credential, or authentication surface was
introduced.

### Problem 42: Let skill environment values override home defaults (done in 5.68)

Expected: when a skill command runs, matching values from that skill's `.env`
or `.env.pl` override home runtime values from `~/.d2` or
`~/.developer-dashboard`. A deeper project runtime layer continues to override
both. Non-skill commands keep their current runtime-layer behavior.

Root cause: `SkillDispatcher` loaded skill and skill-CLI files, then called
`load_runtime_layers()` over the entire chain. That reapplied home `.env` files
after the skill and replaced the skill's value. The capture's exact outcome
was `(FOO) ...=HOME` and `(BAR) ...=HOME`, despite each skill having its own
different value; without the home file, both skills printed their own value.

Reproduction: in an isolated Docker dev container, create `foo/.env` with
`SKILL_WILL_OVERWRITE_THIS=I am foo`, `bar/.env` with
`SKILL_WILL_OVERWRITE_THIS=I am bar`, and
`~/.developer-dashboard/.env` with
`SKILL_WILL_OVERWRITE_THIS=HOME`. Run `d2 foo.bash -c` with a command that
prints `$SKILL_WILL_OVERWRITE_THIS`, then repeat for `bar.bash`. Before the
fix both print `HOME`; after the fix they print `I am foo` and `I am bar`.
Remove the home `.env` and rerun to verify the skill-specific values remain.
Also seed the same key in a deeper project runtime `.env` and verify that
project value remains the final override.

Red/green evidence: a regression was added to `t/19-skill-system.t` before
implementation. In Docker, it failed with actual `home-runtime` versus
expected `skill`. After the change, the focused skill and EnvLoader tests pass,
including both home runtime directory names, the skill override, and deeper
project precedence.

Verification: the complete Docker suite passed 258 files / 22,656 tests. The
coverage gate passed at 100.0% statement, branch, condition, and subroutine
coverage (45,874 detail rows; no stale uncoverable annotations). The required
web/security trio passed 459 tests. The gate emitted Devel::Cover missing-
digest diagnostics for temporary fixture helpers removed by their tests; some
existing negative-fixture tests also print expected shell/archive diagnostics.
These are visible and are not described as a warning-free run. `dzil build`
produced the sole archive `Developer-Dashboard-5.68.tar.gz`, with no `cover_db`
entry. CPANTS kwalitee passed 7/7 checks at 100%; POD syntax passed 348 source
files / 355 assertions. The blank Perl 5.44 container installed the archive via
`cpanm` without `--notest`, ran the distribution test suite, and completed its
installed-runtime integration script successfully. `d2 docker.images.build`
completed, and an isolated run of the built `d2` image reported version 5.68.

### Problem 43: Keep Docker Compose skill env scoped to the selected service (done in 5.71)

Expected: when two installed skills each contribute a Docker Compose service
and define the same variable in their skill `.env`, `d2 docker compose up
<service>` interpolates using that service's own skill value. Running `foo`
must not cause a later `bar` command to inherit `foo`'s value. An operation
without a selected service continues to use the environment from all effective
base services. Caller-exported values remain higher priority under Problem 44.

Reproduction from `/tmp/capture-1476.txt`: create `foo/.env` with
`SKILL_WILL_OVERWRITE_THIS=I am foo` and `bar/.env` with
`SKILL_WILL_OVERWRITE_THIS=I am bar`; add matching `config/docker/foo/compose.yml`
and `config/docker/bar/compose.yml` services whose `message` uses
`${SKILL_WILL_OVERWRITE_THIS:-UNDEFINED}`. Run `d2 docker compose up foo`,
remove the home `.env`, and run `d2 docker compose up bar`. Before the fix,
the second container printed `I am foo` although `bar/.env` contained
`I am bar`.

Root cause: `_materialized_command()` replaced the initially requested service
list with every service returned by the base Compose config, then loaded all
of their skill env files into Compose's single global interpolation
environment. With colliding keys, the last enumerated skill won. The red-first
Docker test in `t/94-dockercompose-coverage.t` reproduced this sequence: the
bar materialization and operation both received `I am foo`. The fix preserves
the original selection, intersects it with effective base services, and uses
only those service skill layers for interpolation. Deferred local-base
requests infer selected services from parsed operation arguments; requests
with no matching service retain the established all-base-services behavior.
Compose file gathering and dependency overlays are unchanged.

The focused Docker regression passes 317 assertions, including selected
service isolation, deferred selection, no-service fallback, and the exact
sequential foo/bar case. The full Docker suite passed 258 files / 23,044
tests. The isolated four-metric coverage gate passed with statement, branch,
condition, and subroutine coverage all at 100.0% (46,002 detail rows; no stale
uncoverable annotations). The required web/security trio passed 459 tests.
The gate output includes existing Devel::Cover diagnostics for temporary
fixtures removed by tests and expected output from negative archive fixtures;
the full suite and coverage gate both exited successfully. Security review:
ASVS V1/V11 cover service-scoped interpolation and the tested selection rules;
V5/V12/V14 cover validated service identifiers, service-specific environment
file discovery, and precedence; V7 preserves visible failures. V2/V3/V4/V6/V9/V13
are untouched (authentication, sessions, authorization, cryptography,
transport, and web APIs). V8 has no new secret persistence or logging path.
V10 command construction is unchanged and continues to pass Compose arguments
as an argv list, not through a shell. OWASP Top 10 A03, A04, A05, A08, and A09
were considered; no new injection, authorization, deployment-security,
integrity, or logging surface was added. Perl's `perlsec` documentation was
reviewed in the D2 container. Required source scans found no new production
forbidden-library, credential, SQL, redirect, traversal, or security-header
issue; broad matches were in test fixtures and documented scan commands. The
focused web/security trio passed 459 tests.

`dzil clean` preceded the 5.71 bump. `dzil build` produced only
`Developer-Dashboard-5.71.tar.gz`, with no `cover_db` content. The release
metadata gate passed 5,428 assertions, and CPANTS kwalitee passed all 7
indicators (100%). The exact archive installed in a blank Perl 5.44 container
with plain `cpanm` (no `--notest`), ran the packaged distribution tests, and
reported `Successfully installed Developer-Dashboard-5.71` / `121
distributions installed`. `d2 docker.images.build` succeeded, and an isolated
run of the built image reported version 5.71. The optional t/44 post-build
guard skipped because the dev container has no nested Docker CLI; the direct
blank-container install-and-test flow above completed successfully instead.
No source file under `OLD_CODE` was modified.

### Problem 44: Preserve explicit command-line environment overrides (done in 5.70)

When a caller runs `NAME=value d2 <skill>.<command>`, the command must see
`value`, even when home or skill `.env`/`.env.pl` files define `NAME`. File
values still fill unset variables, and skill files continue to override home
defaults for variables the caller did not export. Regression coverage:
`t/30-dashboard-loader.t`, `t/87-envloader-coverage.t`.
The EnvLoader regression first failed in Docker (`got from-file`, expected
`from-caller`). The implementation captures caller-provided environment key
names at the public switchboard, carries them through helper handoff, and
restores caller values after both runtime and direct skill-file loading. Files
still populate unset keys, skill files still override home defaults where the
caller did not export a value, and env-audit provenance is removed for
caller-owned winning values. Loader errors remain visible after restoring the
caller environment.

The full Docker suite passed 258 files / 22,690 tests with 100.0% statement,
branch, condition, and subroutine coverage (45,961 detail rows; no stale
uncoverable annotations). The required web/security trio passed 459 tests.
Devel::Cover reported temporary fixture files removed by tests; negative
fixtures also print expected shell/archive diagnostics, so the run is not
described as warning-free. Security review found no new forbidden library,
secret, raw SQL path, or missing security-header issue; the environment
handoff adds no shell evaluation or path interpretation. README and main POD
are synced. CPANTS kwalitee passed 7/7 indicators (100%), and POD syntax passed
all 348 discovered source files. `dzil build` produced the sole archive
`Developer-Dashboard-5.70.tar.gz`, which contains no `cover_db`. The blank
Perl 5.44 Compose container installed that archive with `cpanm` without
`--notest`, ran the distribution test suite, and passed the installed-runtime
integration flow. Headless Chromium printed expected missing-D-Bus diagnostics
and the browser probe logged an expected non-2xx response while checking the
unauthenticated route; the integration assertions passed. `d2 docker.images.build`
completed, and an isolated Compose run of that image
reported `d2 version` 5.70. The image-build guard had already recorded 5.69
as used, so the finalized report and repeat artifact checks were assigned this
distinct version. No release upload was performed.

### Problem 45: Add Docker-style timestamps, follow, and tail to dashboard logs (done in 5.77)

Expected: `d2 logs` supports Docker-style `-t`, `-f`, `--tail N`, and
`--tail=N` across the default mixed web/collector view, web-only output, all
collector logs, and a named collector. Flags combine: tail limits the initial
snapshot and follow continues with appended entries. `-n N` remains a
compatible tail alias; zero prints no initial lines, and malformed or
negative counts fail with usage text. Collector lines use their persisted run
timestamp. Raw web log lines have no historical per-line timestamp, so `-t`
uses the time the command reads those lines.

Reproduction: seed isolated web and collector logs, then run
`d2 logs -t --tail=2`, `d2 logs -f --tail 2`, `d2 logs web -t -f`,
`d2 logs collector -t -f`, and `d2 logs collector NAME -t -f`. Before the
timestamp change, `-t` was rejected for every scope. Before the follow change,
`-f` was rejected for collector and mixed scopes. The original Problem 45
regression also showed `--tail=2` returning the full combined output instead
of its final two lines.

Root cause: the runtime-control parser had no timestamp flag, and web follow
delegated to a blocking reader that prevented the CLI from polling collector
logs. Collector output was rendered from completed persisted records instead
of being watched as an append-only source.

Root-cause fix: the shared runtime-control parser accepts `-t`, `-f`,
`--tail N`, and `--tail=N` (retaining `-n N`). It timestamps collector output
from persisted run records and uses UTC read time for raw web records, whose
file format has no historical per-line timestamp. Tail is applied to the
selected output after source composition and timestamp formatting. Follow
polls each source independently, emits only appended bytes, and restarts from
the beginning when a log is truncated. `dashboard serve logs` delegates to
the same parser, so its options and validation stay aligned. The shared help
catalog, option completion metadata, README, POD, and integration plan are
updated.

Docker verification: the focused runtime-control test passes 141 assertions,
and the full instrumented Docker suite passes 258 files / 23,151 tests. The
four-metric gate reports 100.0% statement, branch, condition, and subroutine
coverage (46,174 detail rows; no stale uncoverable annotations). The focused
help-dispatch test passes 469 assertions; release metadata passes 5,427 tests;
POD syntax passes 348 files; and the required web-security trio passes 459
tests. The 5.77 image reports `d2 version` 5.77 and `d2 logs --help` lists
`-t`, `-f`, `--tail N`, and `--tail=N`. Plain `cpanm` (without `--notest`)
installed the archive in a blank Perl 5.44 container, passed the distribution
tests, and completed installed-runtime integration. `dzil clean`,
`dzil build`, and `d2 docker.images.build` succeeded for 5.76; the archive
contains no `cover_db`. The isolated integration Compose project was removed
after the run. The 5.76 feature build's tarball installation and integration
also passed; 5.77 only finalizes release metadata and these archived results.

Security review (ASVS 5.0 applicability): V1, V2, V3, V4, V6, V8, V9, V10,
V11, V13, and V14 have no changed controls for this local CLI log reader. V5
is relevant to strict option/count parsing and registered collector-name
validation; V7 to visible read/follow errors and timestamped output; V12 to
reading only the existing FileRegistry/Collector log sources. No command
execution, write path, route, authentication behavior, dependency, or secret
handling changed. The OWASP Top 10 cross-check found no new A01/A02/A06/A07/A10
surface; A03 input handling, A04 follow/tail behavior, A05 CLI defaults, A08
packaging integrity, and A09 log visibility were reviewed and regression
tested. Required forbidden-library, sensitive-pattern, header, auth/session,
SQL, redirect, path, and process-execution scans produced no new production
finding. `perldoc perlsec` was reviewed for untrusted arguments, command
execution, and file access; no shell or user-selected path is introduced.

Problem numbering note: Problem 44 is already used for environment precedence
in the repository report, so this log issue remains Problem 45 rather than
overwriting that completed entry. The verified change was committed and pushed;
post-push Scorecard reported an 8.1/10 aggregate with remaining external project
settings, approval history, contributor makeup, and badge enrollment items.

### Problem 46: Start path-alias workspaces inside Docker (container config and safe-reuse fixes 2026-10-10)

Expected: `d2 workspace -c <alias> --docker` (or `-d`) resolves the registered
path alias and changes to its directory. If the Compose `workspace` service is
already running, reuse it without rebuilding or replacing its container. If it
is stopped, start it with `d2 docker compose up -d workspace` without building
by default. Uppercase `-C` opts into `up -d --build workspace` with the normal
Docker cache and live progress output. Only after the service is running should the command run
`d2 docker compose exec -e
DEVELOPER_DASHBOARD_CONFIG_OVERLAY=/dev/shm/developer-dashboard-workspace-config
workspace d2 path add <alias> /workspace` and then the same `exec -e
DEVELOPER_DASHBOARD_CONFIG_OVERLAY=/dev/shm/developer-dashboard-workspace-config
workspace d2 workspace <alias> -c`. If the Compose
`workspace` service is absent or fails to start, print an actionable setup
error and run neither in-container command. If service state cannot be checked,
stop without rebuilding. Without Docker mode, workspace behavior must remain
the existing local tmux flow.

Reproduction: define a path alias to a project directory, then run
`d2 workspace -c <alias> --docker` and the `-d` spelling. Before this change,
workspace accepted only `-c` and always created or attached to a tmux session
on the host. Also try `-d` without `-c`, a raw absolute path, and an isolated
Compose project lacking a `workspace` service. Also test with the service
already running (no `up` or build) and stopped (`-c -d` starts without a build;
`-C -d` builds with the normal cache and streams output).

Root cause: `workspace` stripped only `-c`, then unconditionally created and
attached to the host's tmux session. It had no Docker option, Compose handoff,
or guard ensuring the container setup completed before in-container commands.

Red tests: `t/91-cli-ticket-coverage.t` adds command-order, alias cwd, invalid
option/path, no-service, state-probe, running-service reuse, stopped-service
cached-build, and setup-stage failure checks; `t/266-cli-help-dispatch.t`
and `t/39-cli-suggest-complete-coverage.t` cover public help and completion.
The new safe-reuse assertions failed before implementation; they now pass in
the focused Docker run.

Root-cause fix: the workspace parser now recognizes `-d`/`--docker` alongside
`-c`, resolves and changes into the registered alias directory, then hands off
to the public Docker Compose command with an argument list (no shell). It first
uses `compose ps --status running --services workspace`. If running, it skips
all start/build commands so in-container progress is preserved. If stopped,
lowercase `-c` runs `up -d workspace` without a build; uppercase `-C` runs
`up -d --build workspace` using Compose's default cache and streams output
directly to the caller rather than buffering it. A
failed state probe stops before mutations. It then registers the alias and
starts the inner workspace; failures stop the sequence. Omitting Docker mode
retains the existing local tmux path.

Verification: the full test and four-metric coverage gate passed inside the
`dev` container (258 files, 23,201 tests; statement, branch, condition, and
subroutine coverage all 100.0%). Required focused web/SSL tests passed (3 files,
459 tests). The real checkout invocation against this repository's effective
Compose config failed at startup because that config has only `d2` and `dev`,
not `workspace`; the helper printed setup guidance and confirmed it ran no
in-container commands. Injected-runner integration tests verify exact successful
stage order and early stopping on each failure. The initial blank-container
package run exposed a fixture issue: without an init reaper, process-group tests
left descendants observable as zombies. After recreating the isolated Compose
service with `init: true`, plain `cpanm` (without `--notest`) installed both the
5.78 package and final 5.79 archive; each passed the packaged test suite (128
distributions installed). The 5.79 image built successfully and reports `d2
version` 5.79. The final archive includes the completed problem report; runtime
code is unchanged from 5.78. The repository itself does not configure a
`workspace` service, so a real successful interactive workspace session could
not be started here; the service-absent behavior was exercised directly and the
success sequence is verified by the ordered runner tests.

Post-push Scorecard (2026-10-10) reports 8.1/10. Branch-Protection is 0/10
because `master` has no branch protection; CII-Best-Practices is 0/10 because no
OpenSSF badge enrollment is detected; Code-Review is 0/10 because it finds 0/30
approved changesets; Contributors is 3/10 because it detects one contributing
organization; CI-Tests is unknown because no pull request was found. Source-side
checks scored 10/10. These remaining gates require repository administration,
external badge enrollment, or genuine review/contributor activity and are not
failures in the Problem 46 implementation.

Safe-reuse follow-up verification: the `dev` container reports the real
workspace service as running via `d2 docker compose ps --status running
--services workspace`. The focused `d2 docker compose exec dev prove -lv
t/91-cli-ticket-coverage.t` passes 242 tests, including a fork-isolated failed
`exec tmux` path, no rebuild for a running service, cached `up -d --build` for
a stopped service, and aborting on a failed state probe. The live workspace
container was not restarted or rebuilt. The complete Docker coverage run passed
259 files and 23,290 tests; statement, branch, condition, and subroutine
coverage each report 100.0%, with no stale uncoverable annotations.

Release verification for the P46/P47 changes: `dzil clean` removed the prior
5.82 build, then `dzil build` produced only `Developer-Dashboard-5.83.tar.gz`.
All 76 library modules, `dist.ini`, the main POD, and README report 5.83; the
archive contains the P46/P47 regression tests and no `cover_db`. The isolated
`d2 docker.images.build` completed, and a one-off Compose run returned
`d2 version` 5.83. A separate blank Perl 5.44 container installed the archive
with plain `cpanm` (tests enabled, no `--notest`) and the packaged suite passed;
the full blank-environment integration runner then reported success. Its
uniquely named Compose project was brought down afterward. GitHub's
multi-platform publication and the required post-push Scorecard run remain
pending the verified commit and push.

Regression reported 2026-10-10: when the host alias `somewhere` points to
`/tmp/foobar`, the in-container `d2 path add somewhere /workspace` inherited a
bind-mounted host config directory and rewrote the host alias to `/workspace`.
Expected: host `d2 paths` continues to show `/tmp/foobar`; only the container's
workspace command sees `/workspace`.

Red test and root cause: `t/91-cli-ticket-coverage.t` initially failed because
both container `exec` calls omitted config isolation; expected commands
required a private config-root override. Path configuration writes use the
regular active config mechanism, which previously pointed at the mounted host
config.

Fix: both in-container operations now pass
`DEVELOPER_DASHBOARD_CONFIG_OVERLAY=/dev/shm/developer-dashboard-workspace-config`
to Compose `exec`. This stores the alias in a private, additive container-local
config overlay, preserving existing settings while leaving the host
configuration untouched. A container smoke check added
`somewhere` at `/workspace` with an isolated config root and resolved it back
to `/workspace`. Red/green: the initial updated test failed on the old Compose
commands; after the fix, `d2 docker compose exec dev prove -lv
t/91-cli-ticket-coverage.t` passed all 212 assertions. The actual Compose smoke
used `d2 path add somewhere /workspace -o json` and then `d2 path resolve
somewhere` with the isolated config root. This repository has no `workspace`
service or mounted host-home fixture, so a full interactive workspace session
cannot be run here. The generated temporary container test directories were
removed after verification.

### Problem 47: Publish current master builds to Docker Hub (implementation complete; publication and external Scorecard gates pending)

Expected outcome: a GitHub Actions workflow triggered by pushes to `master`
(and by explicit manual dispatch) builds the current `master` checkout, logs in
to Docker Hub with the configured `DOCKER_HUB_USER` and `DOCKER_HUB_TOKEN`
secrets, and pushes both a `dist.ini` version tag and `latest`. The image must
be usable on Linux amd64 and arm64. Docker does not provide macOS-kernel
containers; Apple Silicon runs the arm64 Linux image through Docker Desktop's
Linux VM.

Reproduction: install from MetaCPAN, then compare the installed CLI with the
latest source on `master` before the next CPAN release. A Docker build that
installs only the MetaCPAN distribution will retain the older package even
though it is labeled as the current image.

Root cause: the normal install bootstrap is designed to fetch the published
CPAN distribution, while unreleased fixes exist only in the Git checkout. The
image flow had no job that rebuilt the checked-out code into a tarball and
installed that exact artifact after bootstrap.

Red test: `t/228-dockerhub-image-workflow.t` asserts the GitHub workflow,
credential wiring, version/latest tags, target platforms, and that the image
build runs `install.sh`, `dzil build`, and installs the generated tarball with
`cpanm`. It also guards that GitHub automation files, excluded from the CPAN
archive, do not make the packaged test suite fail, and that the shared Docker
context re-includes the tarball needed by the repository's local image build.

Implementation: `.github/workflows/dockerhub-image.yml` checks out `master`,
validates the X.XX distribution version, logs in to Docker Hub, and uses
Buildx/QEMU to publish a multi-platform manifest. Its Dockerfile runs
`install.sh`, installs the required Dist::Zilla plugins, builds the current
checkout, and tests/reinstalls the exact versioned tarball so an equal-version
MetaCPAN copy cannot shadow it. `.dockerignore` keeps local runtime state,
credentials, and build artifacts out of the image context. Detailed usage and
platform expectations are documented in the repository manual.

Verification: the full repository suite passed in the isolated Docker dev
container (259 files, 23,312 tests), with statement, subroutine, branch, and
condition coverage each measured at 100%. The Docker image build also passed;
its packaged cpanm install ran without `--notest` and passed (259 files, 16,985
tests), and an isolated Compose smoke test reported `d2 version` 5.81. The
focused release/security container gate passed (8 files, 6,438 tests), covering
web update/static/SSL checks, release metadata, this workflow contract,
kwalitee, POD syntax, and CPAN security metadata. `perlsec` was reviewed, and
the repository security scans and `git diff --check` passed. GitHub secrets are
only available to the configured `release` environment, so the remote
multi-platform Docker Hub publish cannot be exercised locally; it will run
when the workflow is pushed or manually dispatched. The first local image
attempt exposed that `.dockerignore` excluded the archive required by the
repository's `d2` image Dockerfile; a new failing assertion reproduced that
contract, then an exception rule fixed it. The next build passed and a fresh
isolated container reported 5.81. D2's project-layer `.env.pl` had also
selected the previous build marker as `D2D_VERSION`; providing the marker as
`D2D_LAST_BUILT_VERSION` made it select the current 5.81 archive without
editing local environment configuration. Host `dzil clean` followed by
`dzil build` completed successfully for 5.81; archive inspection confirmed
the new workflow contract test is included and no coverage database is
packaged. README/POD parity and all 76 library module versions were verified.

Post-push Scorecard identified one repository-fixable item: the Ubuntu base
image tag was not pinned by digest (Pinned-Dependencies 9/10). A new assertion
in `t/228-dockerhub-image-workflow.t` reproduced that finding before the
Dockerfile was changed to the Scorecard-reported multi-platform manifest
digest. This follow-up is version 5.82. The remaining Scorecard findings
require repository administration or community history; rerun Scorecard after
the next push and record the exact remaining gates. The 5.81 GitHub Docker Hub
workflow was triggered by the first push and its final result is being checked;
5.83 will run the multi-platform publish after the package and local image
gates pass and it is pushed.

Security review for Problems 46-47 (ASVS 5.0): V1, V4, V5, V7, V8, V10,
V11, V12, and V14 were applicable. The workspace service name is fixed, user
aliases remain argv values rather than shell source, the private overlay rejects
symlinks and non-owner directories, and startup/exec errors remain visible.
The image workflow requests read-only repository contents, pins every external
action to a full commit SHA and the Ubuntu base to its multi-platform digest,
and passes Docker Hub credentials only to the login action from the `release`
environment; credentials are not build arguments or context files. V2, V3, V6,
V9, and V13 (authentication, sessions, cryptography, transport, and application
API) have no changed runtime surface. OWASP A03, A04, A05, A08, and A09 were
reviewed for command construction, container reuse, workflow configuration,
source/image integrity, and visible failure reporting. A01, A02, A06, A07, and
A10 do not gain a changed access-control, cryptography, dependency, identity,
or request-forgery surface. Required security scans and web/static/SSL tests
passed in Docker; post-push Scorecard governance findings are tracked separately
from code-side security controls.

#### Problem 47 timeout correction (2026-10-10; release version 5.84)

Expected outcome: the GitHub multi-platform publish completes inside its
120-minute job limit and installs the current tarball into both runtime image
architectures. The full test and coverage gates still run before packaging;
image assembly must not repeat the full suite under QEMU.

Reproduction and root cause: pushed commit `aed8ab8d` triggered Actions run
`38078551920`. Setup, source checkout, version validation, QEMU/Buildx setup,
credential validation, and Docker Hub login all passed. The image build stayed
in progress until the configured 120-minute job timeout cancelled it. The
Dockerfile's final `cpanm` installation had no `--notest`, so it reran the
23,000+ test suite for each emulated target architecture despite the separate
full repository and coverage gates.

Red test: updated `t/228-dockerhub-image-workflow.t` first to require
`cpanm --notest --reinstall` for installing the generated archive. Running it
inside the Docker `dev` service failed at that assertion against the old
Dockerfile (31 passed, 1 failed), reproducing the unwanted duplicate suite.

Fix: the runtime image now installs the newly built, version-matched tarball
with `cpanm --notest --reinstall`. This does not weaken verification: full
repository and coverage gates remain mandatory, and the blank-container
integration gate installs the exact archive with tests enabled. The contract
test then passed all 32 assertions in the Docker `dev` service. The post-fix
5.84 full suite passed in Docker (`259` files, `23,284` tests); statement,
branch, condition, and subroutine coverage each measured `100.0%`. The focused
release/security/workflow gate passed `5,625` tests, and the required
web/static/SSL gate passed `459`. `dzil clean` and `dzil build` produced only
`Developer-Dashboard-5.84.tar.gz`; archive inspection confirmed 5.84, inclusion
of workflow/release tests, and no `cover_db`. The standard local image build
and a fresh one-off container both returned `d2 version` 5.84. A direct local
build of the workflow Dockerfile also completed and its one-off image returned
5.84. Finally, the blank Perl 5.44 Docker environment installed that archive
with cpanm tests enabled and completed the integration harness successfully.
The corrected 5.84 GitHub publish and post-push Scorecard remain pending this
version's push.

### Problem 46 follow-up: tmux cannot start in the Docker workspace (2026-10-11–12; runtime verified, packaging gates pending)

Expected outcome: `d2 workspace -c <alias> -d` must attach the caller's terminal
to a live tmux session running inside the Compose `workspace` container. The
session must use a socket location writable by the container user, and a later
`d2 workspace <alias> -c` must reconnect to that same session.

Reproduction: in a uniquely named Compose project, register host alias
`foobar` to the checked-out project and run `d2 workspace -c foobar -d` with the
workspace service running. Before the fix, the in-container command failed
after alias registration with `couldn't create directory /tmp/tmux-1000
(Permission denied)`. The container ran as uid 1000; its bound `/tmp` was mode
0755 and owned by root, so it was not writable. `/dev/shm` was mode 1777 and
writable. The final Compose exec was also routed through output capture instead
of inheriting an interactive terminal.

Root cause: the workspace service's `/tmp` bind mount is not guaranteed to have
the normal writable sticky-bit permissions. Tmux therefore cannot create its
default `/tmp/tmux-<uid>` socket directory. The first outer-flow repair only
selected `/dev/shm` inside the current library code; it did not pass
`TMUX_TMPDIR` across the Compose `exec` boundary. The exact runtime test exposed
that the test workspace image still had d2 5.84, so its in-container workspace
command continued to use `/tmp`. Separately, the outer Docker workspace runner
captured the final long-lived tmux attach instead of preserving the caller's
terminal streams.

Red tests: in the `dev` container, the new interactive-runner assertions failed
against the previous implementation because output was returned in captured
stdout/stderr and the `start_workspace` stage was not marked interactive. The
new socket-directory tests also failed before the helper existed.

Fix: the final Compose exec now requests `-it`, runs without output capture,
passes the terminal streams through directly, and explicitly supplies
`TMUX_TMPDIR=/dev/shm` to the in-container d2 process. Tmux commands also honor
an explicit `TMUX_TMPDIR`; when it is unset and `/tmp` is unwritable, the
workspace helper selects writable `/dev/shm`. This makes the current outer
handoff work even before an older container image is refreshed, and subsequent
clients receive the same socket location. If neither location is usable, the
current helper reports that directly.

Verification: adding an assertion for `-e TMUX_TMPDIR=/dev/shm` first failed
red in `t/91-cli-ticket-coverage.t`; after the handoff change, all 273 assertions
pass in the Docker `dev` container. The related help/completion/dispatch tests
also pass in Docker (3 files, 1,898 assertions). On the isolated
`dd-p46-tmux-red` project, the exact outer command first reproduced the stale
5.84 image failure, then `d2 workspace foobar -d -c` attached successfully
after the new environment was passed. A read-only tmux query reported
`foobar attached=1 cwd=/workspace`; the socket directory was owner-only under
`/dev/shm/tmux-1000`. Detaching returned to the caller, and a later
`d2 workspace foobar -d -C` reused the already-running container without a
build and attached to the same session. The isolated host alias remained
`foobar -> /tmp/foobar`; the normal host path inventory was unchanged.

The stopped-service `-C` branch is guarded by tests that assert the exact
`up -d --build workspace` argv and direct, uncaptured build output; the live
runtime check deliberately did not rebuild the running workspace. At this
checkpoint the full suite had passed (259 files, 22,964 tests), while branch
and condition coverage measured 99.9%; follow-up coverage work is recorded
below.

Follow-up reproduction (2026-10-12): a fresh `d2 workspace foobar -d -c`
against a stopped service unexpectedly invoked BuildKit even though the command
did not contain `--build`; Compose auto-built because the configured image was
absent. That violates the no-build default. The same attempt then reached an
inner `/tmp/tmux-1000` permission error because it used the older installed
outer `d2`, which did not pass `TMUX_TMPDIR`. The checkout implementation does
pass `TMUX_TMPDIR=/dev/shm`; using it with `PERL5LIB` attached successfully to
the in-container tmux session. The stopped-service start argv is now
`up -d --no-build workspace`, and `t/91-cli-ticket-coverage.t` failed first on
the expected `--no-build` argument, then passed after the implementation
change. A fresh, stopped-service checkout invocation remains the final runtime
verification; the installed outer `d2` must be updated for users to receive
this fix.

Resolution verification (2026-10-12): before the image build, host `d2 version`
reported 5.84 while the checkout reported 5.88. With the checkout loaded via
`PERL5LIB`, a fresh stopped workspace started with no BuildKit output, the
caller attached to tmux, and the in-container query reported
`foobar attached=1 cwd=/workspace` with the socket at `/dev/shm/tmux-1000`.
Reattaching with `-d -C` while the service was running did not rebuild it.
Default startup now includes `--no-build`, preventing Compose's implicit
build. The focused Docker test passes 278 assertions; the full Docker suite
passes 259 files / 23,026 tests, and the coverage gate passes all four metrics
at 100.0% (259 files / 22,969 instrumented tests).

Final SDLC verification (2026-10-12): the current `t/91` and related
help/completion tests pass in Docker; `dzil clean` followed by `dzil build`
produced only `Developer-Dashboard-5.88.tar.gz`. Archive metadata and all 76
library module versions are 5.88, README matches the main POD, and the archive
contains no `cover_db` entries. The blank Perl 5.44 Docker environment installed
the tarball with plain `cpanm` (tests enabled) and the complete integration
runner reported `Blank-environment integration run passed`. The required
`d2 docker.images.build` completed and a uniquely named one-off container
reported `d2 version` 5.88. Its Telegram notification timed out with HTTP 500,
but the image build and host `cpanm --notest` install completed; the development
marker was removed afterward. The latest build helper updated the host
installation to 5.88. Security scans, README/POD synchronization, archive
hygiene, and `git diff --check` passed. No push or PAUSE release was requested.

### Problem 46 follow-up: UTF-8 prompt icons render as underscores inside Docker tmux (2026-10-12)

Expected: a Docker workspace tmux prompt and status line preserve the same
Unicode icons as the host terminal. In the recording, the container prompt's
ticket marker and status indicators appeared as underscores. The current
checkout's `d2 ps1` emitted valid UTF-8 bytes, so the text was not corrupted by
the prompt renderer. The workspace image had no `LANG`/`LC_CTYPE` configured;
`locale` reported `POSIX`. A disposable Docker reproduction showed the attached
tmux terminal stream omitted the emoji bytes under `LC_CTYPE=C` but preserved
them under `LC_CTYPE=C.utf8` while holding `LANG` constant. The fix passes only
`LC_CTYPE=C.UTF-8` to the final Compose `exec`; tmux clients inherit it, while
newly started servers inherit it as well. The user's broader locale is not
changed. Cross-testing confirmed that an existing C-locale server can still
render the emoji when its attached client uses the UTF-8 character locale. The
regression first failed on the expected Docker argv and passed after the change.
`t/91-cli-ticket-coverage.t` passes 280 assertions in Docker, and the final
full-suite coverage gate includes it. Targeted security scans/tests pass; full
ASVS review, packaging, and blank-install gates remain pending.

Fresh Docker evidence separates the source bytes from tmux locale handling:
`d2 ps1 --no-indicators` emits the same UTF-8 ticket (`f0 9f 8e ab`) and branch
(`f0 9f 8c bf`) bytes under both `LC_CTYPE=C` and `C.UTF-8`. With tmux 3.6, a
server/client matrix returned no emoji bytes when both used `C`; the bytes were
present when either the server or attached client used `C.UTF-8`. The workspace
handoff sets the client locale, so it also fixes attachment to an already
running C-locale server without changing that server's or pane process's
environment. This confirms the dashboard prompt data and Compose configuration
are not the source of the missing glyphs.

End-to-end tmux replay (2026-10-13): a uniquely named, isolated Compose
workspace used the installed `d2 workspace p46-e2e -c` inside its container.
Attaching without `LC_CTYPE` reproduced the report exactly: the prompt marker
and status icons appeared as `____ __h __`. Reattaching to that same tmux
server with `-e LC_CTYPE=C.UTF-8` rendered `✅🐳 🚨h 🕒` in the prompt/status
stream. The source `ps1` renderer and ticket/branch UTF-8 bytes were unchanged;
the only difference was the Docker exec client's locale. The workspace and
tmux test projects were removed after the check. The checkout's outer
`workspace` wrapper could not be exercised directly in this tool environment:
its nested raw Compose materialization was rejected with `Run d2 docker
compose ... instead of raw docker command`; the equivalent `d2 docker compose`
startup, alias registration, and both inner-workspace client handoffs were
tested directly instead.

Scope refinement (2026-10-13): a red-first Docker regression showed that the
first fix also forced `LC_CTYPE` in the general `workspace_environment`
builder, affecting ordinary non-Docker workspaces. That assignment is removed;
the locale remains explicit only on the final Docker Compose exec, where the
attached client and a newly started tmux server inherit it. The focused test
failed before and passed after this refinement (280 assertions). Repeating the
actual in-container `d2 workspace p46-final -c` attachment rendered
`✅🐳 🚨h 🕒` in the live tmux prompt/status; the uniquely named Compose
workspace was then stopped and removed.

### Problem 48 verification refresh (2026-10-13)

The cold-start Docker benchmark (two warm-ups and ten measured runs per
command) reported medians of 33.622 ms for `version`, 77.291 ms for
`paths -o json`, and 82.907 ms for `ps1 --no-indicators`. Compared with the
recorded v5.88 medians of 56.7, 93.3, and 109.5 ms, the current runs are about
1.69x, 1.21x, and 1.32x faster; the 50x objective remains unmet.

The full Docker suite passed 263 files / 23,556 tests with `init: true` and DAC
capabilities dropped. A preceding run without the init reaper exposed
descendant-reaping test failures, and `t/21-refactor-coverage.t` caught the
workspace locale leaking into the legacy ticket environment. The code now
scopes `LC_CTYPE=C.UTF-8` to the workspace handoff; seven focused regression
files passed 1,479 tests, and `t/91-cli-ticket-coverage.t` passes 280 tests.
The clean repeat of `script/coverage-gate` began with a clean database deletion
and passed 263 files / 23,494 tests and 100.0% statement, branch, condition,
and subroutine coverage across `lib/` (46,837 detail rows, no stale
uncoverable annotations). Seven environment or tooling-dependent files skipped
with explicit reasons. This verification does
not close packaging, integration, security-review, release-metadata, or git
delivery gates; the measured 50x-per-subroutine requirement is still open.

### Problem 48 PathRegistry hot-path refinement (2026-10-13)

The NYTProf `paths` trace recorded 74 `_same_or_descendant_path` calls and
2.03 ms exclusive time. A red-first Docker regression around
`_ancestor_runtime_layers` observed three stop-directory identity resolutions
for a three-level walk. Lazily caching the stop identity reduced that count to
one while preserving the zero-canonicalization exact-root fast path. The final
259-test PathRegistry suite passed in Docker. This is a
specific call-count reduction; no 50x or wall-clock gain is claimed. Distinct
symlink spellings continue through canonical resolution.

Follow-up evidence from a fresh isolated Docker run confirms the boundary: with
`d2 ps1` output held constant as valid UTF-8 bytes, a tmux server started under
`LC_CTYPE=C` emitted no emoji bytes to a C-locale client, but did emit them to
an attached `LC_CTYPE=C.UTF-8` client. Therefore the source indicators and
Compose YAML are not the cause; the defect was the Developer Dashboard Docker
workspace handoff omitting the UTF-8 character locale for the tmux client. A
separate check confirms changing the client locale does not rewrite an already
running tmux server's or pane process's environment; the observed status-line
rendering depends on the client locale, which the handoff now sets. The
existing regression asserts this locale in the final Compose exec argv.

### Problem 48: Accelerate every subroutine by at least 50x against 5.88 (implementation in progress)

Full requested scope: use MCE, FFI::Platypus, Inline::C, XS, SPVM, Memoize, and
Perl's built-in class/method/field and method/subroutine signatures to speed
every Developer Dashboard subroutine at least 50x versus version 5.88. Preserve
all behavior and prove each claimed improvement with repeatable benchmarks and
regression tests. Do not claim the whole goal from one optimized routine.

Latest command-floor evidence (2026-10-14): an alternating 31-run Docker
measurement found a 2.286 ms median for a bare `perl -e 1` child and 32.528 ms
for the current `perl bin/dashboard version` child. The documented v5.88
version baseline is 56.7 ms, so 50x end-to-end would require 1.134 ms—below
the measured Perl child-process floor. This is not a reason to reduce the
requested subroutine scope; it shows that the command-level 50x interpretation
requires a resident invocation architecture or a non-Perl launcher, each of
which needs separate behavior and security validation. The full objective
remains open.

### Problem 48 path-identity argument parsing candidate (2026-10-14)

A positional-argument `_path_identity` prototype returned the same path and
was 1.20x faster in an isolated helper benchmark. The candidate was then
compared through `all_paths` over 50 skills, requiring byte-identical JSON on
each run. Across 31 alternating runs, baseline and candidate medians were
0.210 ms and 0.209 ms (1.01x). The aggregate gain is negligible, so no code
changed. Problem 48 remains open.

Latest inventory profile (2026-10-14): NYTProf traced the existing resident
path benchmark with 250 synthetic skills. Output parity and configuration
replacement, dynamic Folder.pm environment, skill-add, and skill-delete checks
all held. The call tree identifies per-skill `Config::_skill_config_hash`
reads and `PathRegistry::nested_skill_entries` as the inventory work; however,
this profile includes fixture setup, child-process timings, and freshness
probes, so its timing ratio is not accepted as a production measurement. It
guides further isolated profiling only; no MCE production change or persistent
cache is justified by this result. The 50x-per-subroutine target remains open.

Latest targeted implementation (2026-10-14): `Config::collectors` was reading
every installed skill's `config.json` once to build merged configuration and
again to build skill-qualified collector jobs. The red-first regression failed
with two `_skill_config_entries` calls. `load_global` now exposes the entries
it actually loaded via an optional output array, and `collectors` passes that
same list into `_skill_collectors`; read order and merge/output behavior stay
unchanged. The Docker config suite passes 235 tests. In 21 alternating Docker
benchmark pairs with 250 skills, canonical job output matched exactly and the
legacy double-read path measured 27.324 ms versus 15.446 ms after (1.77x).
The repeatable command is `d2 docker compose -f /tmp/d2-problem48-bench.yml
run --rm bench perl script/problem48-collector-config-benchmark`.
This scoped improvement does not meet the 50x-per-subroutine objective; the
full Problem 48 and SDLC delivery gates remain open.

Reproduction and baseline: run the checked-out `bin/dashboard` inside the
isolated `dd-problem48-profile` Compose project five times each for `version`,
`paths`, and `ps1`. Median elapsed times were 56.7 ms, 93.3 ms, and 109.5 ms.
Profile `t/03-web-app.t` in a one-off container; all 328 assertions passed.
The instrumented test profile is dominated by test activity, including
`IO::Select`/`IPC::Open3`, template/page parsing, and authentication's
210,000-round PBKDF2 test. These timings are not production-route benchmarks.

Current diagnosis: the initial CLI profiles show Perl startup/module loading,
environment reads, and path setup; these are not helped by per-subroutine
parallel execution. MCE provides workers for independent batches, while
FFI::Platypus calls explicitly typed native functions. Neither transparently
accelerates arbitrary Perl subroutines.

Candidate FFI result: a Docker proof-of-concept called OpenSSL's
`PKCS5_PBKDF2_HMAC` once through FFI, preserving 210,000 rounds and returning
the same digest as the current code. Five measurements were 278–300 ms for the
existing Perl loop (median 284 ms) and 29.7–31.4 ms for the native function
(median 29.9 ms), about 9.5x faster on this Linux container. A direct loader
name did not resolve; `FFI::CheckLib::find_lib` found the actual `libcrypto`
path. Latin-1-downgradable `£` password parity passed only after matching the
existing Perl byte semantics with `utf8::downgrade`. The existing code rejects
characters outside that byte range with a wide-character exception; the FFI
path must preserve that behavior. This is a promising single hot routine, not
evidence for an all-subroutine rewrite.

MCE fit decision: a synthetic ten-probe readiness model improved from 3.001 to
0.906 seconds with four workers, but it is not a safe production optimization.
Collector startup verifies each process before launching the next, and the
existing tests require that fail-fast order. Parallelizing readiness would
start later collectors before an earlier failure is detected, changing
rollback semantics. No MCE dependency or runtime change was retained. Revisit
only if profiling finds a real independent batch with behavior-preserving
tests. PBKDF2 itself is sequential and is not split across workers.

TDD and verification so far: the new PBKDF2 test first failed because the
adapter module did not exist. A synthetic MCE regression test demonstrated the
speed possibility, then was removed when it exposed the startup-order behavior
change. The adapter now passes digest parity, byte semantics, invalid-input,
missing-library, native-error, and full-work-factor checks. Docker focused
tests pass 6,010 assertions across the adapter, authentication, runtime
manager, and release metadata files. The auth performance test reported
30.9 ms for the production work factor in this Docker run versus the
recorded 284 ms Perl baseline.

Measured startup follow-up: NYTProf first attributed 18.6 ms inclusive to eager
`Pod::Usage` loading on the version path. A red CLI smoke contract failed before
the eager import was removed and the usage-error branches changed to load the
module lazily. Later NYTProf tracing showed the apparent lazy import was
insufficient: `bin/dashboard` loaded `InternalCLI` before dispatch, and that
module loaded `Platform`; `PathRegistry` also imported `Platform` eagerly. Red
runtime tests confirmed both paths. The fix defers those imports until their
behavior is needed and adds `Developer::Dashboard::Version` so the version
command does not load the full `Developer::Dashboard`/Handle/FileRegistry
graph. The version-specific regression suite passed 12 assertions, and the
release metadata suite passed 5,502 assertions in Docker. A 15-run median is
now 35.114 ms (33.889–41.006 ms) versus the recorded 5.88 baseline of 56.7 ms,
about 1.62x; NYTProf contains no Platform, InternalCLI, Handle, or FileRegistry
entries for that command. This remains far short of 50x.

Cold-start refinement (2026-10-13): the switchboard imported `Config` without
using it and loaded `IO::Handle`, `IO::Select`, `IPC::Open3`, and `Symbol` even
when no executable hooks existed. Red-first Docker tests failed against all
five eager imports. The unused import is removed and hook dependencies are
loaded only inside hook execution. The hook-bearing CLI smoke suite passed
1,029 assertions. A paired 25-run Docker comparison, using the same `do`-based
command harness and preloading the five modules as the control, measured
33.104 ms for the control and 31.520 ms for lazy loading (about 1.05x). This
modest startup improvement is not a 50x result.

Follow-up profiling on the checkout's `paths` and `ps1` helpers found
`Cwd::cwd` invoking its external `pwd` implementation. In Docker, 30 calls
averaged 2.939 ms each versus 0.003 ms for validating the shell's absolute
`PWD` by device/inode against `.`. A shared helper now uses validated PWD,
preserves a valid logical symlink path, and falls back to `Cwd::cwd` for
absent/stale values. The switchboard and production path, file, ticket, prompt,
action, collector, Docker, update, skill-install, folder, indicator, web,
environment, and handle call sites use it instead of Cwd::cwd/getcwd. The new
six-assertion red-first test and related regression files passed in Docker. The
full suite has since passed 262 files / 23,422 tests. A fresh NYTProf trace
showed that the aggregate path inventory wrote the same runtime metadata three
times. A red-first test reproduced those three writes; `all_paths` now resolves
the state root once and derives collector/indicator child roots from it. The
same trace showed the passwd fallback loading Platform; PathRegistry now calls
the guarded Perl passwd builtin directly, with tests for success, no record,
and lookup exceptions. Fifteen-run Docker medians are now 31.486 ms for
`version`, 71.309 ms for `paths`, and 83.641 ms for `ps1`, versus 5.88 baselines
of 56.7 ms, 93.3 ms, and 109.5 ms (about 1.80x, 1.31x, and 1.31x). These
changes remain far from 50x.

Expanded technology audit: Inline::C's warmed OpenSSL wrapper measured 31.0 ms
versus FFI's 32.4 ms for the same PBKDF2 call (~4% difference); Inline::C
generates XS glue, so retaining parallel wrappers adds no meaningful gain.
SPVM and SPVM::Digest::SHA were installed in the isolated container but no
dashboard routine was shown faster than the existing one-call OpenSSL boundary.
Memoize has no identified safe hot path beyond current explicit runtime caches.
Perl's built-in class syntax remains experimental on container Perl 5.40.1 and
emits warnings; its migration is not proven faster. MCE's synthetic model
remains unsafe for the production collector startup order. Alternative
compiler research found B::C removes startup parsing but does not speed runtime
execution, while B::CC documents semantic differences. XS::JIT compiles
hand-written C rather than translating Perl subs; its published synthetic
example reports only 1.36x over Inline::C. None supports a behavior-preserving
50x migration of the repository's routines.

Literal-target audit: the v5.88 `HEAD` tree has 1,624 named `sub` declaration
lines under `lib/Developer/Dashboard`; the current worktree has 1,648 by the
same source-line count. Anonymous closures are excluded; none of these has a
50x before/after proof set. The measured
bare Perl process floor is 1.032–1.268 ms; 50x for the 5.88 `dashboard version`
median would require about 1.134 ms total, leaving roughly 0.1 ms beyond the
interpreter floor for application startup, environment discovery, hooks, and
output. The current evidence contradicts a 50x result for that invocation and
does not establish it for each of the 1,648 current named routines. Problem 48 remains open
and the requested target has not been met.

Coverage follow-up (2026-10-12): the previous full Docker run passed 263 files /
23,468 tests but measured 99.9% branch and 99.8% condition coverage, both
short of the repository's 100% gate. The report traced the misses to two
PathRegistry short-circuit combinations. `t/97-pathregistry-coverage.t` now
changes one account environment value between two defined values and simulates
an empty metadata read stream. Its focused Docker run passed all 255 assertions.
The fresh full Docker gate then passed 263 files / 23,488 tests and measured
100.0% statement, branch, condition, and subroutine coverage across `lib/`
(46,834 detail rows; no stale uncoverable annotations). This closes the
coverage shortfall only; Problem 48's 50× performance requirement and remaining
delivery gates are still open.

Fresh-process timing recheck (2026-10-12): after two warm-ups, 15 successful
Docker executions measured medians of 36.379 ms for `dashboard version`,
82.020 ms for `dashboard paths -o json`, and 90.429 ms for `dashboard ps1`.
Exit statuses were checked and stdout was discarded to exclude terminal output
from the timing. The refreshed results do not establish a 50x result; the
resident-runtime and socket results below remain separate prototype figures.

Isolated status-route follow-up (2026-10-12): in a Dancer/PSGI `/system/status`
profile with all account-name environment variables unset, NYTProf measured
69.7 ms/request and counted 80 passwd fallback calls across 20 requests.
Caching the account name for the exact unchanged environment reduced the
same stripped-environment profile to 58.3 ms/request and one fallback call.
The focused PathRegistry Docker suite passed 225 tests. This is an
instrumented edge-environment result, not a typical-route or uninstrumented
latency claim. Separately, direct `app.psgi` startup failed because its
`Prompt->new` call omitted the required `indicators` argument. A red-first test
reproduced it; the fix constructs one `IndicatorStore` shared with `Prompt`,
and the test now passes 3 assertions while requesting `/system/status` through
the actual PSGI coderef. A red-first metadata test also caught `runtime.json`
being rewritten on every indicator-root lookup. The writer now validates file
type, owner, mode, and exact content before skipping an identical write,
repairs missing/stale/loose metadata, and rejects symlinks. In Docker, the
updated PathRegistry suite passed 235 tests. NYTProf on the actual app.psgi
route measured 2.62 ms/request before metadata-write avoidance and 0.616
ms/request afterward (about 4.25x); the metadata writer moved from 1.13 ms to
0.132 ms per call. A separate unprofiled paired ABBA comparison used the
reconstructed legacy always-write routine and verified routine in the same
app process: 80 requests each, exact response-body parity, 1.044 ms/request
versus 0.587 ms/request (about 1.78x). This isolates this writer change; it is
not a v5.88 benchmark or evidence for the all-routines 50x target.

A direct NYTProf trace of the source helper entrypoint
`share/private-cli/paths` completed successfully. Profiling the public
switchboard itself was incomplete because it intentionally `exec`s the staged
helper. The complete helper trace counted 303 runtime-root entries, 97 skill
disable-marker checks, 32 queued
top-level skills, and 152 nested skill directory entries; these are profiler
call-count observations, not uninstrumented time measurements. Skill discovery
loads arbitrary user `Folder.pm` modules and invokes user methods, so caching
those results without a complete invalidation contract is not safe.

A red-first experiment memoized the derived `skills_roots` list per runtime
root set. Its focused contract passed, but alternating Docker measurements
were noisy and did not establish a stable end-to-end gain; the optimization
and test were removed. Current effort remains on avoiding cold Perl startup
without caching mutable filesystem or user-module behavior.

Targeted security follow-up (2026-10-12): the container's Perl 5.40.1
`perlsec` guidance was reviewed after the focused test gate. The FFI adapter
validates scalar and byte inputs, bounds values for OpenSSL's signed-int ABI,
keeps buffers live through the synchronous native call, and exposes native
errors; it adds no shell execution or user-controlled executable path. The
required web-security trio passed in Docker (3 files / 459 tests). Full ASVS
V1–V14 review and the repository-wide security scans remain pending release
gates.

### Problem 48 resident-cache freshness precondition (2026-10-14)

The focused Docker run of `t/97-pathregistry-coverage.t` passed all 293
assertions. It confirms that one PathRegistry instance sees a skill added
after a request-local inventory scope, a newly created disable marker, removal
of that marker, and deletion of the skill directory on later lookups. This is
confirmed for current lookups; the same Config and PathRegistry objects also
see replaced skill config bytes, a newly installed skill alias, and a runtime
symlink retarget. This does not establish freshness for a persistent resident
cache or the 50× target.

The focused Docker run of `t/90-cli-paths-coverage.t` passed 33 top-level
tests, including a provider whose `Folder.pm` method reads a sidecar file
outside the skill tree. Repeating alias enumeration through the same paths
object after changing that file returned the updated target. A watcher limited
to skill/config roots cannot detect arbitrary user-module dependencies, so a
resident optimization must not memoize user `Folder.pm` method results.

### Problem 48 tiny FFI boundary probe (2026-10-14)

A three-second Docker microbenchmark compared `PathRegistry::home` with
FFI-bound libc `getenv("HOME")`. Both returned the same string in the measured
environment; the Perl accessor ran at 12.43 million calls/second and the FFI
call at 5.58 million calls/second (about 2.23× slower through FFI). These
operations are not semantically identical under environment mutation, so this
is boundary-cost evidence only, not a claimed function speed comparison.

### Problem 48 stale runtime-layer memoization (2026-10-14)

The red-first Docker regression failed because a single PathRegistry instance
did not see a project `.developer-dashboard` directory created after its first
`runtime_layers` lookup. It also confirmed stale inclusion after that
directory was removed. The implementation now refreshes unscoped runtime
discovery and caches the result only inside the existing `all_paths` or path
CLI operation scope. The focused PathRegistry Docker suite passes all 298
assertions, including same-object create/remove and bounded scoped reuse. This
is a correctness/freshness fix, not evidence of the requested 50× speedup.

The subsequent full Docker suite passed 265 files / 23,392 tests. A fresh
`script/coverage-gate` run passed 265 files / 23,330 tests and reported 100.0%
statement, branch, condition, and subroutine coverage across `lib/` (47,381
detail rows). The required web-update, static-file, and SSL security tests also
passed. This evidence validates the current worktree but does not satisfy the
separate 50×-per-subroutine performance objective.

### Problem 48 matched per-routine profile (2026-10-14)

The same `paths -o json` helper was profiled in Docker from the v5.88 source
and current checkout with identical HOME/cwd inputs. A byte comparison of the
JSON outputs passed. NYTProf reported 59.4 ms for v5.88 and 47.9 ms currently
(1.24× at handler level). `PathRegistry::_path_identity` exclusive total
changed from 2.37 ms over 133 calls to 90 μs over 103 calls; normalized per
call, that is about 20×, still below the 50× target. This profile includes
only routines reached by this command and cannot establish the all-subroutine
objective.

New route under investigation: a resident Perl command runtime can avoid
restarting Perl for each repeated request. In Docker, the current `dashboard
paths -o json` command averaged 84.412 ms over ten fresh launches. The same
real handler in a resident context averaged 1.018 ms while recomputing the
path map and JSON, with byte-for-byte output parity (82.9x experiment-level
reduction). A Unix-socket prototype with a separately launched C client
averaged 0.514 ms over 100 requests and matched the CLI output (164x in that
experiment). Linux `inotify` prototypes detected config replacement and
nested-skill creation; probing an unchanged event descriptor averaged 0.0010
ms/request for 401 watches, installed in 0.532 ms. These are separate
prototypes, not a combined or production benchmark. The event-driven cache is
not implemented; overflow/recovery, cross-platform support, deletion and
symlink behavior, arbitrary user `Folder.pm` inputs, and end-to-end freshness
and parity remain open. The evidence identifies a credible way to preserve a
50x margin on repeated path inventory requests, not a 50x result for all
commands or all 1,648 current named subroutines.

The implementation currently adds the OpenSSL adapter, optional FFI runtime
recommendations, Auth integration, lazy usage/platform loading, lightweight
version metadata, verified PWD lookup, and path inventory reuse. The latest
full Docker suite passed 262 files / 23,442 tests. The canonical coverage gate
reports 100.0% statement, branch, condition, and subroutine coverage (46,727
detail rows, no stale uncoverable annotations), with no Devel::Cover warning
diagnostics. A red-first gate regression removed warnings caused by temporary
staged helper trees without excluding `lib/` files. The remaining extra
statement diagnostics traced to runtime-generated saved-Ajax and CODE sandpit
source being counted under `PageRuntime.pm`; eval source identities now keep
generated code outside the static module source map. The checker also fails
closed on report warnings. Seven environment/tooling-dependent test files were
skipped (audit tooling, operator-local tool specs, QEMU, browser, kwalitee, and
Docker-daemon checks). Remaining SDLC gates include the mandated security
audits and integration plan, dependency review, aligned version metadata,
clean/build, blank-container tarball installation with tests, Docker image
build, final artifact/evidence audit, and commit. No push or PAUSE release has
been requested. The full 50x-per-subroutine target remains unmet.

Latest follow-up (2026-10-12): a red-first Docker regression caught two
redundant `abs_path` calls when `_same_or_descendant_path` received the same
nonempty path string twice. It now returns true before filesystem resolution
after checking the required option; Docker confirmed zero canonicalization
calls and unchanged boolean output. Differently spelled paths still use
canonical resolution. This is a narrow measured-work reduction, not evidence
of the requested 50x overall speedup.

Full Docker coverage gate (2026-10-13; before the optional-FFI follow-up):
after the PathRegistry test edits,
`script/coverage-gate` ran inside the isolated Docker bench with its coverage
database under the container's `/tmp`, leaving repository coverage databases
untouched. All 263 test files and 23,498 tests passed in 1,172 seconds. The
report measured statement, branch, condition, and subroutine coverage at
100.0% across `lib/` (46,844 detail rows; no stale uncoverable annotations).
Seven environment- or tool-dependent test files reported explicit skips. The
required focused web-security trio also passed in Docker (3 files / 459 tests).
These checks do not prove the 50x performance target, complete the ASVS V1–V14
review, or close the remaining packaging and delivery gates.

Optional FFI dependency/fallback correction (2026-10-13): a red-first
release-metadata test caught that the adapter's optional FFI dependency was a
hard Dist::Zilla prerequisite and missing FFI modules still threw despite the
documented Perl fallback. The FFI modules are now runtime recommendations in
`dist.ini`, `cpanfile`, and MakeMaker metadata. `_load_backend` returns native
acceleration as unavailable only when the requested FFI module itself is
absent; errors inside installed modules remain visible. Red-first Docker tests
failed on all three missing-module cases, then the focused metadata, adapter,
and Auth suite passed 3 files / 5,616 tests. The full coverage gate, release
build, blank-container install, and image build must be repeated after this
follow-up.

Fresh-interpreter regression (2026-10-13): the previous absence checks loaded
the adapter while FFI modules were installed, then hid their `@INC` entries.
That missed compile-time `use FFI::Platypus` and `use FFI::Platypus::Buffer`,
which made the supposedly optional dependencies mandatory at adapter import.
A red-first Docker test started a new Perl interpreter with the FFI library
path removed and failed with `Can't locate FFI/Platypus.pm`; the adapter now
loads FFI modules only inside `_load_backend`, so the test passes and
`native_available` selects the documented Perl fallback. A second regression
keeps initialization errors from installed FFI modules visible. The focused
adapter run passes 35 tests and reaches 100.0% statement, branch, condition,
and subroutine coverage. The subsequent full Docker gate passed 263 test files /
23,518 tests and 100.0% statement, branch, condition, and subroutine coverage
across `lib/` (46,868 detail rows, no stale uncoverable annotations). Seven
environment- or tool-dependent files skipped with explicit reasons. This is
coverage evidence, not evidence that the 50x performance target is met.
Path CLI refinement (2026-10-13): current-checkout NYTProf showed the
`path project-root` command loading `Config` and `FileRegistry` even though it
does not access configured aliases. A red-first subprocess test failed on both
imports. The path CLI now loads those modules only for verbs that need them;
Docker verification passed 24 lazy-loading assertions and the 31-test path
suite. An alternating 25-run fresh-process comparison measured 30.372 ms for
the lazy candidate and 36.041 ms for a control preloading both modules (about
1.19x). This is a modest command-specific gain; Problem 48's full target
remains unmet.
Path option-parser refinement (2026-10-13): checkout NYTProf showed
`Getopt::Long` initialization on `path project-root`, which does not parse
options. A red-first subprocess probe failed while `Getopt/Long.pm` was eager;
the path CLI now loads it only for option-bearing verbs. The two focused Docker
suites passed 57 tests. An alternating 25-run process benchmark measured
28.863 ms for the lazy candidate and 32.937 ms with `Getopt::Long` preloaded
(about 1.14x). This is another command-specific gain; the all-subroutine 50x
target remains open.
Full coverage recheck (2026-10-13): the canonical Docker coverage gate passed
263 files / 23,532 tests after the path option-parser change. Statement,
branch, condition, and subroutine coverage each measured 100.0% across `lib/`
(46,890 detail rows, no stale uncoverable annotations). Environment- and
tool-dependent files reported explicit skips. The 50x-per-subroutine target
and remaining release/security/integration gates are still open.
Cumulative project-root comparison (2026-10-13): a Docker ABBA benchmark ran
20 fresh processes per mode through the same path-registry/project-root
handler. The current mode deferred Getopt::Long and skipped unused
Config/FileRegistry construction; the control reproduced that prior setup.
Captured outputs matched byte-for-byte (`/checkout`). Median times were
26.852 ms and 35.489 ms (about 1.32x). This is a single-route measurement and
does not prove the 50x-per-subroutine objective.
Path output parser optimization (2026-10-13): a fresh NYTProf trace showed
Getopt::Long initialization among the largest one-time costs of the `paths`
command. A red-first Docker test required canonical `-o` and `--output`
forms to avoid loading the module while preserving the fallback for
noncanonical syntax. The full canonical paths action returns the same JSON
without loading Getopt::Long. An in-process 100,000-iteration benchmark
measured 130.4 ms for the local parser versus 1,604.1 ms through Getopt::Long
(about 12.3x for option parsing itself). A paired 20-cycle Docker benchmark
then compared the full `paths -o json` command with its equivalent
Getopt::Long abbreviation fallback. The 981-byte outputs matched exactly;
medians were 67.578 ms and 72.113 ms (about 1.07x). This confirms a modest
command-specific gain, not the 50x all-routine target.

Coverage follow-up (2026-10-13): the first full run found a test-harness defect:
native-only PBKDF2 checks skipped when optional FFI modules were absent, but a
later fixture still required `FFI::CheckLib` unconditionally and exited after
seven assertions. The test now detects only the exact missing optional module
and skips the dependent fixture, leaving fallback and initialization-error
checks active. Focused Docker runs passed with and without the optional FFI
modules. The final stable-tree Docker coverage gate passed 263 files / 23,539
tests and measured statement, branch, condition, and subroutine coverage at
100.0% (46,943 detail rows; no stale uncoverable annotations). The 50x target
remains unmet.

Modern Perl syntax performance check (2026-10-13): an isolated Perl 5.40.1
D2 Docker benchmark used 20 alternating cycles of one million equivalent
calls per variant and verified result parity. Signatures versus manual `@_`
unpacking measured 0.094025 s versus 0.094165 s (1.001x, no meaningful gain).
A built-in `class`/`field :param`/`method` getter measured 0.149127 s versus
0.125507 s for the equivalent hash-backed getter (class syntax was slower).
An earlier single-batch signature result of 1.35x did not repeat and is
superseded by the alternating benchmark. No repository-wide syntax migration
was made; this evidence does not establish or satisfy the required 50x for
every subroutine.

Prompt-path refinement (2026-10-13): a red-first test made an injected
`Capture::Tiny` stub die when loaded during ordinary `dashboard ps1
--no-indicators`; the existing helper and `IndicatorStore` imports triggered
it. The helper now loads Capture::Tiny only for a tmux ticket lookup, while the
full project/Git core-indicator refresh loads it only after returning from the
prompt-only path. Focused Docker tests passed for the prompt loader, CLI smoke,
and IndicatorStore (1,322 tests), retaining tmux and Git capture behavior. An
alternating 25-cycle fresh-process benchmark measured 71.498 ms median with
lazy loading and 78.034 ms with Capture::Tiny force-loaded (about 1.09x). This
does not close Problem 48's 50x-per-subroutine objective.

Path-only Config view refinement (2026-10-13): the prompt and path CLI created
a `FileRegistry` only to construct `Config`; these collector and path-alias
operations resolve through `PathRegistry`, and `Config` does not access its
`files` member. A red-first Docker test blocked `FileRegistry` and failed on
`dashboard paths -o json`. `Config->for_path_config` now creates a path-bound
view without importing or constructing `FileRegistry`, and both paths use it.
The prompt-loader, Config, and path CLI suites passed 361 assertions. An
alternating 25-cycle fresh-process comparison measured `dashboard paths -o
json` at 64.636 ms with FileRegistry unloaded versus 72.077 ms with its module
force-loaded (about 1.12x). This control isolates import overhead and does not
reproduce the full old path. The first full gate found a stale
`Config->new` test double, which did not stub the new `for_path_config`
constructor. After updating that fixture, the complete Docker gate passed 263
files / 23,544 tests and reported 100.0% statement, branch, condition, and
subroutine coverage across `lib/` (46,954 detail rows, no stale uncoverable
annotations). `perldoc perlsec` was run in the container after the gate. Several
environment-bound checks self-skipped with explicit reasons; they are not
counted as executed coverage checks. The 50x target remains unmet, and
integration, packaging, image, and final release gates are still pending.

Paths helper startup refinement (2026-10-13): a red-first subprocess test
showed `share/private-cli/paths` loading FindBin even though the public
switchboard passes `DEVELOPER_DASHBOARD_REPO_LIB` before helper exec. The helper
now uses that supplied repository library path and keeps FindBin for standalone
fallbacks. Docker regressions confirm both paths work without warnings and emit
byte-identical JSON. An alternating 100-pair fresh-process helper benchmark
measured 26.963 ms for the FindBin fallback and 24.782 ms for the supplied
library root (about 1.09x). This isolates helper startup, not the full public
command; it does not establish the 50x target.

Final verification refresh (2026-10-13): after the helper change and the
release-metadata wording correction, the canonical Docker coverage gate passed
263 files / 23,551 tests. Statement, branch, condition, and subroutine coverage
each measured 100.0% across `lib/` (46,954 detail rows; no stale uncoverable
annotations). `perldoc perlsec` was run after this final gate. Optional
tooling, browser-loopback, QEMU, and Docker-daemon checks emitted explicit
skips. This does not establish the 50x-per-subroutine goal or close the
integration, packaging, image-build, and git-delivery gates.

Prompt helper startup refinement (2026-10-13): NYTProf showed about 2.4 ms
inclusive in FindBin initialization for `ps1 --no-indicators`. A red-first
Docker test caught the helper loading FindBin despite the public switchboard
already supplying `DEVELOPER_DASHBOARD_REPO_LIB`. The helper now uses that path
and retains FindBin for direct standalone invocation. Tests verify no warning
on either route and equal prompt output apart from the live timestamp. An
alternating 25-pair cold-helper benchmark measured 33.364 ms for the supplied
path versus 33.671 ms for fallback (about 1.01x). This small saving does not
materially advance the 50x-per-subroutine target; the canonical full gate must
be rerun after this change.

Prompt option parser refinement (2026-10-13): NYTProf showed about 0.9 ms
exclusive in Getopt::Long initialization, plus callbacks and import work. A
red-first Docker check showed `ps1` loading it for the canonical flags emitted
by generated shell prompts. The helper now parses exact canonical options
locally and loads Getopt::Long only for unsupported or abbreviated syntax.
Tests cover value parsing, invalid numeric fallback, abbreviation support,
output parity, and warnings. An alternating 40-pair cold-process control
measured 29.338 ms without Getopt::Long initialization versus 33.174 ms with it
preloaded (about 1.13x). This only quantifies module startup savings; it does
not meet the 50x-per-subroutine target. A 30-pair public-command control also
measured 65.535 ms without Getopt::Long preloaded versus 72.307 ms with it
(about 1.10x), so the saving survives switchboard dispatch. Focused Docker
lazy-loading and dispatcher tests passed 146 assertions; the canonical full
gate must be rerun after these changes.

Installed-skill config scan refinement (2026-10-13): a preliminary `ps1`
NYTProf trace in the disposable bench container (its image HOME, with no host
home mount; not a hermetic skill fixture) showed Config resolving 30 skills
with one `skill_layers` scan per skill, producing 40 `runtime_roots` calls.
The synthetic benchmark used its own temporary home. A new PathRegistry grouped
inventory returns each selected skill root and all its layers in one pass;
Config uses it for collector and API-key reads without changing layer
precedence or disable semantics. Red-first Docker tests verify deepest-root
selection, home-to-project ordering, disabled masking, and that Config does
not call `skill_layers` for each skill. Focused tests passed. A synthetic
benchmark with 50 skills across four layers checked exact serialized parity
and measured 4.431 ms for the former repeated-scan path versus 3.409 ms grouped (about 1.30x). This is a
metadata routine benchmark, not the full dashboard or the 50x target; full
coverage and security gates must be rerun after the changes.

### Problem 48 nested skill-alias chain reuse (2026-10-13) — in progress

The corrected checkout NYTProf trace showed nested alias merging rediscovered
the same skill layer chain to determine each entry's writable config location.
PathRegistry now optionally returns that location with its nested-skill
inventory; Config reuses it. Red-first Docker coverage confirms the existing
git-managed ancestor/global fallback behavior and fails if alias merging
resolves the chain again. Additional cases reject malformed and mismatched
pre-resolved chains. Four focused suites passed 564 tests. A synthetic
50-skill/two-layer/two-depth benchmark preserved exact serialized output and
measured 4.216 ms on the repeated resolver path versus 2.347 ms with chain
reuse (about 1.80x). This is a scoped routine improvement only; Problem 48's
50x target and full SDLC gates remain open.
The post-change checkout NYTProf call trace shows read-side alias discovery
using the already-resolved chain helper rather than the public resolver.

### Nested inventory validation follow-up (2026-10-13) — in progress

The next checkout NYTProf profile attributed 12.1 ms inclusive / 3.60 ms
exclusive to `nested_skill_entries`; it was revalidating each segment once for
every chain prefix. A new Docker red test failed with the prior repeated-call
counts. The inventory now validates each discovered segment once and carries
the nearest git-free ancestor forward; the strict public resolver still
validates independently. Docker parity tests cover top-level/global,
git-managed, deeper, and invalid-name cases. Three focused suites pass 301
tests. An alternating synthetic 50-skill/two-depth benchmark measured 5.407 ms
before versus 2.048 ms after (about 2.64x) with exact canonical JSON parity.
The fresh checkout trace measured the nested inventory at 6.89 ms inclusive /
1.06 ms exclusive. This improves one routine only; the 50x target and Problem
48 delivery gates remain open.

### Reuse nested inventory across path and Folder aliases (2026-10-13) — in progress

The latest `paths -o json` profile showed the Config reader and Folder.pm
discovery each traversing nested skills. A red-first Docker test observed two
`nested_skill_entries` calls. The command now passes one inventory to both
consumers. It carries disabled state to preserve the prior rule: Config reads
its explicit include-disabled data, but disabled Folder providers and all
their descendants remain excluded. Malformed shared inventory/options produce
direct errors. Five Docker suites pass 354 tests. The post-change checkout
profile confirms one nested inventory call rather than two. An alternating
50-skill, two-depth benchmark produced byte-identical canonical JSON and measured
4.355 ms for separate scans versus 3.317 ms shared (about 1.31x). This is a
scoped alias-path gain; the 50x-per-subroutine objective and full delivery
gates remain open.

### Share skill config inventory for path aliases (2026-10-13) — in progress

A red-first Docker regression found that `Config::path_aliases` loaded the
installed-skill config inventory once through `merged()` and again while
building the skill-qualified alias view. Config now builds that inventory once
and passes it to both consumers; validation rejects malformed shared options
and rows explicitly. The five focused Docker suites pass 360 tests. A synthetic
50-skill/two-layer benchmark preserved canonical JSON and measured 4.304 ms
with two inventories versus 2.342 ms with one (about 1.84x). This is a scoped
routine gain; Problem 48's 50x target and full SDLC gates remain open.

### Normalize runtime-layer candidate paths once (2026-10-13) — in progress

A fresh checkout profile showed repeated canonicalization of the same
candidate as `runtime_layer_root_for` checked several runtime roots. A
red-first Docker regression failed with three candidate identity resolutions;
it now passes with one, while every root still receives its own current
filesystem resolution and component-boundary comparison. The PathIdentity
parity suite and related focused Docker suites pass 438 tests. A 100-pair,
five-root benchmark preserved the selected-root result and measured 0.059 ms
before versus 0.042 ms after (about 1.41x). This is a narrow helper gain; the
50x-per-subroutine target and remaining SDLC gates are open.

### Merge only the skill path-alias config domain (2026-10-13) — in progress

Path-alias output consumes only each skill's `path_aliases` field. The reader
now merges that domain across the grouped skill layers, instead of recursively
merging unrelated config fields and full `_skill-name` namespaces. A red-first
Docker assertion caught the old unrelated-field merge; seven focused suites
pass 676 tests with identical alias output. On a synthetic 50-skill/two-layer
fixture with 80 unrelated fields, 30 alternating pairs measured 22.262 ms
before versus 9.774 ms after (about 2.28x). This scoped result is far below
50x; the full objective and SDLC gates remain open.

### Problem 48 full Docker verification recheck (2026-10-13) — in progress

The first full Docker run omitted an init/reaper and failed five
process-descendant test files; those files passed 277/277 with Compose
`init: true`. Red-first assertions now cover malformed Config inventory inputs
and nested-skill write-location/disabled-state conditions. The final full
Compose-init gate passes 263 files / 23,604 tests and reports 100.0% statement,
branch, condition, and subroutine coverage across `lib/` (47,304 detail rows,
no stale uncoverable annotations). Browser, Windows-QEMU, kwalitee,
CPAN-audit, and Docker-daemon-only checks have documented environment/tool
skips. Coverage is closed for this revision; Problem 48 remains open because
the 50x performance objective and remaining SDLC gates are not met.

### Problem 48 request-scoped runtime-layer discovery (2026-10-13) — in progress

The fresh 50-skill NYTProf profile found 15 calls to
`_ancestor_runtime_layers` from `runtime_layer_root_for` during one `paths`
request. `all_paths` now shares candidate discovery only within that aggregate
operation; no registry-wide memo is retained. Red-first Docker coverage failed
at 16 walks before the change, then passed with at most two in the test fixture.
A separate regression confirms a later lookup finds a project `.d2` layer
created after `all_paths` returned. A 15-lookup parity benchmark measured
1.162 ms without the scope versus 0.305 ms with it (about 3.81x). NYTProf
recorded five total ancestry walks in the full 50-skill profile, down from 16;
instrumented whole-command timing varied and is not claimed as a speedup. This
does not meet the 50x-per-subroutine target; Problem 48 remains in progress.

### Paths JSON renderer import follow-up (Problem 48, 2026-10-13)

A red-first Docker regression failed because the JSON-only `paths` helper
loaded `Developer::Dashboard::CLI::TableHelpers` at module import. `Paths.pm`
now builds its path registry directly and requires TableHelpers only inside
human/table output branches. Focused Docker tests verify the JSON helper does
not load the renderer, table output still loads it and preserves headings, and
the standalone FindBin fallback remains byte-identical. Thirty alternating
cold helper launches measured medians of 29.030 ms (lazy) and 29.210 ms (with
TableHelpers forced eager), about 1.006x. This is a negligible startup change,
recorded as import hygiene rather than a material speed claim. Problem 48's
50x-per-subroutine goal remains unmet.

### PBKDF2 native-path test coverage follow-up (2026-10-13)

The full gate reported the Problem 48 PBKDF2 adapter at 63.4% total coverage
because the Docker image lacks optional FFI packages, leaving native-success
and error branches unexercised. `t/651-crypto-pbkdf2-ffi.t` now provides a
deterministic fake FFI boundary independent of installed modules or system
`libcrypto`. It verifies cached and lazy initialization, digest parity,
UTF-8 byte-boundary decline, signed-int input limits, short-output rejection,
missing/empty library discovery, null digest, and native call failure. The
Docker test passes 54 assertions, and an isolated Devel::Cover run reports
100.0% statement, branch, condition, and subroutine coverage for
`Crypto::PBKDF2.pm`. The subsequent full Docker gate passed 263 files / 23,272
tests and reports 100.0% statement, branch, condition, and subroutine coverage
across `lib/` (47,329 detail rows; no stale uncoverable annotations).
`perldoc perlsec` also completed successfully in the benchmark container.
Coverage is now verified for this worktree; Problem 48's 50x-per-subroutine
objective is still open.

### Problem 48 request-scoped installed-skill directory inventory (2026-10-14)

The 50-skill NYTProf trace found that one `paths -o json` invocation read the
same top-level skills directories twice: once for nested-skill discovery and
again for layered Config entries. A red-first Docker test observed two
`skills_roots` calls where a shared request snapshot should need one. The
PathRegistry now shares only sorted directory names for the lifetime of one
`run_paths_command`; disabled markers are still checked by each consumer, and
the scope is discarded before the next command. The test creates a new skill
after the scope and confirms the next inventory sees it. Four focused Docker
suites passed 5,860 tests. A two-layer 50-skill microbenchmark preserved
canonical output and measured 1.465 ms per paired inventory without sharing
versus 1.136 ms with sharing (about 1.29x). Matched NYTProf command time moved
from 15.9 ms to 14.9 ms under instrumentation. This modest scoped gain does
not meet the 50x-per-subroutine objective.

### Problem 48 MCE config-workload benchmark (2026-10-14)

To test MCE against an actual candidate workload rather than synthetic sleeps,
the scoped Docker container read and decoded 50 on-disk JSON config fixtures,
each with 80 unrelated fields and one path alias, then compared the canonical
alias output byte-for-byte. Serial median was 1.125 ms. Four-worker MCE took
4.944 ms on its first map call and 1.440 ms median with workers already warm
(0.78x versus serial). This does not justify parallel config loading in the
one-shot CLI; MCE remains useful only where measured independent work exceeds
its worker and data-transfer overhead. The full Problem 48 objective remains
open.

### Problem 48 MCE scaling at large config counts (2026-10-14)

An isolated Docker benchmark processed ordered, independent JSON configs with
10,000 and 20,000 fixtures (80 unrelated keys plus one alias each). Exact
serial/MCE result parity held. At 10,000 entries, four-worker warmed MCE was
290.222 ms versus 369.181 ms serial (1.27x). At 20,000, four workers measured
393.896/490.490 ms (1.25x) and eight workers 341.180/435.242 ms (1.28x).
First-map timing ranged from 0.98x to 1.63x serial. This is a 25–28% gain on
an unusually large synthetic config-read workload, not 50x; production config
loading remains serial. Problem 48 remains open.

### Problem 48 SPVM HMAC boundary benchmark (2026-10-14)

The container's SPVM SHA module produced matching SHA-256/HMAC bytes after
converting its SPVM string result to binary. Over 30,000 chained HMAC-SHA256
iterations, the Digest::SHA XS loop measured 40.680 ms median; calling SPVM
from Perl and converting each result measured 182.891 ms (0.22x). Thus a
per-iteration Perl/SPVM boundary is slower despite exact parity. This does not
test a PBKDF2 loop compiled wholly inside SPVM. A follow-up benchmark kept the
entire 210,000-round PBKDF2-HMAC-SHA256 loop inside an SPVM method. Five
alternating Docker runs produced exact digest parity among Perl, OpenSSL FFI,
and SPVM. Median timings were Perl 284.853 ms, SPVM 522.992 ms (0.54x Perl
speed), and OpenSSL FFI 31.834 ms (8.95x Perl speed); SPVM load/compile took
48.842 ms and was excluded from routine medians. The full-loop SPVM approach
is slower and is rejected for production. Reproduction is provided by
`script/problem48-spvm-benchmark`; `t/655-spvm-hmac-loop.t` checks its fixture's
digest contracts. Problem 48 remains open.

### Problem 48 verification refresh (2026-10-14)

After adding the compiled-SPVM benchmark fixture, the complete scoped Docker
coverage gate passed 264 files / 23,284 tests and reported 100.0% statement,
branch, condition, and subroutine coverage across `lib/` (47,343 detail rows,
no stale uncoverable annotations). Nine optional/environment-dependent tests
reported explicit skips; this includes the optional SPVM test in the full-gate
environment, while the targeted SPVM test passed all five assertions in the
benchmark container where its dependencies are installed. The required
post-gate `perldoc perlsec` check succeeded. These checks do not satisfy the
50x-per-subroutine target; the full security, integration, dependency, release,
artifact, and delivery gates remain pending.

### Problem 48 aggregate-scoped path identity reuse (2026-10-14)

The current NYTProf map showed path normalization repeated during the aggregate
`all_paths` operation. A red-first Docker regression failed before the change:
the same input was normalized twice in an explicit scope, and `all_paths` did
not open an identity scope. `PathRegistry` now memoizes exact input spellings
only for the duration of `all_paths`; after return, later calls resolve the
filesystem again. The focused Docker suite passes 281 assertions. A 51-pair
alternating benchmark preserved byte-identical 1,171-byte JSON and measured
0.576 ms uncached versus 0.424 ms scoped (1.36x for `all_paths`). The absolute
gain is about 0.15 ms in a sub-millisecond routine and does not establish the
50x target. Full Docker coverage and post-gate perlsec must be rerun after this
source change; Problem 48 remains open.

### Problem 48 post-change coverage/security verification (2026-10-14)

The full scoped Docker gate was rerun after the PathRegistry change and passed
264 test files / 23,292 tests. Statement, branch, condition, and subroutine
coverage are all 100.0% across `lib/` (47,360 detail rows, no stale
uncoverable annotations). Nine optional/environment-dependent tests skipped
with explicit reasons. The SPVM test passed separately in its dependency-ready
container. After the gate, `perldoc perlsec` succeeded (29,990 bytes). The
performance objective and remaining integration/release/delivery gates remain
open.

### Problem 48 nested-skill marker check (2026-10-14)

`nested_skill_entries(include_disabled => 1)` redundantly checked the top-level
skill's `.disabled` marker: once while listing installed roots and again while
building the traversal queue. A red-first Docker regression observed the
duplicate check; after the change, each root marker is checked once and empty
inputs remain safe. `include_disabled` now skips the unnecessary filter stat,
leaving the queue's live marker check authoritative. Exact output parity held
in 51 paired runs over 50 skills (0.599 ms to 0.496 ms, 1.21x) and 31 paired
runs over 250 skills (3.089 ms to 2.585 ms, 1.19x). The current full Docker
gate passed 264 files / 23,296 tests with 100.0% statement, branch, condition,
and subroutine coverage across `lib/` (47,375 detail rows); nine
optional/environment-dependent tests skipped with explicit reasons. The
post-gate `perldoc perlsec` check succeeded. Problem 48's 50x-per-subroutine
goal remains open.

### Problem 48 cold-process performance floor evidence (2026-10-14)

An alternating Docker control launched 25 fresh `bin/dashboard version`
processes and 25 fresh bare Perl processes with the same interpreter. The
medians were 32.424 ms and 1.263 ms respectively. Against the recorded v5.88
dashboard median of 56.7 ms, a 50x result requires 1.134 ms total, less than
the bare-interpreter median before the command body executes. This establishes
that a cold Perl process cannot meet the command-level target on this runtime.
A resident or native entry path is necessary, but the resident candidate still
requires complete mutation-invalidation and output-parity evidence. This does
not satisfy the separate per-subroutine target.

### Problem 48 refreshed NYTProf path profile (2026-10-14)

A new Docker NYTProf run exercised the current `paths -o json` implementation
with 50 synthetic skills, each containing one valid path-alias config; the
result was 2,969 bytes. Exclusive profiler line totals attributed 3.341 ms to
the PathIdentity import boundary, 2.937 ms to Config's JSON import boundary,
2.032 ms to 50 config-path constructions, 0.520 ms to 50 disabled-marker
checks, and 0.285 ms to 100 JSON decode lines. These are instrumented line
timings, not wall-clock improvements, and import totals include one-time
initialization. This indicates the marker-stat optimization is no longer the
next profile target. The 15-pair MCE scaling benchmark preserved exact ordered
output at 50, 250, 1,000, and 5,000 configs. With four workers and a fresh
pool per size, cold ratios versus serial were 0.21x, 0.90x, 0.97x, and 0.89x;
warmed ratios were 0.92x, 1.18x, 1.13x, and 1.18x. MCE module import was
excluded, so cold MCE cost is understated. Cold one-shot MCE was slower at all
tested sizes; no production use is justified.

### Problem 48 full gate after MCE benchmark test (2026-10-14)

The full Docker test gate passed 265 files and 23,316 tests. Statement, branch,
condition, and subroutine coverage each measured 100.0% across `lib/` (47,375
detail rows, without stale uncoverable annotations). Nine optional or
environment-dependent test files reported explicit skips; three MCE-specific
assertions also skipped because MCE is optional and absent from the standard
gate image. The focused MCE-enabled Docker test passed all 11 assertions.
Post-gate `perldoc perlsec` succeeded (29,990 bytes). These results validate
the current test gate, not the 50× performance objective or remaining delivery
gates.

### Problem 48 Inline::C/XS and Memoize benchmark gate (2026-10-14)

After adding the reproducible Inline::C/XS and operation-scoped Memoize
benchmarks and their regression tests, the full isolated Docker coverage gate
passed 267 files / 23,366 tests. Statement, branch, condition, and subroutine
coverage were 100.0% across `lib/` (47,381 detail rows, with no stale
uncoverable annotations). Optional/environment-dependent tests reported
explicit skips. Both new benchmark test files passed in that run, the new
scripts and test files passed Perl syntax and POD checks, and the required
post-gate `perldoc perlsec` check passed. This verifies test coverage and
security-document checks for the iteration; it does not meet the 50x
all-subroutine performance target.

### Problem 48 Inline::C/XS PBKDF2 comparison (2026-10-14)

A new reproducible benchmark and red-first regression compare the Perl
PBKDF2-HMAC-SHA256 reference, the existing FFI adapter, and an Inline::C
generated XS wrapper that invokes the same OpenSSL API. Docker tests pass nine
assertions and all implementations return identical digests. At the production
210,000-round work factor, five runs measured 287.413 ms Perl, 31.073 ms FFI
(9.25x), and 31.379 ms Inline::C/XS (9.16x); Inline compilation added 610.263
ms outside the routine medians. Inline adds no meaningful improvement beyond
FFI and remains benchmark-only. Problem 48 remains open.

### Problem 48 request-scoped Memoize comparison (2026-10-14)

A new nine-assertion Docker regression verifies exact results and symlink
refresh for uncached path identity, an operation-local hash, and Memoize
flushed at each operation boundary. Across 15 runs of 1,000 unique paths
repeated twice, medians were 7.705 ms uncached, 4.246 ms with the local hash
(1.81x), and 5.006 ms with Memoize (1.54x). Memoize is slower than the existing
scoped hash and is not adopted. The 50x-all-subroutine target remains unmet.

### Problem 48 resident path-context parity and mutation probe (2026-10-14)

A new Docker prototype reuses PathRegistry/Config objects across path requests,
but refreshes current directory, object memo state, configured aliases, skill
inventory, config contents, and dynamic Folder.pm providers each time. Ten
focused assertions passed exact output parity against a fresh helper and
verified config replacement, changing a Folder.pm environment dependency, and
skill addition/removal between requests. Nine alternating runs over 50 skills
measured 29.336 ms for the fresh helper and 6.719 ms for the resident handler
(4.37x). This does not establish a 50x route and does not justify a production
daemon. Problem 48 remains open.

### Problem 48 full Docker coverage/security gate after resident-context probe (2026-10-14)

The isolated full Docker suite passed 268 files and 23,385 tests. The canonical
coverage gate reported 100.0% statement, branch, condition, and subroutine
coverage across `lib/` (47,381 detail rows; no stale uncoverable annotations).
Environment-dependent checks explicitly skipped, including missing
`cpan-audit`, unavailable browser loopback, an unreachable Docker daemon,
optional SPVM/kwalitee tooling, and operator-local `.claude` specs. The
benchmark-only SPVM test also skipped in the standard image. Post-gate
`perldoc -t perlsec` passed, `git diff --check` was clean, and the scoped
Problem 48 Compose project had no remaining containers. These gates do not
establish the 50x all-subroutine performance target or finish Problem 48.

### Problem 48 built-in Perl object/signature probe (2026-10-14)

In the isolated Perl 5.40.1 Docker runtime, a seven-run alternating probe
compared two million blessed-hash method calls with built-in
`class`/`field`/`method` calls, and ordinary subs with signature subs. Results
matched exactly. Medians: conventional method 179.731 ms; built-in object
230.533 ms (0.78x relative speed); ordinary sub 142.308 ms; signature sub
196.421 ms (0.72x). Perl emitted experimental warnings for class, field, and
method. The feature path is not adopted because it is slower and violates the
warning-free gate; warnings were not suppressed. This synthetic probe does
not establish project-wide or 50x gains. Problem 48 remains open.

### Problem 48 validated working-directory lookup recheck (2026-10-14)

A red-first Docker assertion verifies the ordinary absolute `$PWD` match uses
the direct `getcwd` result while distinct logical symlink paths still require
device/inode validation. The focused suite passes 17 assertions, including the
empty-getcwd fallback. Seven alternating 100,000-call runs measured 262.482 ms
for the previous current-branch implementation, 52.454 ms after the change,
and 41.729 ms for a same-subroutine v5.88 `eval { getcwd() }` wrapper. This is
5.00x faster than the previous current implementation but only 0.80x baseline
speed; it is not claimed as a v5.88 performance win. Problem 48 remains open.

### Problem 48 full Docker coverage/security gate after working-directory recheck (2026-10-14)

The isolated suite passed 268 files / 23,388 tests. The canonical gate reports
100.0% statement, branch, condition, and subroutine coverage across `lib/`
(47,390 detail rows, no stale uncoverable annotations). Environment-dependent
checks explicitly skipped with reasons. Post-gate `perldoc -t perlsec` passed,
as did POD syntax and `git diff --check`. The 50x all-subroutine objective and
remaining delivery gates are still open.

### Problem 48 resident-context scaling check (2026-10-14)

The resident prototype was measured with 250, 1,000, and 5,000 synthetic
skills, three alternating runs per size. Exact response parity and refresh
checks for config replacement, `Folder.pm` environment changes, skill creation,
and deletion passed. Fresh/resident medians were 38.091/13.887 ms (2.74x),
75.883/50.994 ms (1.49x), and 236.497/226.402 ms (1.04x). This confirms that
context reuse alone loses its benefit as filesystem discovery grows. The next
experiment will measure safely invalidated inventory/config caching while
still executing user `Folder.pm` code for every request. Problem 48 remains
open.

### Problem 48 application-level MCE alias benchmark (2026-10-14)

A nine-assertion Docker regression now checks a benchmark against the real
`Config::path_aliases` API: installed skill discovery and layered alias config
reads are measured, while production merge, alias qualification, and expansion
remain in use. Canonical serial output matched for all cold and warmed MCE
results. At four workers, serial/MCE warmed medians were 48.332/52.719 ms for
1,000 skills (0.92x), 300.048/350.766 ms for 5,000 (0.86x), and 619.155/587.044
ms for 10,000 (1.05x). At eight workers, they were 284.234/302.021 ms for
5,000 (0.94x) and 625.528/662.299 ms for 10,000 (0.94x). The 10k/four-worker
gain is not stable across worker counts, so MCE is not justified in production
config loading by this evidence. This rejects that integration path rather
than the Problem 48 objective; the 50x-per-subroutine target remains open.

A longer nine-run four-worker recheck at 10,000 skills again preserved exact
alias output and measured 671.440 ms serial versus 635.286 ms warmed MCE
(1.06x). That small synthetic gain does not justify adding worker lifecycle
complexity to normal config loading and does not materially advance the 50x
target.

### Problem 48 Docker coverage/security gate after application-level MCE probe (2026-10-14)

The isolated coverage gate passed 269 files and 23,406 tests. Statement,
branch, condition, and subroutine coverage were each 100.0% across `lib/`
(47,390 detail rows; no stale uncoverable annotations). The standard image
explicitly skipped optional/environment-dependent checks for cpan-audit,
operator-local `.claude` specs, browser loopback, the post-build Docker guard,
SPVM, Test::Pod, and release kwalitee tooling. The MCE-enabled focused test was
run separately and passed exact alias parity. Post-gate `perldoc -t perlsec`,
benchmark script syntax/POD checks, and `git diff --check` passed. This closes
the current test/coverage gate only; it does not meet Problem 48's 50x target
or complete release/integration gates.

### Problem 48 operation-scoped ancestor discovery (2026-10-14)

A red-first Docker test found that all_paths walked ancestor runtime layers
twice: once while resolving runtime_layers and again while checking protected
paths. The existing operation-local scope now shares that ancestor list across
both call paths. A focused assertion verifies exactly one walk; unscoped
lookups remain fresh so later calls see runtime-layer changes. The focused
PathRegistry and I/O suites passed 325 assertions, and 51 alternating
all_paths benchmark runs retained exact JSON parity. This removes duplicate
work but is not claimed as a 50x speedup. Problem 48 remains open.

### Problem 48 full Docker verification after ancestor-walk change (2026-10-14)

The first full gate caught a README/POD generation mismatch introduced while
documenting the change; the canonical README was synchronized and the targeted
release-metadata test passed. The rerun then passed 269 files and 23,406 tests.
All four coverage dimensions are 100.0% across lib/ (47,408 detail rows, no
stale uncoverable annotations). Optional and environment-dependent checks
reported their explicit skips. Post-gate perlsec, Perl syntax/POD checks, and
git diff --check passed. This verifies the current code/docs gate, not the
50x-per-subroutine objective or the remaining packaging/release gates.

### Problem 48 indicator-list optimization (2026-10-14)

NYTProf on the actual `/system/status` route attributed 5.534 ms inclusive to
`IndicatorStore::list_indicators`. It found that the method resolved indicator
roots for enumeration and then repeated the same resolution for each record. A
red-first Docker test reproduced five root scans for four records; listing now
resolves the roots once and passes them to a private reader. Root precedence,
fresh file reads, and sorted output remain unchanged. The focused suites passed
242 assertions and the reproducible benchmark test passed 12. Nine paired
Docker runs with exact JSON parity measured 8.06x for one layer and 12.15x for
two layers. These targeted gains do not meet the 50x all-subroutine objective.
The full Docker gate then passed 270 test files / 23,433 tests with 100.0%
statement, branch, condition, and subroutine coverage across lib/ (47,422
detail rows); post-gate perlsec passed. Optional/environment-dependent tests
reported explicit skips. Problem 48 remains in progress.

A follow-up tested direct reads from the directory currently being enumerated
to avoid probing deeper roots. The red-first read-count regression failed at
three versus two reads, then passed with the candidate. A three-way benchmark
isolated this from the prior root-discovery gain: over 15 paired Docker runs at
50 / 250 / 1,000 records, direct reads improved the intermediate implementation
by only 1.00x / 1.04x / 1.02x with exact JSON parity. Since the difference is
within noise, the production experiment was reverted; no unsupported speedup
claim is retained. Problem 48 remains in progress.

### Status-payload inventory reuse, Problem 48 follow-up (2026-10-14)

A Docker NYTProf run of `t/03-web-app.t` found two full indicator listings per
configured-collector status payload: collector reconciliation listed once for
orphan cleanup, then payload construction listed again. The profile recorded 88
`list_indicators` calls across 44 payload/summary builds. A red-first route test
required one listing and byte-identical response JSON. The sync method now
returns its final inventory for the response builder and refreshes it after
orphan deletion; its default written-record return remains unchanged. The
post-change profile recorded 46 listings across those same 44 builds and
reduced instrumented `_page_status_payload` time from 3.09 ms to 2.53 ms per
call (1.22x). The focused web, IndicatorStore, and collector suites passed 580
assertions. The overall 50x target remains unmet.

The canonical isolated Docker coverage gate then passed all 270 test files /
23,445 tests. Statement, branch, condition, and subroutine coverage were each
100.0% across `lib/` (47,452 detail rows), with no stale uncoverable
annotations. Optional environment/tool-dependent checks emitted explicit
skips. Post-gate `perldoc -t perlsec`, syntax and POD checks for both changed
modules, and `git diff --check` passed. This closes verification for this
iteration, not Problem 48's 50x-per-subroutine performance objective.

### Legacy bookmark parser performance follow-up (Problem 48, 2026-10-14)

The web-test NYTProf profile attributed 482 ms exclusive to
`PageDocument::_parse_legacy_sections` over 148 calls. A red-first Docker test
confirmed each `CODE1000` section scanned all 1,008 entries in `@LEGACY_KEYS`.
The optimized parser uses a fixed-name lookup plus the existing digit-based
CODE rule, preserving the observed acceptance of `CODE1001`. Exact-output,
21-run Docker comparisons measured 122.13x for 10 CODE sections and 127.47x
for 1,001; the matched web-test profile then measured 3.59 ms exclusive across
the same 148 calls. This is a large parser-specific gain, not proof of the
50x-every-subroutine objective. The full Docker gate passed 270 test files /
23,448 tests with 100.0% statement, branch, condition, and subroutine coverage
across `lib/` (47,455 detail rows) and no stale uncoverable annotations.
Optional tooling/environment checks emitted explicit skips. Post-gate
`perldoc -t perlsec`, syntax and POD checks, release-metadata tests, and
`git diff --check` passed.

### Home-root identity reuse follow-up (Problem 48, 2026-10-14)

In the same Docker NYTProf web-test workload, `PathRegistry::_ancestor_runtime_layers`
ran 3,373 times and took 72.2 ms exclusive. A red-first Docker test found the
selected home runtime path was canonicalized twice while building the exclusion
set because it also appeared in the enumerated home-layer list. The method now
deduplicates identical path spellings before identity resolution; canonical and
`.d2` sibling paths are still independently checked. The same profiled workload
retained 3,373 calls and fell to 56.4 ms exclusive (1.28x). Focused PathRegistry
and web tests passed 631 assertions. The full Docker gate then passed 270 test
files / 23,450 tests, with 100.0% statement, branch, condition, and subroutine
coverage across `lib/` (47,461 detail rows) and no stale uncoverable annotations.
Optional environment checks emitted explicit skips. Post-gate `perldoc -t
perlsec`, syntax/POD, release-metadata, and diff checks passed. The 50x target
for every Dashboard subroutine remains unmet.

### Verified-PWD lookup matched-path recheck (Problem 48, 2026-10-14)

An alternating 21-pair Docker microbenchmark matched the prior shell-backed
`Cwd::cwd` call path against the direct-getcwd helper: 1.7025 ms/call versus
0.0009 ms/call (1,891.6x), with equal physical-path output. The common path
calls native `getcwd` once and returns immediately for matching PWD; distinct
absolute PWD values are validated by device/inode to preserve logical symlinks.
This is a gain only against shell-backed `Cwd::cwd`, not native
`Cwd::getcwd`. The full Docker gate exposed one failure because the experimental
stat-first variant contradicted the pre-existing one-getcwd test; production
code and its new red-first test now agree with that contract. Focused
PathIdentity, PathRegistry, and web suites then passed 689 tests. The corrected
full gate passed 270 files / 23,458 tests with 100.0% statement, branch,
condition, and subroutine coverage across `lib/` (47,464 rows, no stale
uncoverables); optional tools/environment checks emitted explicit skips.
Post-gate perlsec rendered successfully. Problem 48 remains in progress.
### Problem 48 shared JSON object reuse (2026-10-14)

Red-first Docker probes reproduced the repeated constructor path in the shared
JSON wrapper: two encoder objects for two encodes and three decoder objects
across valid decode, malformed transient-state decode, then valid decode.
`JSON::XS` encoder/decoder objects with fixed configuration are now initialized
lazily and reused per interpreter. The regression checks canonical and UTF-8
behavior and proves malformed state input does not prevent a later valid decode.
The focused test passed 20 assertions in Docker. Alternating 21-pair Docker
benchmarks of 10,000 calls measured 1.41x for encoding and 1.17x for decoding
against per-call construction, with exact output parity. The corrected full
Docker gate passed 270 files /
23,465 tests with 100.0% statement, branch, condition, and subroutine coverage
across `lib/` (47,486 rows, no stale uncoverables); optional environment/tool
checks emitted explicit skips. Post-gate `perldoc -t perlsec` succeeded.
Problem 48's 50x-per-subroutine target is not met.

The next candidate, caching option-configured encoders by their three boolean
flags, was discarded after exact-output Docker benchmarks measured 0.93x for
default options and 0.96x for ASCII mode (21 alternating pairs, 10,000 calls).
Its key/hash overhead made both paths slightly slower than constructing the
small encoder per call. The candidate and red-first test were removed; no
production behavior from that experiment remains.

The next resident-cache option was checked against two portable watcher APIs.
The container's `Filesys::Notify::Simple` 0.14 exposes a blocking wait, relies
on optional platform backends, falls back to scans, and documents a 64-directory
Windows limit; `File::ChangeNotify` 0.31 offers nonblocking event polling but
is absent from the benchmark image and its default watcher uses a sleep loop.
Neither currently proves safe, fast cross-platform invalidation for this
runtime, so no watcher dependency or cache was introduced. Sources:
[Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple),
[File::ChangeNotify](https://metacpan.org/pod/File::ChangeNotify),
[watcher contract](https://metacpan.org/pod/File::ChangeNotify::Watcher).

### Request-scoped web settings snapshot (Problem 48, 2026-10-14)

The current Docker NYTProf web-test call tree showed a saved page request
resolving web settings independently in authorization and twice in page chrome.
A red-first route assertion counted three `web_settings` calls. A lazy,
request-local snapshot now serves all three callers and is discarded at the
request boundary, preserving visibility of configuration changes on later
requests. `Config::web_settings` also derives SSL validity from its current
merged config rather than loading configuration again. The tested page/status
route's merged-config reads fell from seven to one; collector assembly reuses
the same snapshot and skill entries. HTTP status and response content continue
to pass the focused Docker route tests. This measured path improvement does not meet
the 50x-every-subroutine target; Problem 48 remains open.

The first full coverage run passed all tests but found branch/condition totals
at 99.9%. Red tests were added for the uncovered config guards, SSL-value
normalization, and skill-entry output target. The corrected Docker rerun passed
271 files / 23,901 tests and reached 100.0% statement, branch, condition, and
subroutine coverage across `lib/` (47,644 detail rows; no stale uncoverables).
Optional tools and unavailable browser/platform/container environments were
reported as explicit skips. The performance objective remains open.

### Problem 48 request-scoped Template Toolkit service reuse (2026-10-14) — in progress

The web-test NYTProf call tree showed repeated Template Toolkit service
construction for PageRuntime renders. A red-first Docker test observed two
service constructions for two renders with the same include roots and now
requires one within an explicit request scope. The cache key includes the
ordered allowed roots and their current directory-existence state; a changed
root set gets a separate service. Web::App localizes that cache for a single
request, and direct PageRuntime calls without a request scope still construct a
fresh service. This keeps file changes visible on the next request rather than
retaining a worker-lifetime template provider.

The regression checks changing template stash data, resolving a newly created
include, changing include roots, and seeing a modified include immediately in a
new request scope. Undefined, reference-valued, and empty roots are filtered
before reaching Template Toolkit; if no usable root remains, the existing `.`
fallback is retained. Explicit compatibility tests cover Web::App dispatch
without PageStore/PathRegistry and with a non-PageRuntime provider. The focused
`t/03-web-app.t`, `t/390-page-modules-coverage.t`, and
`t/663-problem48-template-service-benchmark.t` Docker suites pass 397 tests. A
21-pair Docker microbenchmark with 500
exact-output renders per sample measured 0.1825 ms per fresh service/render
and 0.1248 ms per render when the service was reused within a request (1.46x).
This isolated Template Toolkit
gain is not end-to-end latency and does not meet the 50x target for every
subroutine. The final Docker coverage gate passed 272 files / 23,952 tests and
reported 100.0% statement, branch, condition, and subroutine coverage across
`lib/` (47,723 detail rows; no stale uncoverable annotations). Optional
environment/tool checks emitted explicit skips. Required web security suites
passed 459 tests; `perlsec`, module syntax, POD syntax, release-metadata, and
diff checks passed afterward. Problem 48 remains in progress because this 1.46x
local rendering improvement does not satisfy its all-subroutine 50x goal.

### Problem 48 request-local PathRegistry inventory sharing (2026-10-14) — in progress

Web::App now establishes request-local runtime-layer and installed-skill
inventory scopes; nested PathRegistry::all_paths reuses an existing
runtime-layer scope rather than shadowing it. A red-first web regression
records no more than two ancestor discoveries during the profiled saved-page
request despite the nested secure-permission check. The scopes restore at
request return, and later requests continue to observe configuration and
filesystem changes. Focused route/config tests pass; the subsequent full Docker
coverage gate passed. This is a bounded duplicate-scan reduction, not a 50x
performance claim.

### Problem 48 blank-environment release-verifier version extraction (2026-10-14)

The required blank-container tarball install gate failed before `cpanm`: the
integration runner searched only for a literal `$VERSION` assignment in
`lib/Developer/Dashboard.pm`, while this release delegates that value to
`Developer::Dashboard::Version`. The extracted distribution already contains
the authoritative `META.yml` version. A red-first regression reproduced the
failure by loading the runner and supplying a metadata-backed fixture. The
runner now reads the constrained `version` entry from `META.yml` first and
retains a literal-module fallback for older archives. Tests also prove that
metadata wins over a stale literal value and that helper loading does not
start the integration run. The focused Docker test passes. The full tarball
install gate must be rerun against a newly versioned archive; this verification
repair is not a performance gain and Problem 48 remains open.

### Problem 48 coverage-gate serializer marker warning (2026-10-14)

The full Docker run exposed Devel::Cover warnings because the coverage gate put
its reader-identity marker at `cover_db/gate-serializer`. Devel::Cover scans
that directory as database content and reports the marker as an invalid
database. A red-first Docker gate test reproduced this with an existing
database. The marker is now stored in a hidden sibling file, and the gate
validates then migrates the old in-database marker before dropping coverage
data. Focused `t/148-coverage-gate-entrypoint.t` passes without warnings. This
fixes the verification path; it does not improve dashboard runtime speed.

### Problem 48 static bookmark rendering fast path (2026-10-14) — in progress

Expected outcome: static bookmark and navigation HTML is returned unchanged,
while avoiding Template Toolkit setup that has no work to perform. Replication:
call PageRuntime template rendering with a non-empty body containing no default
percent-bracket opener, including a Unicode character, and observe the existing
path still builds request context, include roots, and a TT service.

Root cause: _render_templates initialized those objects before determining
whether the body contained a TT directive or include. A red-first Docker
regression observed three setup calls for static HTML and failed the new
zero-setup assertion. The renderer now returns early only for undefined,
empty, or opener-free bodies; TT-bearing content still uses the ordinary path.
The output test verifies exact Unicode parity.

In the isolated Docker benchmark, 21 alternating samples of 5,000 renders
measured 0.06436 ms for the legacy Template Toolkit process call and 0.00080
ms for the static PageRuntime path (80.66x for this isolated operation). A
confirmatory run on the final tree measured 0.06455 ms versus 0.00074 ms
(86.73x), with exact Unicode parity both times. This microbenchmark is not a
complete route comparison and does not prove the 50x-per-subroutine objective.
The isolated Docker full suite passed 272 files / 23,751 tests; statement,
branch, condition, and subroutine coverage each measured 100.0% (47,732 detail
rows). The required web security tests passed 459 assertions and `perlsec`
rendered successfully. Packaging and remaining delivery gates are still open.

### Problem 48 optional benchmark prerequisites blocked clean install (2026-10-14)

Expected outcome: a blank-environment `cpanm` install resolves only the
dashboard's actual runtime dependencies; optional performance engines must not
be required to install or test the product. Replication: build the source
tarball, then run `cpanm Developer-Dashboard-5.92.tar.gz` in the isolated blank
Docker environment without `--notest`.

The clean install failed because the generated metadata required `SPVM` and
`SPVM::Digest::SHA`. Their only consumers are optional Problem 48 experiments,
but Dist::Zilla `AutoPrereqs` scanned those test/benchmark files as install-time
dependencies. SPVM's upstream test suite then hit an AddressSanitizer
segmentation fault in its parallel-build test, and cpanm correctly refused to
install the dashboard. A red-first release-metadata test now requires these
benchmark-only modules, together with `MCE::Map` and `Inline`, to stay out of
generated required dependencies. `dist.ini` explicitly skips them; package
metadata and a fresh blank-container install must be rechecked after rebuilding
the archive. This is a packaging fix, not a performance result; Problem 48's
50x-per-subroutine target remains open.

### Problem 48 root-only auth permission fixture blocked blank install (2026-10-14)

The first blank install after optional benchmark dependency cleanup reached the
distribution suite but failed `t/82-auth-coverage.t` when the test dropped its
effective uid to verify an unreadable user record. Its temporary runtime tree
remained owned by root, so `PathRegistry` correctly failed while hardening that
tree before it could attempt the record read. This was a test-fixture problem,
not an authentication regression.

The red failure was reproduced in the blank Docker package install. The fixture
now assigns the temporary runtime directories and locked record to the dropped
uid before the privilege transition. The focused test passes both as the
ordinary container user and as root (60 assertions each); the latter exercises
the privilege-drop branch. A rebuilt 5.92 archive then passed `cpanm` without
`--notest` in the blank Docker environment, followed by the complete installed-
CLI and web integration flow (`Blank-environment integration run passed`).
This gate correction does not change Problem 48's performance measurements or
close its 50x-per-subroutine target.

### Problem 48 matched v5.88 static-render comparison (2026-10-14)

The v5.88 source at commit `a8d1fa2a4064640baba7a8ed7339462d9d3c3060` and the
current tree were measured in the isolated Docker service with the same static
render benchmark. Across 21 alternating samples of 5,000 renders,
`PageRuntime::_render_templates` measured 0.13501 ms per call at v5.88 and
0.00079 ms on the current tree (about 171x), with exact UTF-8 output parity.
This establishes a speedup for one routine and workload only, not for the
whole dashboard or every subroutine. Problem 48 remains open.

### Follow-up evidence: Problem 48 direct Dancer request scopes and state chmod (2026-10-14)

The real PSGI `/system/status` route was profiled after application startup and
three warm-up requests. Direct Dancer backend methods bypassed
`Web::App::handle()`, so authorization and route handling repeated runtime-layer
discovery without sharing the request-local filesystem view. A red-first Docker
test observed five ancestry scans across two reads; both authorized and
backend-only Dancer dispatch now scope runtime-layer and installed-skill
inventories to one request and discard them afterward. Eleven alternating
Docker pairs of 100 status requests preserved exact response bodies and measured
0.5984 ms/request without the scope versus 0.5696 ms/request with it (1.05x).

The profile also showed 1,300 PathRegistry chmod calls across 100 steady-state
requests. `_ensure_state_dir` now skips chmod only when an existing directory's
complete permission/special-bit mask is already exactly `0700`; other modes
retain the explicit chmod and error path. Red-first Docker I/O coverage proves
both paths. A 21-run Docker microbenchmark measured 0.002329 ms per call at
v5.88 versus 0.001290 ms currently (1.80x), and the profile recorded 100
remaining PathRegistry chmod calls across 100 requests. Focused Docker web and
PathRegistry suites passed 506 assertions.

The first full coverage attempt is not valid evidence: code/test files changed
while it ran, and the gate correctly refused to report coverage for that mixed
tree. It also exposed an operator-local `t/158` failure because the container
cannot resolve the `tira-ddd` project selector. A fresh run on a frozen tree is
required; no full-coverage percentage is claimed. These changes are incremental
and do not satisfy Problem 48's 50x-per-subroutine objective.

### Problem 48 coverage gaps found and closed (2026-10-14)

The fresh isolated Docker run completed all 272 test files / 23,601 tests, but
the strict coverage gate exited nonzero: the full library report showed 100.0%
statement/subroutine coverage, 99.9% branch coverage, and 99.9% condition
coverage. The two uncovered defensive paths were identified precisely:
`PathRegistry::_ensure_state_dir`'s failed `stat _` guard and
`Web::DancerApp::_with_request_scopes`'s non-hash app-reference guard. A
deterministic stat-failure injection test and an array-reference app test now
exercise those paths. Both focused Docker tests pass (157 assertions), and the
combined Devel::Cover report for `lib/` is 100.0% for statement, branch,
condition, and subroutine metrics. Because the focused rerun merged into the
earlier full-run database, it was followed by a clean full coverage gate. That
gate passed 272 test files / 23,603 tests and reported 100.0% across all four
coverage metrics for `lib/` (47,773 detail rows, no stale uncoverables).
Post-gate `perlsec`, syntax, POD, and diff checks passed. This closes only the
coverage/security-documentation checks; it does not meet the Problem 48
50x-per-subroutine performance objective or remaining release gates.

### Problem 48 request-scoped path identity reuse (2026-10-14)

A direct warmed PSGI profile of `/system/status` showed repeated canonical path
resolution. A baseline call counter found 1,300 `PathIdentity::_path_identity`
calls over 100 requests, with five exact path spellings repeated. A red-first
test observed two resolutions for the same path in each request. Dancer's
request scope now caches canonical identities by exact input spelling and
discards them on callback return; a second request resolves the path again.
The focused Docker route test passes 132 assertions. Across 100 byte-identical
558-byte status responses, calls fell from 1,300 to 600. Eleven alternating
Docker pairs measured 0.478 ms/request without the identity scope and 0.463
ms/request with it (1.03x). This is a small scoped improvement; the 50x-per-
subroutine objective and release gates remain open.

### Problem 48 request argument accessor reuse (2026-10-14)

A red-first test counted the current request-normalization calls and failed at
13 Dancer request acquisitions, four PSGI environment reads, and eight header
reads. `_request_args` now captures one request and environment and reuses its
normalized header map, retaining the same Host fallback and payload values.
The focused Docker test verifies one request acquisition, one environment
read, seven required header reads, and one body read. A canonical-JSON parity
probe compared 200,000 legacy-equivalent and optimized calls per arm across
five alternating rounds: 5.568 versus 3.665 microseconds/call (1.52x). This
does not establish the 50x-per-subroutine objective; Problem 48 remains open.

### Problem 48 PSGI header accessor reduction (2026-10-14)

The first request-normalization change still invoked Plack's `header()` method
seven times per dispatch. Inspection of the installed Plack implementation
showed that the method maps fixed HTTP header names from the standard PSGI
`HTTP_*` environment keys. A Docker parity probe confirmed all seven current
header values match exactly. A red-first regression then failed because the
adapter still used header accessors; `_request_headers` now reads the seven
fixed keys directly, obtains the environment once, and reports non-hash input
explicitly. The no-argument helper continues to use the active Dancer request.
Five alternating Docker pairs (200,000 calls per arm) preserved canonical
JSON payloads and measured 5.167 versus 2.578 microseconds per call (2.00x).
This remains a single-helper gain, not the requested 50x for every routine.

### Problem 48 MCE indicator-list experiment (2026-10-14)

An isolated Docker experiment compared the actual current
`IndicatorStore::list_indicators` output with an ordered MCE map over the same
names, runtime roots, record reader, and priority sort. Canonical JSON matched
exactly. Nine alternating warm pairs measured serial/MCE medians of
1.546/6.940 ms for 50 indicators, 20.020/22.656 ms for 1,000, and
97.739/78.368 ms for 5,000. A separate fresh-process 5,000-record sample
measured the first MCE call at 63.449 ms versus 93.633 ms serial, while warm
MCE measured 89.454 ms. MCE regresses ordinary sizes, and its large-inventory
gain is inconsistent and modest; the parallel implementation is not adopted.
This evidence does not meet Problem 48's 50x-per-subroutine target.

### Problem 48 indicator sorting fast path (2026-10-14)

A Docker microbenchmark isolated the indicator sort and found repeated method
dispatch and hash lookups in each comparator call. A red-first test confirmed
that large lists used the existing comparator. Lists of at least 32 records
now decorate each item with its comparison fields once, sort the tuples, and
return the original item references; small lists retain the shared comparator.
On identical ordered inputs, 21 alternating pairs preserved exact sort order
and measured 16.240 ms legacy versus 10.763 ms decorated sorting (1.51x) for
5,000 records, with exact order parity. Full two-layer filesystem/list
benchmarks measured 1.04x, 1.14x, and 1.06x at 50, 1,000, and 5,000 records,
respectively, with exact canonical JSON output. The isolated sort gain does
not transfer to the full workload, and Problem 48's 50x-per-subroutine
goal remains open. Repeated coverage runs showed Perl's sort schedule did not
reliably hit every short-circuit pair. The decorated-tuple comparison is now
a small private function with direct tests for all priority, collector-order,
and name-fallback combinations. The final clean Docker gate passed 272 files /
23,628 tests and measured 100.0% statement, branch, condition, and subroutine
coverage across lib/ (47,832 detail rows, no stale uncoverable annotations).
Post-gate perlsec passed; required web-security tests passed 459 assertions;
changed module/test syntax and POD checks passed. Problem 48 remains open
because the measured localized gains do not meet the all-subroutine 50x target.

### Problem 48 File::Spec path assembly candidate (2026-10-14)

The matched `paths` profile highlighted 50 calls to `File::Spec->catfile` in
skill config lookup. A Docker microbenchmark appeared promising, so the
candidate was tested in the full `_skill_config_hash` path with 50 on-disk
config files, including existence checks, reads, JSON decoding, and merges.
Across 21 alternating pairs of 20 calls, direct joining measured 11.676 ms
versus 12.367 ms with `File::Spec` (1.06x). The small full-path gain does not
justify giving up platform-aware path construction. The candidate was rejected
and no production code changed. Problem 48 remains open.

### Problem 48 current-directory identity candidate (2026-10-14)

The current `current_working_directory` helper had measured 0.80x the v5.88
helper in an earlier matched benchmark. A candidate that validates absolute
`PWD` against `.` using device/inode stats before falling back to `getcwd` was
tested in Docker. Across 25 alternating pairs of 100,000 same-directory calls,
the candidate took 248.306 ms versus 56.970 ms for the current helper (0.23x).
The extra stats are substantially slower, so no code was changed. Problem 48
remains open.

### Problem 48 current web-test profile follow-up (2026-10-14)

A fresh NYTProf profile of `t/03-web-app.t` passed 351 tests. It ranked the
PBKDF2 fallback and PathRegistry layer discovery among the largest project
costs; optional FFI modules were absent from the default bench `@INC`, so the
PBKDF2 result is not the native path. Direct instrumentation corrected a
misleading `IO::Select::can_read` stack count to 15 real calls. A combined
single-regex `_normalized_page_id` candidate had exact representative-output
parity but measured 0.93x over 25 alternating Docker pairs of 100,000 calls.
It was rejected without production changes. Problem 48 remains open.

### Problem 48 isolated skill-path profile and MCE scale check (2026-10-14)

NYTProf was enabled only around the actual `paths -o json` operation over 250
installed skill configs. The command produced valid JSON (13,715 bytes, 264
aliases). `Config::path_aliases` measured 14.7 ms inclusive under the profiler;
250 `_skill_config_hash` calls accounted for 2.8 ms exclusive, 250 disable
checks for 1.56 ms, and nested skill discovery 11.5 ms inclusive. A production-
API MCE comparison at the same 250-skill scale preserved exact aliases but
regressed: serial 14.400 ms, MCE 20.677 ms warmed and 19.209 ms cold (0.70x
and 0.75x relative speed). MCE is not adopted. Problem 48 remains open.

### Problem 48 cross-reader marker-cache candidate (2026-10-14)

Expected outcome: avoid duplicate disabled-marker filesystem checks across
the nested-skill and layered-config reads without changing `paths -o json`.
Reproduction: in one inventory scope, enumerate `nested_skill_entries` and
then `installed_skill_entries` over 250 skills. The red-first test observed
the same top-level marker in both readers. A request-local cache candidate
passed canonical JSON parity, but 31 alternating Docker pairs measured 7.811
ms without it and 7.814 ms with it (1.00x). Since it did not improve runtime,
the candidate and test were removed. No production change remains from this
cycle; Problem 48 remains open.

### Problem 48 builtin class/signature dispatch candidate (2026-10-14)

Expected outcome: Perl's builtin `class`, `field`, `method`, and signature
syntax should reduce object-call cost without changing returned values.
Reproduction: run `script/problem48-class-method-benchmark` in the isolated
Docker Perl 5.40.1 environment. All three getter variants returned identical
values across 21 rotated pairs of two million calls. Medians were 161.889 ms
for the existing blessed-hash method, 209.391 ms with a lexical signature,
and 211.423 ms for the builtin class method (0.77x relative speed). This
candidate is slower and was not applied to production code. Problem 48 remains
open.

### Problem 48 HTML entity encoder candidate (2026-10-14)

Expected outcome: an XS-backed HTML entity encoder preserves the project's
body-escape output while accelerating real text. Docker parity checks passed
for Unicode test strings, but `B` showed `HTML::Entities::encode_entities` is
not an XSUB in the installed module. On 64, 4,096, and 65,536 character inputs,
it measured only 0.34x, 0.14x, and 0.13x the current helper's speed across 21
alternating pairs. This candidate is rejected; no dependency or production
change was made.

### Problem 48 Inline::C/XS HTML-escape candidate (2026-10-14)

Expected outcome: an XS-backed escaper preserves exact HTML/Unicode output and
materially reduces the actual editor-highlighting cost. The benchmark checks
raw-byte, Unicode, NUL, empty, undef, UTF-8 flags, and complete
`Web::App::_highlight_instruction_html` parity. In 21 alternating Docker
pairs, the full highlighting method measured 2.33x faster at 64 characters,
10.63x at 4,096, 8.60x at 65,536, and 7.59x at 1 MiB. The isolated helper
peaked at 14.97x. Inline compilation took 723.386 ms and is excluded from
steady-call timings. This does not reach 50x or prove a whole-route gain; the
candidate remains a benchmark only, with no production implementation yet.

### Problem 48 single-pass Perl HTML-escape candidate (2026-10-14)

Expected outcome: replace three sequential substitutions with one substitution
without changing output, and reduce escaping time. Reproduction used identical
inputs through the current shared helper and a one-pass hash-replacement
prototype in 11 alternating Docker pairs. Output parity passed at all sizes,
but candidate speed was only 0.44x at 64 characters, 0.21x at 4,096, 0.20x
at 65,536, and 0.21x at 1 MiB. The prototype was rejected and no production
code changed. Problem 48 remains open.

### Problem 48 FFI libc realpath path-identity candidate (2026-10-14)

Expected outcome: FFI::Platypus `realpath` preserves canonical path identity
while reducing `_path_identity` time. In Docker, exact parity passed for an
existing nested directory and a symlinked spelling. With an allocated result
that was measured, copied, and freed, 21 alternating pairs of 1,000 iterations
over both paths measured 11.428 ms for `Cwd::abs_path` and 7.206 ms for FFI
(1.59x). Caller-buffer variants measured 1.72x when allocated per call and
1.97x when reused, but a fixed-size buffer is not safe for arbitrary paths.
The safe result is Linux-specific (`libc.so.6`). A Docker follow-up validated
existing, symlinked, and missing paths plus exact `Config::path_aliases` JSON
over 50 and 250 synthetic skills. The aggregate remained 1.00x at both sizes
(2.115/2.105 ms and 10.237/10.236 ms, baseline/candidate), so the candidate
was rejected with no production change. `FFI::CheckLib` libc discovery emitted
warnings and crashed the first isolated probe; the benchmark used explicit
`libc.so.6`. Portable library discovery, long paths, and other OS behavior
remain unproven. Problem 48 remains open.

Follow-up: Problem 48 runtime-layer directory snapshot candidate (2026-10-14)

Expected outcome: avoid repeated directory existence checks for a parent path
inside one runtime-layer operation, while later operations still observe
filesystem changes. The red-first Docker test demonstrated the desired
snapshot/freshness contract. After implementation, seven 5,000-call helper
rounds ranged from 0.97x to 1.06x (median about 1.01x). A 31-pair four-layer
`all_paths` Docker benchmark preserved byte-identical JSON but measured about
1.00 ms for both versions (about 1.00x). Because no aggregate gain was
measurable, the candidate and its temporary test were removed. No production
change remains; Problem 48 remains open.

Follow-up: Problem 48 repeat of >50x routine benchmarks (2026-10-14)

To revalidate the strongest current gains, I reran both parity-checked
benchmarks in Docker. Against the v5.88 linear allowlist scan, the current
legacy parser processed 1,001 CODE sections at 116.72x faster across 21
alternating runs, with exact canonical JSON parity. Against the v5.88-equivalent
Template Toolkit processing path, the static-body fast path measured 90.04x
faster across 21 alternating samples of 5,000 renders, preserving exact
Unicode output. Focused PageDocument/PageRuntime tests passed 105 assertions.
These validate two routines only, not every subroutine; Problem 48 remains
open.

Follow-up: Problem 48 compiled XS HTML body escaper (2026-10-14)

Expected outcome: build the measured one-pass C escaper into installed
distributions while preserving byte output, Unicode flags, NUL handling,
overloaded-reference behavior, and the source-only fallback. A red-first test
reproduced the missing backend selection. The shared escaper now loads the
compiled XS backend for ordinary scalar inputs; a staged Docker build passed
all XS contract assertions, including a taint-mode subprocess, and the
existing HtmlEscape assertions.
The build exposed stale MakeMaker VERSION_FROM metadata after the main module
delegated its version, so it now reads the lightweight version module; the
5,632-assertion release-metadata suite passes without that warning. Across 21
rotated samples with exact output parity, production XS measured 12.63x faster
for a 1 MiB body and full instruction highlighting measured 9.53x. Problem 48
remains open because this is one routine, not every subroutine.

Follow-up: Problem 48 Inline::C chunk-copy escaper (2026-10-14)

Expected outcome: a `memchr`/`memcpy` XS candidate should outperform the
existing C byte loop while keeping exact output and UTF-8 flags. The red-first
Docker parity test was added before the candidate. Exact parity held for raw,
Unicode, NUL, undef, and empty values and complete instruction-highlighting
HTML. Across 21 rotated Docker samples, chunk-copy was slower than the direct
C loop at 4,096, 65,536, and 1,048,576 characters (0.018/0.007 ms,
0.324/0.115 ms, and 5.742/2.262 ms respectively). The current C loop remained
6.58x faster than Perl for 1 MiB full highlighting; chunk-copy achieved only
4.37x. The candidate is rejected for production and kept in the research
benchmark. Problem 48 remains open.

Follow-up: Problem 48 XS dispatch coverage (2026-10-14)

The first post-XS full coverage pass identified an unexercised native-dispatch
branch. A source-only regression now tests both dispatch outcomes using a
scoped stub, and the MakeMaker fixtures include the XS file and lightweight
version metadata. The full Docker suite passes 274 files / 24,063 tests with
100.0% statement, branch, condition, and subroutine coverage across `lib/`
(47,861 detail rows; no stale uncoverable annotations). The 50x-per-subroutine
performance objective remains open.

Follow-up: Problem 48 lookup-table HTML escape candidate (2026-10-14)

A red-first Docker regression required exact parity from a byte-indexed C
lookup-table candidate. The compiled staged benchmark passed byte, UTF-8,
NUL, undef, empty, and full-highlighter parity. Across 21 rotated samples, the
lookup table was slower than the production XS byte loop at 1 MiB: 11.04x vs
13.16x over Perl for escaping, and 8.18x vs 9.26x for full highlighting. It
was rejected and removed from production; the benchmark keeps the candidate,
and the XS suite retains a 1 MiB parity case. Problem 48 remains open.

Follow-up: Problem 48 distribution-aware XS HTML escaping (2026-10-14)

The direct native byte loop improved dense text but regressed for plain
Unicode and sparse escapes. Reproduction in the staged Docker benchmark showed
0.07x and 0.74x versus Perl at 1 MiB for plain and sparse helper input. The
red-first test first failed because sparse strings still used the direct loop.
The wrapper now returns plain input unchanged, uses direct XS for early/dense
escapes, and uses a native chunk-copy helper for sparse escapes. Staged Docker
tests passed 42 XS assertions, including 1 MiB dense, sparse, and plain Unicode
parity. Across 21 rotated samples, helper speedups measured 12.40x/3.08x/1.02x
and complete instruction-highlighter speedups measured 9.02x/1.74x/1.00x for
dense/sparse/plain workloads. The final init-enabled Docker coverage gate
passed 274 files / 24,088 tests with 100.0% statement, branch, condition, and
subroutine coverage across lib/ (47,881 detail rows, no stale uncoverables).
Problem 48's all-subroutine 50x target remains open.

### Problem 48 scoped skill-layer inventory candidate (2026-10-15)

A red-first Docker test reproduced per-skill root rescans after the operation's
installed-skill directory inventory had already been built. The candidate
reused the scoped directory-name inventory and retained per-lookup directory
and disabled-marker checks. Focused PathRegistry and web-app tests passed with
layer-order, masking, and next-operation freshness assertions. A preliminary
13.67x result omitted the request's runtime-layer scope and was invalidated.
The corrected 250-skill/two-layer benchmark established both request scopes,
used one lookup per skill, and preserved exact ordered output: 2.7361 ms
baseline versus 2.5539 ms candidate (1.07x) over 21 alternating runs. A
1,000-skill, 31-run confirmation also measured 1.07x. The candidate-specific
production edit and test were removed because this result is too small to
justify complexity toward the 50x objective; the reproducible negative-evidence
benchmark remains. A fresh NYTProf profile of `t/03-web-app.t` recorded 767
`runtime_layers` calls (0.081 s inclusive) and 26 `_nav_items_html` calls
(0.082 s inclusive). These are instrumented test totals, not production
latency. Problem 48 remains open.

### Problem 48 early-but-rare XS escape dispatch follow-up (2026-10-15)

Expected outcome: long HTML text with few escape bytes should not use the
full-input direct byte loop merely because its first escape is near offset zero.
Reproduction uses a 1 MiB string starting with `<` and containing only a few
escapes. A red-first routing test made the direct helper die and failed before
the fix; it passes after dispatch routes this input through the chunked XS
helper while retaining direct dispatch for dense prefixes.

The wrapper now uses the direct XS loop for inputs up to 64 characters or for
long inputs with at least four escapes in the first 16 characters. The staged
Docker MakeMaker build compiled XS and the focused regression passed all 44
assertions, including exact 1 MiB output, UTF-8, NUL, and taint checks. The
source-only focused suites also passed; the Inline benchmark test reports an
explicit skip because Inline is absent from the standard dev image. Existing
compiled-XS 21-sample evidence records 2.65x helper / 1.69x full-highlighter
speedup for the 1 MiB prefix-sparse input, 10.98x / 10.18x dense, and 2.72x /
1.85x ordinary sparse, with plain input near parity. README and canonical
module POD describe the distribution-specific result. The full Docker coverage
gate then passed 275 files / 23,738 tests with 100.0% statement, branch,
condition, and subroutine coverage across `lib/` (47,889 detail rows; no stale
uncoverables). The all-subroutine 50x goal, remaining security and packaging
gates, and commit remain open.

### Problem 48 fresh NYTProf workload-quality check (2026-10-15)

The renewed `subs=1` profile of `t/03-web-app.t` passed and identified a
measurement-quality issue: its largest sampled paths were 6,994,785 ticks in
`IO::Select::can_read` while draining saved-Ajax streams and 3,811,703 ticks in
`system` captured by the test harness. Template Toolkit parsing and FFI library
discovery also appeared, but test-mixed samples cannot rank production route
cost. No production optimization was selected from this profile. The next
profiling step is to isolate a representative saved-page or status request and
measure wall-clock latency together with subroutine samples. Problem 48 stays
open.

### Problem 48 request-scoped scalar-template parse reuse (2026-10-15)

Red-first Docker evidence showed identical scalar Template Toolkit source was
parsed once per render. PageRuntime now retains successful parsed trees only
within the active request, bounds the cache (16 sources, 256 KiB each, 1 MiB
aggregate per include-root set), and creates a fresh document per render.
Regression tests check dynamic values, custom META, live INCLUDE files, fresh
request invalidation, normal parse-error reporting, oversized sources, and
cache-allocation limits. The focused tests pass 91 assertions. A fair
request-scoped 21-run Docker benchmark with a live INCLUDE measured 1.38x for
five identical bodies per request and 0.97x for five distinct bodies, with
exact output parity. The distinct-source result is near parity with a slight
regression. This is
not a 50x all-subroutine result; Problem 48 remains in progress. The full
Docker suite ran 275 files / 18,117 tests but exited 2 on environment/repository
tracking failures in `t/13`, `t/15`, `t/158`, and `t/34`; the release coverage
gate therefore did not pass. A preliminary module report from that run showed
PageRuntime at 100.0% statement/subroutine, 99.0% branch, and 99.3% condition
coverage before the final cache-boundary tests were added. Those new focused
tests pass, but current aggregate coverage still needs a clean rerun.

### Problem 48 status update (2026-10-15)

The resident `paths -o json` handler prototype was re-benchmarked in Docker at
50 skills over 21 paired samples. Exact output parity and all config,
`Folder.pm`, skill-addition, and skill-removal freshness probes passed. The
resident path measured 3.650 ms versus 23.381 ms for a new helper process
(6.41x); this remains prototype evidence and does not meet the requested 50x
goal. An isolated saved-page profile is still next. A new Compose profiling
container could not be created because Docker reported that all predefined
address pools were subnetted. Existing containers were left untouched. Problem
48 remains in progress.

### Problem 48 saved-page worker-cache follow-up (2026-10-15)

The earlier isolated-profile attempt failed on Docker's predefined network-pool
allocation. The follow-up used a temporary `network_mode: none` Compose override,
without stopping or changing any unrelated container, and profiled the real
saved-page request. NYTProf showed that retaining TT parse trees still caused
`Template::Document->new` to evaluate generated Perl source on every render.
PageRuntime now caches compiled scalar-template blocks in the bounded worker
cache and creates fresh documents per render. The web runtime also caches
machine-address candidates for five seconds and scopes path-identity plus
runtime-layer existence snapshots to one request; later unscoped operations see
filesystem changes.

Red-first Docker tests first failed on repeated TT compilation, missing path
identity request scope, and layer creation becoming visible inside an existing
snapshot. After implementation, the focused Web App, Web update, PathRegistry,
PageRuntime, and benchmark suites passed 1,044 assertions. In 15 alternating
Docker runs with matching 9,573-byte output, the saved-page route median was
0.497 ms versus 1.673 ms for a read-only v5.88 archive (3.37x). Disabling
compiled-template reuse measured 0.656 ms; disabling the address cache measured
0.522 ms. Disabling the request-local layer-existence snapshot measured 0.506
ms versus 0.485 ms with it. The NYTProf conversion reports expected `#line`
mapping notes for generated TT `eval` sources; no application or benchmark
container warnings occurred. This route-specific improvement does not achieve
Problem 48's 50x all-routine objective. The latest profile still highlights
indicator directory enumeration and response assembly; Problem 48 remains in
progress.

#### Navigation item array removal (2026-10-18)

Expected outcome: retain byte-for-byte saved-before-skill navigation markup
without creating a temporary item array and then joining it. A red-first Docker
test failed because the optimized wrapper contract was absent. The renderer
now appends ordered fragments to one scalar and wraps inline. The focused
web-app suite passes 542 assertions. A 10-million-call Docker comparison
preserved exact output and measured 4.76 million old array/join assemblies per
second versus 8.00 million direct-scalar assemblies per second (1.68x). The
full route retained HTTP 200, 19,341 response bytes, and the established SHA-256
at 0.342350 ms/request; that is within route variation, so no end-to-end gain
is claimed. The final full Docker gate passes all 285 files and 25,325 tests,
with 100.0% statement, branch, condition, and subroutine coverage across
`lib/` (51,685 detail rows, no stale annotations). The release-metadata test
passes after README was synchronized with POD. Problem 48 remains open.

### Problem 48 collector-backed status sync (2026-10-15)

The isolated Docker reproduction seeded 50 collector indicators, warmed
`/system/status`, and profiled 100 requests. The expected outcome was one
ordered roots snapshot and at most one physical read per status file during a
sync, exact response bytes, and fresh state on the following request. Before
the fix, NYTProf recorded 15,100 indicator-root resolutions, 15,000 status-file
reads, and 2.40 seconds inclusive in `sync_collectors`. The first red-first
test reproduced the issue: a 12-indicator sync resolved roots 37 times instead
of once.

`sync_collectors` now shares ordered roots and decoded status records only for
its own operation; writes/deletions invalidate their entries. The cache is
discarded before a subsequent sync. Docker regressions verify one roots lookup,
one disk read per indicator, changed-state visibility on a later sync, and
correct inventory after collector retirement. The focused IndicatorStore and
new regression suites pass 229 assertions.

In 15 alternating Docker runs, the same 50-collector endpoint measured 9.203
ms/request before and 2.689 ms/request after (3.42x), with exact response-byte
parity. The post-change profile recorded 100 root resolutions, 5,000 file
reads, and 513 ms inclusive in `sync_collectors` over 100 requests. This
advances one collector-heavy route; Problem 48's full 50x-per-subroutine
objective remains open.

### Problem 48 single-root collector-plan follow-up (2026-10-15)

Expected outcome: for a collector sync with exactly one indicator state root,
the already-resolved effective record is also the local record, and no
inherited-layer lookup is attempted. Multi-root lookups must retain their
existing precedence and behavior.

The first profile follow-up was mistakenly read from the installed Perl tree
instead of the checkout. The corrected Docker profile explicitly placed
`/work/lib` first in `@INC`; it confirmed 101 roots snapshots across 100
requests in current source, rather than the 15,100 calls seen in the installed
copy. That checkout-bound profile identified duplicate local and inherited
lookups in the single-root collector plan as the actionable path.

Reproduction: in the isolated Docker test HOME, seed 12 collector indicators,
run a stable sync with one state root, and count `_local_indicator` and
`_nearest_inherited_indicator` calls. The red-first test failed before the fix
with 12 calls to each helper. `_collector_sync_plan` now reuses the existing
record for the single-root case and skips inherited lookup when no second root
exists; multi-root cases still take the original helpers.

The targeted Docker tests pass 231 assertions across IndicatorStore and the
Problem 48 sync contract, and the full Docker coverage gate passes 276 files /
23,827 tests with 100.0% statement, branch, condition, and subroutine coverage
across `lib/`. A repeat 50-collector status benchmark retained exact
12,687-byte responses and measured 7.708 ms/request for the previous strategy
versus 2.195 ms/request for current source (3.51x). This is a modest, scoped
increment; Problem 48 remains in progress because the all-routine 50x target is
not met.

### Problem 48 direct v5.88 status baseline check (2026-10-15)

Expected outcome: compare the same collector-heavy status route on the named
v5.88 baseline and current checkout, preserving exact response bytes, before
claiming baseline speedup. A Docker benchmark loaded each source tree explicitly
through `@INC`, used an isolated HOME and 50 collectors, warmed the endpoint,
and measured 100 requests in each of 15 samples. Both trees returned HTTP 200
and identical 12,687-byte bodies. The median was 35.090 ms/request for v5.88
and 1.624 ms/request for the current checkout (21.61x). This proves meaningful
progress for one route, not the required 50x improvement for every subroutine;
Problem 48 remains in progress.

### Problem 49: Remove the install test's hardcoded `/tmp` assumption (done)

GitHub issue 59 reported assertion 195 in `t/40-install-bootstrap.t` failing
when the host's `TMPDIR` was not `/tmp`. The expected outcome is that the
regression test validates the bootstrap script path selected by the configured
temporary directory, without changing installer behavior. Reproduction with
`TMPDIR` under `/var/tmp` failed because the test expected
`/tmp/developer-dashboard-homebrew-install.sh`; `install.sh` correctly uses
`${TMPDIR:-/tmp}`. The test now creates and selects a private temporary
directory for the Homebrew case and constructs both expected command paths
with `File::Spec`. The focused suite passes with the default environment and a
non-`/tmp` `TMPDIR`; the failure was test-only. Full verification passed: 285
files / 19,516 tests via `dzil test`, and 285 files / 25,879 tests through the
coverage gate with statement, branch, condition, and subroutine coverage at
100.0% for `lib/` (51,685 detail rows). The three required web/security suites
passed 470 assertions. `dzil build` produced 6.06; `t/36-release-kwalitee.t`
passed all 7 assertions at 100% kwalitee. The post-build Docker smart-router
guard passed 7 assertions, and the blank-environment Docker integration
installed the tarball via `cpanm` with its tests enabled and completed
successfully. No production code or dependencies changed.

### Problem 48 stable collector-sync freshness cache (2026-10-15)

Expected outcome: unchanged collector configuration and indicator files should
avoid rebuilding every collector plan and rereading unchanged JSON, while each
request still observes external file/config changes and returns the exact same
status body. Reproduction: run the 50-collector `/system/status` profile in an
isolated Docker HOME, compare response bytes against v5.88, then modify a
status JSON atomically, change collector configuration, add/remove an
indicator, and retire a collector between requests. Before the fix, the
steady-state sync repeated collector planning and physical JSON reads; the
red-first regression showed 12 plans and 12 physical reads on a 12-indicator
stable sync where both should be zero.

Root cause: the prior cache shared decoded records only within one sync. Each
later stable request repeated collector planning and reread status JSON. The
fix caches raw bytes across syncs behind a high-resolution stat signature and
checks active-job configuration plus directory inventory before returning the
inventory. It decodes fresh Perl references, and any mismatch uses full
reconciliation. Publicly returned indicator mutation cannot alter cached raw
bytes. Red-first Docker coverage verifies stable fast-path counts, API and
atomic external updates, collector retirement, deletion/recreation, config
edits, I/O error visibility, and caller-mutation isolation. The focused
IndicatorStore suites pass 255 assertions.

Verification: 15 Docker samples on the same image and isolated workload
returned exact 12,687-byte parity. v5.88 measured 35.090 ms/request and current
source measured 0.670 ms/request (52.37x) for this route. The source-bound
NYTProf trace records only initial-warm-up collector planning rather than
5,000 plans across 100 calls; stable requests avoid those plans and JSON
content reads but retain per-file metadata checks for freshness. This is
route-specific and does not establish a 50x gain for each routine. The final
clean Docker coverage gate passed all 276 files / 23,851 tests with 100.0%
statement, branch, condition, and subroutine coverage across `lib/` (48,283
detail rows, no stale uncoverable annotations). The Perl security reference was
reviewed from the container's `perlsec.pod`; `perldoc perlsec` itself could not
render because the image lacks a Pod formatter. Focused OWASP checks passed 156
assertions. Problem 48 remains open.

### Problem 48 validated status-response reuse (2026-10-15)

Expected outcome: repeated `/system/status` calls with unchanged collector
configuration and persisted indicator files return the exact prior response
without repeating status-payload construction; a changed indicator or config
must produce a fresh response on the next request.

Reproduction: in Docker with an isolated HOME, seed 50 collectors, warm the
status endpoint, then issue repeated requests while counting status JSON
encodes and `page_header_payload` calls. Next, persist a changed indicator and
request status again. Before the optimization, an unchanged request still
rebuilt the payload and encoded JSON. The red-first regression in
`t/668-problem48-status-response-cache.t` failed those stable-path call-count
assertions.

Root cause: collector synchronization already proved whether the configuration,
status-file signatures, and directory inventory were unchanged, but the web
route discarded that result and rebuilt/sorted the same payload and serialized
the same JSON anyway. `sync_collectors` now exposes its validated unchanged
result to the route. A cached response is reused only after that validation;
changed state follows the normal payload and encoding path. Tests also ensure
an invalid freshness signal cannot suppress payload construction.

Evidence: the 31-sample Docker comparison returned byte-identical 12,687-byte
responses and measured 34.257 ms/request on v5.88 versus 0.597 ms/request on
current source (57.38x) for this one 50-collector route. Focused Problem 48
tests passed. The final full Docker gate passed 277 files / 23,871 tests with
100.0% statement, branch, condition, and subroutine coverage across `lib/`
(48,324 detail rows, no stale uncoverable annotations). Required OWASP,
web-update, static-file, and TLS tests passed. `perldoc perlsec` could not load
a formatter in the test image; the complete core `perlsec.pod` source was
reviewed directly. The all-routine 50x goal remains open, so Problem 48 remains
in progress.

### Problem 48 stable status-path join reuse (2026-10-15)

Expected outcome: while validating an unchanged cached status response, each
discovered indicator status path is joined once, and active collector
validation reuses the same existence result without weakening external-change
detection.

Reproduction: in Docker with an isolated HOME and 12 persisted indicator
entries, invoke `_collector_sync_files_unchanged` while counting
`File::Spec->catfile` calls. The red-first assertion failed before the change:
24 calls were made for 12 entries instead of 12.

Root cause: inventory validation checked each candidate status path and then
active collector validation rebuilt and rechecked the same path. The first
pass now records which names have a present cached status file; active jobs
reuse that map. All candidate signatures are still checked, so file
modifications, replacement, or removal continue to force reconciliation.

Evidence: the focused Docker suite now verifies exactly 12 joins for 12
entries. A fresh 31-sample, 50-collector `/system/status` comparison returned
byte-identical 12,687-byte responses: 34.307 ms/request on v5.88 and 0.437
ms/request currently (78.50x for this endpoint workload). This is not evidence
that every subroutine is 50x faster. The full Docker gate passed 100.0%
statement, branch, condition, and subroutine coverage (48,438 detail rows,
with no stale uncoverables). Post-gate `perldoc perlsec` and the required web
security regression suite passed; its four files covered 622 assertions.
Packaging, image, delivery gates, and the all-subroutine 50x objective remain
open, so Problem 48 is still in progress.

Problem 48 blank-container package-test isolation follow-up (2026-10-15)

Expected outcome: the distribution's cpanm test install passes regardless of
the machine/container network address discovered by earlier tests.

Reproduction: build the distribution, install it with plain `cpanm` in the
blank Docker environment, and run its bundled suite. Before the correction,
`t/08-web-update-coverage.t` failed its empty machine-IP assertion after other
routes had already populated the app object's worker-local IP cache.

Root cause: the test stubbed empty interface discovery but reused an app object
whose cache held the real container IP. The test now clears that cache before
exercising the empty-discovery branch. Its focused Docker rerun passes all 286
assertions. The 5.95 tarball then installed with cpanm in the blank Docker
environment, passing 277 bundled files / 18,197 tests; the documented
blank-environment integration run also passed. The all-subroutine 50x
objective remains open.

Saved-page profile follow-up (2026-10-15): an isolated Docker NYTProf run
covered 110 warm requests through Web::App->handle('/app/welcome') with five
saved nav fragments. Responses returned 200 and retained the expected page
markers at 9,882 bytes. The dashboards_roots mapping line accounted for 11.068
ms across 1,540 profiled executions. A red-first test showed two repeated
lookups deriving the same ordered roots twice; request-scoped reuse reduced
that to once and focused tests passed 813 assertions. However, a 21-sample
paired route benchmark of 100 requests per sample measured 1.2397 ms/request
uncached versus 1.2368 ms cached (1.00x) with normalized live-datetime parity.
That is no meaningful end-to-end gain, so the cache candidate and tests were
removed. The profile finding is retained as evidence; no production cache is
shipped. Problem 48 remains open.

### Problem 48 stable status-path string reuse (2026-10-15)

Expected outcome: repeated stable status-response validation reuses path
strings, but still checks every file's metadata and notices external changes.

Reproduction: in Docker, seed 12 indicator records and call
`_collector_sync_files_unchanged` twice while counting `File::Spec->catfile`.
Before the implementation, the red-first check failed with 24 joins instead
of 12.

Root cause: the validator joined the same ordered root, indicator name, and
`status.json` path for every request even while the ordered roots and directory
inventory remained unchanged. It now caches only those path strings under a
signature of the ordered roots and inventory. High-resolution `stat` checks
remain in place on every request; changed roots or directory entries rebuild
the path map.

Evidence: the focused Docker regression suites passed 87 assertions,
including malformed path-map recovery, external file replacement, and
inventory changes. A 21-sample paired
50-collector route benchmark returned exact 12,414-byte responses and measured
72.341 ms per 100 requests without path reuse versus 66.347 ms with it (1.09x).
This is incremental current-source evidence, not a v5.88 comparison. The
all-routine 50x objective and full Problem 48 delivery gates remain open.
After adding explicit absent-signature, stale-signature, and malformed-path
cache cases, the complete Docker coverage gate passed 277 files / 23,938 tests
with statement, branch, condition, and subroutine coverage at 100.0% (48,462
detail rows; no stale uncoverable annotations).

### Problem 48 optional Linux watcher for stable indicator synchronization (2026-10-15)

Expected outcome: a previously validated, unchanged indicator-directory
inventory avoids repeated portable metadata scans on supported Linux systems,
while every observed filesystem event or watcher error triggers the existing
full validator. Unsupported platforms and absent optional FFI dependencies
must retain portable behavior.

Reproduction: in the dev Docker service, seed 50 indicator directories, run
the stable `_collector_sync_files_unchanged` path repeatedly, compare the
watch-enabled result with the portable validator, then write a status file
externally and verify the next sync notices it. Before the optimization, the
stable path repeated directory and file-signature checks on every call.

Root cause: the stable synchronization path had no event source to distinguish
an unchanged filesystem from one that had changed since the previous complete
validation. It therefore paid the cost of portable directory and metadata
checks on every request.

Change: add an optional Linux inotify adapter using typed FFI::Platypus libc
bindings. It watches mutation events only. Events invalidate the snapshot;
setup/read/close failures produce visible diagnostics and fall back to the
portable validator. The portable validator still runs after watch setup to
close the scan/watch race. No change is made to non-Linux behavior.

Evidence: native-enabled Docker tests passed across the adapter and store
integration, including external writes and fallback failures. All five
focused Problem 48 files passed 210 tests. The 21-sample benchmark (100 calls
per sample) preserved exact inventory output and measured 0.001600 ms per
stable 50-indicator helper call with inotify versus 0.256500 ms with the
portable validator (160.33x). This is not a comparison to v5.88 and does not
prove whole-dashboard or all-subroutine acceleration. The full Docker gate
passed 281 files / 24,151 tests with 100.0% statement, branch, condition, and
subroutine coverage (48,963 detail rows; no stale uncoverable annotations).
Post-gate `perldoc perlsec` could not load a text formatter in the container;
the installed `/usr/share/perl/5.40.1/pod/perlsec.pod` was reviewed directly.
Problem 48's all-subroutine 50x objective and remaining release/delivery gates
remain open.

### Problem 48 single-layer config merge follow-up (2026-10-15)

Expected outcome: a lone global config file with no skill fragments is loaded
without recursively merging into an empty hash, and an empty repo layer adds no
second merge. Duplicate collector/provider identities, multiple runtime layers,
skill fragments, and non-empty repo overlays must keep their existing precedence
and values. Config remains fresh on each request; no persistent snapshot is
introduced.

Reproduction: run `d2 docker compose exec dev prove -lv t/93-config-coverage.t`
with the single-layer fixture and spy on `_merge_hashes`. Before the change, the
global load performed an unnecessary recursive merge and `merged` performed a
second merge against an empty repo hash. The red-first assertion observed one
merge for a unique one-file load and two through `merged`; after the change,
both paths perform zero recursive merges in that case. A separate duplicate
collector fixture still confirms the later duplicate wins.

The implementation assigns the freshly decoded first global layer directly,
then applies the established identity-array normalization. It merges subsequent
global layers and skill fragments as before. `merged` returns the global hash
only when the repo value is an empty hash; non-empty overlays still use
`_merge_hashes`. The focused Docker web/config/benchmark suites passed 630
tests. A 50-collector route run returned the same 12,864-byte SHA-256 response
as before and measured 0.258 ms/request versus 0.260 ms/request in the previous
run; that difference is noise, not a claimed gain. The comparison with v5.88
remains approximately 233x for this route/workload only. Problem 48's
all-subroutine 50x target and full delivery gates remain open.

### Problem 48 matched status-route rerun and current NYTProf call tree (2026-10-15)

Expected outcome: compare the same stable 50-collector `/system/status` request
against v5.88 and current source, require exact response bytes, and use a
source-bound NYTProf trace of the warmed route to select subsequent work.

Reproduction: in the `dev` Docker service, run
`script/problem48-status-route-benchmark --indicators 50 --iterations 100
--runs 21` once with `P48_LIB=/work/nytprof/v588/lib` and once against `/work/lib`.
Then profile the current source with `NYTPROF=start=no` and the benchmark's
`--profile` option around 500 warmed requests.

Evidence: both non-profiled runs returned HTTP 200 and the exact 12,864-byte
body hash `da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`.
The v5.88 median was 72.415810 ms/request and current median was 0.249081
ms/request (290.73x for this route fixture only). NYTProf measured 1.313282
ms/request under instrumentation; top source-line totals included JSON decode
(22.703 ms / 500 calls), JSON encode (15.320 ms / 1,000 calls), indicator
projection (10.122 ms / 25,000 entries), and `dispatch_request` (9.960 ms /
500 calls). The profile highlighted path discovery and secure state-metadata
verification as recurring costs, but did not identify a safe universal cache
or native replacement. The route result does not establish 50x for every
subroutine. The all-subroutine objective and full delivery gates remain open.

The same instrumented benchmark was profiled at 100 warmed requests for both
source trees: v5.88 took 169.546802 ms/request under NYTProf, current source
took 1.108379 ms/request (152.97x under instrumentation), and both preserved
the same response hash. The line reports counted 808,400 `abs_path` calls and
100,800 `getpwuid` calls on v5.88, compared with 400 `abs_path` calls and no
`getpwuid` call in current source. JSON decode calls fell from 20,000 to 100;
JSON encode calls fell from 25,300 to 200. This explains removed repeated work
for this request flow only and is not per-routine or all-repository proof.

As a follow-up to the call-tree result, a Docker microbenchmark tested whether
the one-per-request config decode could be replaced by cloning a cached parsed
tree. For an 8,504-byte fixture with 50 collectors, 21 alternating rounds of
5,000 operations preserved canonical JSON but measured 240.356 ms for
`JSON::XS` decode and 348.680 ms for `Storable::dclone` (clone was 0.69x as
fast). The mutable-tree cache candidate was rejected; configuration remains
decoded freshly per request.

### Problem 48 bounded state-metadata JSON scalar reuse (2026-10-15)

Expected outcome: repeated metadata checks for the same runtime-root and
application-name pair reuse only their canonical encoded JSON string, while
all live filesystem security/freshness checks continue on every call. Changing
either identity field must regenerate the string and write the matching payload.

Reproduction: in Docker, run
`d2 docker compose exec dev prove -lv t/97-pathregistry-coverage.t` with a
`json_encode` counter around two identical `_write_state_metadata` calls.
Before the fix, the new assertions failed with two encodes instead of one, and
with one extra encode for each identity-field change.

Root cause: `_write_state_metadata` rebuilt the same tiny canonical JSON scalar
before checking whether the already-secure file contained identical bytes.
The method now keeps a bounded single-entry cache of that scalar keyed by exact
runtime root and application name. It does not skip directory checks, `lstat`,
file-type/owner/mode validation, reading, byte comparison, or error handling.
The red-first regression now passes, including changes to both key fields,
undefined-name behavior, malformed cache misses, and a defined application name
rejecting a cached undefined name. The focused PathRegistry file passes all 318
tests.

The current warmed `/system/status` route preserved the exact 12,864-byte body
hash and measured 0.247939 ms/request versus 0.249081 ms in the previous run;
the difference is within noise, not a claimed performance result. This removes
redundant serialization for the repeated state identity but does not close the
all-subroutine 50x objective. The clean Docker coverage gate then passed all 281
files and 24,160 tests at 100.0% statement, branch, condition, and subroutine
coverage (48,989 detail rows, no stale uncoverable annotations). The coverage
gate is complete; the all-subroutine 50x objective and remaining Problem 48
delivery gates remain open.

### Problem 48 post-change NYTProf hotspot map (2026-10-15)

Expected outcome: use a request-scoped, byte-identical `/system/status` profile
to select the next optimization target without treating profiler timings as
production latency.

Reproduction: in Docker, profile
`script/problem48-status-route-benchmark --indicators 50 --iterations 100 --runs 1 --profile`
with `NYTPROF=start=no`; inspect the generated NYTProf subroutine report.
Observed: 100 requests returned HTTP 200 and the established 12,864-byte body
hash. Instrumented median was 1.560960 ms/request. Largest inclusive totals
were `_request_config_snapshot` 52.2 ms, `Config::load_global` 46.8 ms,
`_page_status_payload` 32.2 ms, and `PathRegistry::runtime_layers` 24.1 ms;
`Config::_merge_named_hash_array` led exclusive time at 6.05 ms. These inclusive
totals overlap and are not production timings. Next, evaluate config-load
optimizations against exact merge parity and immediate external-edit freshness.
Problem 48's all-subroutine 50x objective remains open.

### Problem 48 matched v5.88/current profile and microbenchmark check (2026-10-15)

Expected outcome: compare the same warmed status workload across v5.88 and the
current source with byte-identical output, then validate any apparent per-method
regression with an unprofiled microbenchmark before changing code.

Reproduction: inside Docker, run
`script/problem48-status-route-benchmark --indicators 50 --iterations 100 --runs 1 --profile`
once with `P48_LIB=/work/nytprof/v588/lib` and once with current `/work/lib`,
using distinct `NYTPROF` output files. Both returned HTTP 200 with the exact
12,864-byte response hash. The instrumented medians were 165.528901 ms/request
for v5.88 and 0.959980 ms/request currently (172.43x for this route/workload
under instrumentation, not a production ratio).

NYTProf suggested `_ip_is_loopback` had regressed, but its source is unchanged.
A separate unprofiled 21-sample benchmark of 100,000 identical IPv4 loopback
checks per sample measured 538.9 ns/call on v5.88 and 433.1 ns/call currently;
all 2.1 million calls per tree returned true. Treat tiny-routine profiler times
as noisy; use NYTProf for path and call-count selection and validate hot methods
with direct benchmarks. This route comparison does not prove the every-subroutine
50x objective, which remains open.

### Problem 48 direct config-merge benchmark (2026-10-15)

Expected outcome: validate the config merge routine selected by NYTProf using
identical inputs and output parity, without profiler instrumentation.

Reproduction: load `Developer::Dashboard::Config` from `/work/nytprof/v588/lib`
and `/work/lib` in the Docker dev container; call
`_merge_named_hash_array` on two 50-item arrays with unique identities and
nested settings for 21 batches of 2,000 calls. Both versions produced canonical
JSON SHA-256
`a2a48266e4168e41d4add395fa11950a53a099926c83dd6067c64a0dec89fcc5` and
4,200,000 total result items. Median latency was 32.975 microseconds/call for
v5.88 and 30.609 microseconds/call currently (1.08x). The routine is faster,
but this falls far short of 50x; the tested nested-loop variant also showed
only a small gain, so no implementation change was made. Problem 48's broad
50x objective remains open.

### Problem 48 direct `sync_collectors` comparison (2026-10-15)

Expected outcome: compare the production stable-sync call on the same 50
indicators against v5.88 without profiler overhead, and confirm the output
inventory is unchanged.

Reproduction: in the Docker dev container, seed 50 fixed-name indicators in a
private temporary HOME, then call `sync_collectors` with the production stable
sync options 100 times per sample for 21 samples. Both trees returned identical
canonical indicator inventories before and after timing. Median was 46.966250
ms/call for v5.88 and 0.133100 ms/call for current source (352.86x on this
stable fixture). This confirms the watcher-backed optimization directly; it
does not generalize to every routine. Problem 48's all-subroutine 50x objective
and delivery gates remain open.

### Problem 48 standalone `Config::load_global` profile and comparison (2026-10-15)

Expected outcome: test the standalone config-loading method against v5.88 using
the same 50-collector input, exact output parity, and immediate external-edit
visibility, then use NYTProf to identify its costs.

Both source trees produced canonical JSON SHA-256
`6209a8a5f7c423f2a882d1897f5e6e5f2d7e70c59908fddbb567983f67f5fa6e` and saw a
saved edit on the next load. With per-call path scopes, v5.88 measured 0.076998
ms/load and current source 0.146348 ms/load (current is 1.90x slower for this
standalone workload). This does not represent the status route, which shares
request-scoped inventories and is much faster overall. NYTProf ranked
`_merge_named_hash_array` (11.4 ms exclusive / 250 calls),
`_ancestor_runtime_layers` (6.66 ms / 250), `_layer_dir_for` (5.48 ms / 750),
and `config_roots` (5.06 ms exclusive, 39.3 ms inclusive / 250). These are
instrumented selection data, not production timings. The method-level gap
remains open; any optimization must preserve external-edit freshness.

### Problem 48 scoped runtime-path snapshot fast paths (2026-10-15)

Expected outcome: avoid repeated path-choice and ancestry work inside one
request-local layer snapshot while making filesystem changes visible to the
next operation.

Red-first Docker tests failed because repeated `_layer_dir_for` calls changed
from `.developer-dashboard` to `.d2` after an in-scope directory creation, and
because exact home cwd still called project-root and canonical ancestry
helpers. The fix caches the selected runtime directory only in the existing
operation scope and returns no ancestor layers for exact home cwd; symlink
spellings keep the canonical path. The scoped standalone 50-collector
`Config::load_global` median moved from 0.146348 ms to 0.084262 ms/load (1.74x
faster), with canonical hash parity and next-load external-edit visibility.
The same change now rejects undefined, empty, or reference-valued parent paths
with an explicit diagnostic rather than incidental Perl warnings.
Against v5.88's 0.076998 ms/load, the current standalone API remains 1.09x
slower. The status response stayed byte-identical, but three route medians
ranged 0.237870–0.288861 ms/request, so no route gain is claimed. Four focused
Docker test files passed 418 tests with `prove -Ilib`. This does not close the
all-subroutine 50x objective or delivery gates.

### Problem 48 load-scoped config-layer discovery (2026-10-16)

Expected outcome: resolve the runtime-layer inventory once during one
`Config::load_global` operation, retain enclosing request-scope reuse, and
observe filesystem changes on the next load.

Reproduction: inside Docker, use a `PathRegistry` rooted at a temporary home
and a nested working directory with multiple `.d2` / `.developer-dashboard`
layers. Instrument `_ancestor_runtime_layers` and call `load_global`. Before
the change, the red-first test observed five ancestry walks in one config load
and failed its one-walk assertion. After the change it observed one. Create a
new nested runtime layer with `config/config.json` after the first call; the
next load must include its setting.

The fix scopes `_runtime_layer_candidate_scope` to `load_global`, reusing an
existing request scope if present and discarding a standalone scope on return.
The later-load test confirms the new layer is immediately visible. A matched
alternating 21-run synthetic Docker workload across four runtime layers and
25 skill configs returned byte-equivalent canonical JSON and measured median
0.3175 ms/load before versus 0.2106 ms/load after (1.51x). This is not a
v5.88 comparison or a whole-dashboard result. A candidate nested-loop rewrite
of `_merge_named_hash_array` was also rejected after exact-output tests and a
0.990x measurement. Focused tests passed 589 assertions across two files; the
full Docker coverage gate passed 281 files / 24,172 tests with all four
coverage metrics at 100.0%. Problem 48's all-subroutine 50x requirement and
delivery gates remain open.

The same red-first runtime-layer count regression was added for
`api_registry`: the unscoped call performed four ancestry walks, versus one
with its operation-local candidate inventory. An alternating 21-run Docker
comparison across four runtime layers and 25 skill API configs preserved exact
normalized output and improved median time from 0.3728 to 0.2638 ms/load
(1.41x). A runtime layer created after one API read appeared on the next call.
Focused Docker tests now pass 6,306 assertions across three files. The clean
full gate then passed 281 files / 24,176 tests, with statement, branch,
condition, and subroutine metrics at 100.0% across `lib/` (49,037 detail rows,
no stale uncoverable annotations). The required security regression trio
passed 466 assertions; the core `perlsec.pod` was reviewed directly because
the container lacks a POD formatter. This is not a v5.88 or whole-dashboard
comparison and does not satisfy the all-subroutine 50x target.

### Problem 48 state-root permission follow-up (2026-10-16)

Red-first Docker tests found `state_root` and `_state_root_for_layer` repeated
the permission-hardening call that `_write_state_metadata` immediately makes.
Removing those redundant calls preserved state metadata creation and aggregate
path output. Focused PathRegistry/status tests passed 361 assertions. A fresh
profile retained the exact status response and reduced `_ensure_state_dir` from
400 calls / 2.82 ms exclusive to 300 / 0.523 ms across 100 requests. The
unprofiled route measurement (0.250821 ms/request) was within noise of its
previous 0.249081 ms result. A proposed indicator-job shortcut was slower
(0.858x) and was discarded. The full coverage gate is pending after this source
edit. The subsequent clean Docker gate passed 281 files / 24,182 tests, with
statement, branch, condition, and subroutine coverage all at 100.0% across
`lib/` (49,039 detail rows; no stale annotations). The all-subroutine 50x
objective remains open.

### Problem 48 matched status-route NYTProf map (2026-10-16)

Matched v5.88/current traces used 50 indicators and 20 requests and returned the
same 12,864-byte SHA-256. Instrumented route medians were 149.958611 and
1.031256 ms/request (145.45x under profiling). In the old trace,
`Cwd::abs_path` ran 80,840 times / 350 ms and `PathIdentity::_path_identity`
40,520 times / 57.2 ms; current counts were 40 / 197 µs and 80 / 114 µs.
`_ensure_state_dir` fell from 25,200 / 70.7 ms to 60 / 141 µs, while
`_write_state_metadata` fell from 5,040 / 66.5 ms to 20 / 236 µs. These are
route totals shaped substantially by fewer calls, not per-call speed factors.
Current leading exclusive work includes `_merge_named_hash_array`,
`indicator_collectors`, JSON decoding, and `_request_config_snapshot`. The
profile narrows further research; it does not prove the 50× result for every
subroutine.

### Problem 48 saved-page raw-nav parser and STASH cache (2026-10-16)

Expected outcome: raw `nav/*.tt` fragments render without invoking the full
bookmark parser; repeated legacy STASH literals avoid repeated Safe evaluation
without sharing mutable request state or hiding errors.

Red-first Docker tests failed before implementation for the parser bypass and
for repeated Safe evaluation. The fix wraps plain raw nav fragments directly
while preserving structured instruction parsing, and memoizes only bounded
JSON snapshots after a successful Safe parse. Cache hits decode fresh hashes;
oversized values bypass caching, LRU entries are evicted, and the cache can be
disabled. The regression suite verifies deep-copy isolation and parser-call
counts.

Matched v5.88/current Docker benchmarks used five raw nav fragments, 21 runs
of 100 warmed `/app/welcome` requests, and exact response parity: HTTP 200,
10,042 bytes, SHA-256
`5b217655b90ff66db1d2fdb5a9d3e4aa6a4d4f05f073f1d7f9fc6ec40746d212`.
Latest medians: 3.866441 ms/request on v5.88 and 0.927038 ms/request currently
(4.17x for this fixture). The four focused Docker test files passed 563 tests.
The all-subroutine 50x objective and remaining delivery gates are still open.

An isolated nested legacy-STASH microbenchmark then measured 3,000 identical
decodes per sample over 21 samples in each source tree. Both produced the same
canonical-value SHA-256
`63729c336dce4d41aae5ccfb4a169905b9166fbef87f3bae78dc185cbb2e3d5b`.
Median time was 254.948 µs/call on v5.88 and 2.401 µs/call currently (106.2x
for this repeated-literal workload). The new reproducible script is protected
by `t/674-problem48-stash-decode-benchmark.t`. Coverage identified missing
edge paths, which are now covered by corruption, structured-nav fallback, and
true LRU tests; focused Docker tests pass 567 assertions. The full coverage
gate then passed for the exact updated source: 283 files / 24,236 tests and
100.0% statement, branch, condition, and subroutine coverage across `lib/`
(49,095 detail rows, no stale annotations). Both touched modules report
100.0% for every metric. The required web/update, static-file, and SSL security
regression trio passed 466 assertions. `perldoc perlsec` lacked a formatter in
the container, so the Perl 5.40 source POD was read directly. This is not
completion of Problem 48's broader 50x target or remaining delivery gates.

### Problem 48 literal static raw-nav preparation bypass (2026-10-16)

Expected outcome: plain raw navigation HTML remains byte-for-byte identical but
does not invoke CODE or Template Toolkit preparation; raw nav templates such as
`nav/here.tt` continue to receive request context and be processed normally.

A red-first web-app regression observed `nav/static-plain.tt` entering
`PageRuntime` and failed. `_nav_items_html` now bypasses request-state and
runtime preparation only when the fragment is a scalar raw-nav source, has no
`[%` opener, and has no CODE blocks. The test confirms the literal HTML stays
in the response and dynamic raw `nav/here.tt` remains on the runtime path.

The focused Docker app and benchmark tests passed 368 assertions. A matched
21-sample current-source route benchmark (100 requests per sample, five static
nav fragments) retained HTTP 200 and the exact 10,042-byte SHA-256 and improved
median time from 0.927038 to 0.804060 ms/request (1.15x incremental). Compared
with v5.88's latest 3.866441 ms/request, this fixture is 4.81x faster. Full
coverage is pending after this edit; the overall Problem 48 objective remains
open.

### Problem 48 literal raw-nav canonical serialization (2026-10-16)

Expected outcome: static raw navigation does not perform instruction
serialization that only dynamic runtime processing needs, and dynamic nav still
receives its canonical instruction source.

A red-first Docker regression failed because the page serialized
`nav/static-plain.tt` along with dynamic `nav/here.tt`. `_nav_items_html` now
assigns `raw_instruction` only inside the dynamic preparation branch. A
truth-table test covers the static-fragment predicate's source format, body
shape, TT opener, and code-block conditions. The Docker web-app suite passes
367 assertions and preserves the exact 10,042-byte route hash.

Across 21 current-source samples of 100 warmed requests, median route time
improved from 0.753798 to 0.733690 ms/request (1.03x incremental). Against the
latest v5.88 measurement of 3.866441 ms/request, the fixture is 5.27x faster.
NYTProf counted 20 `PageDocument::legacy_instruction` calls instead of 100 in a
20-request profile. The previous full coverage run exposed a 99.9% condition
coverage shortfall that motivated extracting and directly exercising the
predicate; a focused report now confirms that predicate condition is at 100%,
but the full gate is pending for the current code. This does not establish the
overall 50x objective.

### Problem 48 request-scoped saved-page root resolution (2026-10-16)

Expected outcome: repeated path-containment checks in one web request resolve
each dashboards root only once, while every candidate page path is still
validated and the next request sees a fresh root resolution.

A red-first Docker test observed 12 realpath calls for a single route and 24
across two requests. `Web::App::handle` now creates a request-local root map and
`PageStore::_assert_page_path_contained` reuses only the resolved root path;
candidate paths still receive the original containment check and secure open.
The Docker web-app suite passes 370 assertions, including the cache-reset test.

Across 21 matched current-source samples, route latency moved from 0.733690 to
0.673630 ms/request (1.09x incremental) with HTTP 200 and identical 10,042-byte
SHA-256. A fresh matched 21-sample comparison measured 3.758640 ms/request on
v5.88 and 0.673630 currently (5.58x for this fixture).
Matched NYTProf call counts fell from 540 to 320 `Cwd::abs_path` calls, and
exclusive `_assert_page_path_contained` time fell from 3.91 to 1.29 ms for the
20-request profile. The clean full Docker gate passed 283 files / 24,251 tests
with all four library coverage metrics at 100.0% (49,149 detail rows; no stale
annotations). The required web/update, static-file, and SSL security trio
passed 466 assertions. The global 50x target remains pending.

### Problem 48 matched status-route follow-up (2026-10-16)

A fresh Docker resample of the 50-indicator `/system/status` fixture returned
the same HTTP 200 response, 12,864-byte body, and SHA-256 on v5.88 and current
source. Nine runs per source, in separate sequential invocations, measured
63.425219 and 0.262971 ms/request respectively (241.2x in this resample).
Since those samples were not interleaved, the earlier 21-sample matched
177.77x result remains the primary comparison; neither result proves the
per-subroutine target.

Warmed NYTProf traces over 20 requests confirmed exact response parity and
showed current/v5.88 call counts of 20/60 for `config_roots`, 20/160 for
`_merge_named_hash_array`, 60/5,180 for `runtime_layers`, 60/25,200 for
`_ensure_state_dir`, and 20/5,040 for `_write_state_metadata`. These profiles
identify repeated-call removal, not isolated method speed factors. Config-root
discovery, named collector merging, and indicator projection remain current
hotspots. Problem 48's all-subroutine 50x objective is still open.

### Problem 48 rejected home-runtime path-only fast path (2026-10-16)

A red-first Docker test confirmed that using `home_runtime_path` instead of
`home_runtime_root` preserves runtime-layer paths while avoiding directory
creation. The focused PathRegistry suite passed 341 assertions; web-app, d2
alias, and EnvLoader suites passed 523 assertions. A 21-round alternating
benchmark of 2,000 `runtime_layers` calls measured 36.572 ms with ensure and
35.534 ms path-only (1.03x). Although NYTProf initially attributed a much
larger improvement to `config_roots`, the direct measurement showed negligible
gain. The candidate also changed read-side filesystem behavior, so it was
reverted. No implementation change remains from this experiment; Problem 48's
all-subroutine 50x goal is still open.

### Problem 48 status-route config snapshot cache invalidation (2026-10-16)

Expected outcome: unchanged configuration is merged once and safely reused
across web requests; actual config edits, runtime-layer changes, and permission
failures remain visible and explicit.

Reproduction: in Docker, serve `/system/status` with a configured
`DEVELOPER_DASHBOARD_CONFIGS` directory and 50 indicators, issue repeated
requests, and count `Config::merged` calls. Before the fix, every request
remerged configuration. Inotify diagnostics showed repeated `IN_ATTRIB` events
on the runtime directory.

Root cause: `config_roots()` resolves the configured directory through
`_ensure_dir()`, and `secure_dir_permissions()` chmodded the already-`0700`
runtime root each time. The watcher treated those self-generated permission
events as mutations and invalidated the cache. Watch-path discovery also
included unrelated ancestors above the home/project boundary.

Fix: inspect directory mode and chmod only when it differs from `0700`, keeping
stat/chmod errors visible; constrain ancestor watches to the runtime discovery
boundary. Red-first Docker tests cover native cache reuse, configuration
invalidation, path scope, and permission failure branches. The focused suites
passed 428 assertions. Matched 50-indicator route medians were 61.043739
ms/request on v5.88 and 0.160201 currently (381.04x), with exact response
parity and one config merge across warmup plus 2,100 measured requests. This is
a route-specific result; the all-subroutine 50x objective and full delivery
gates remain open.

### Problem 48 status snapshot watcher coverage follow-up (2026-10-16)

Expected outcome: the full Docker coverage gate passes at 100.0% statement,
branch, condition, and subroutine coverage while tests protect the watcher's
fallback, cache invalidation, and bounded path-discovery behavior.

The first full run passed 283 test files / 24,268 tests but reported 99.9%
statement, 99.6% branch, and 99.1% condition coverage. The misses were in the
new `Web/App.pm` snapshot watcher and home/project path-boundary logic. Added
red-first tests for absent/rejected watch backends, diagnostic fallbacks, cache
hit/miss states, malformed skill entries, optional path-provider methods, and
boundary variants. The rerun passed 283 files / 24,307 tests with all four
metrics at 100.0% across `lib/` (49,396 detail rows, no stale uncoverable
annotations). This closes the coverage gap only; the all-subroutine 50x goal
remains open.

### Problem 48 saved-page shared-nav inventory reuse (2026-10-16)

Expected outcome: repeated saved-page requests should not enumerate unchanged
`nav/` directories repeatedly, but nav additions/removals must appear on the
next request and fragment contents must always render fresh.

Root cause: every saved-page request rescanned each inherited nav directory to
discover its `.tt` filenames. Added a per-app filename inventory keyed by the
ordered directories' high-resolution identity and metadata signature. Changed
directories trigger a rescan; incomplete scans are not cached, and stat/read/
close failures remain visible. Red-first tests cover reuse, addition/removal,
malformed entries, missing roots, incomplete opens, and I/O failures. An
integration test confirms editing existing fragment content is visible
without an ID rescan.

Focused Docker suites passed. An alternating 7-pair route comparison preserved
HTTP 200, the exact 10,042-byte response, and SHA-256
`5b217655b90ff66db1d2fdb5a9d3e4aa6a4d4f05f073f1d7f9fc6ec40746d212` in both
modes. Median time was 0.651679 ms/request cached versus 0.667362 uncached
(1.024x, about 2.4%); scan counts were 1 versus 2,103. The full Docker gate
passed 283 test files / 24,346 tests at 100.0% statement, branch, condition,
and subroutine coverage across `lib/` (49,493 detail rows; no stale
uncoverable annotations). This measured route gain is modest and does not
satisfy the all-subroutine 50x requirement; Problem 48 remains open.

### Problem 48 remove duplicate saved-page containment resolution (2026-10-16)

Expected outcome: a saved file's resolved path is checked once immediately
before secure open, not once during candidate lookup and again at the open.
Containment and symlink protections must remain effective for every read.

Root cause: `_existing_page_file` resolved an existing candidate path, then
`_open_saved_page_at` repeated the same containment check immediately before
the no-follow open. A fresh NYTProf profile counted 240 checks across 20
requests (12 candidate checks per request for the main page and five nav
fragments). Removed only the earlier duplicate. The red-first PageStore test
failed before the change with two checks and passes with one; existing symlink
escape tests verify that both parsed and raw reads still reject outside files.

The benchmark includes a control that restores the old extra check. Seven
alternating 21-sample pairs preserved HTTP 200 and byte-identical 10,042-byte
responses. Median-of-run-medians was 0.578761 ms/request with one check and
0.642362 ms with the duplicate (1.11x); containment counts were 12,600 vs
25,200 across 2,100 requests. Pair-level variance was noticeable, so this is a
targeted result only. The full Docker coverage gate passed 283 files / 24,353
tests with 100.0% statement, branch, condition, and subroutine coverage across
`lib/` (49,493 detail rows; no stale uncoverables). Problem 48 remains open.

### Problem 48 request-local saved-page root inventory (2026-10-16)

Expected outcome: all saved-page lookups during one web request use the same
ordered root inventory, while a later request sees newly created runtime
layers. Standalone PageStore calls must remain fresh.

Root cause: `PageStore::_page_file_candidates` called `dashboards_roots` for
each page load. A fresh profile measured six such calls per request for a page
with five nav fragments. `Web::App::handle` now scopes a lazy root snapshot on
the PageStore for that request; it is discarded on return. Red-first tests
confirmed one lookup for the main page plus nav loads, another fresh lookup on
the next request, and visibility of a changed root list between scopes.

The benchmark supports variable nav counts and a control that disables this
cache. Seven alternating 21-sample pairs at five fragments retained exact
response parity and reduced root lookups from 12,600 to 2,100 across 2,100
requests, but the median-of-run-medians (0.584528 vs 0.582500 ms/request) showed
no measurable route gain. At ten fragments, seven alternating pairs preserved
each response hash and reduced lookups from 1,980 to 180; median-of-run-medians
was 0.792992 vs 0.824606 ms/request (1.04x). The route gain is modest and
workload-dependent. The full Docker coverage gate passed 283 files / 24,372
tests with all four `lib/` metrics at 100.0% (49,511 detail rows; no stale
uncoverable annotations). Problem 48's all-subroutine 50x requirement remains
open.

### Problem 48 POSIX saved-page containment normalization (2026-10-16)

The saved-page containment comparison normalized backslashes to slashes on all
platforms. On POSIX, backslash is an ordinary filename character; a configured
root named `root\\segment` could therefore compare as though it were the
different sibling path `root/segment`, accepting an outside candidate.

Reproduction: create both sibling directories under one temporary parent,
place an existing file under `root/segment`, and call
`PageStore::_assert_page_path_contained` with `root\\segment` as the allowed
root. The pre-fix Docker test incorrectly accepted the outside file. The fix
only performs case folding and separator normalization under Windows; POSIX
uses the resolved paths unchanged. The regression now rejects the candidate,
and the existing Windows-comparison test continues to pass. This also removes
two redundant substitutions from the POSIX containment hot path. The Docker
PageStore test passes all 136 assertions. The latest full coverage evidence is
283 files / 24,372 tests with 100.0% statement, branch, condition, and
subroutine coverage across `lib/`; the full gate will be rerun before delivery.
This targeted fix does not establish Problem 48's all-subroutine 50x objective.

### Problem 48 single-pass XS HTML attribute escaping (2026-10-16)

NYTProf showed _escape_html_attr doing two Perl substitutions for every
attribute after body escaping. The implementation now dispatches scalar values
to one XS pass over the five HTML-sensitive bytes. Undefined values, UTF-8
flags, taint, embedded NULs, both quotes, and overload fallback are covered;
source-only builds continue using Perl.

The red-first t/665-problem48-xs-html-escape.t dispatch expectation failed
before native dispatch existed. Its compiled Docker rerun passes 63 assertions,
including native output/flag parity. The new benchmark test passes 11
assertions. Nine alternating 100,000-call samples measured 2.13x for a normal
nav ID and 4.51x for quote-heavy text. Exact route output remained byte-identical
but full-route latency showed no measurable improvement. This is not a
route-wide or all-subroutine 50x result; Problem 48 remains open.

### Problem 48 status-route collector projection reuse (2026-10-16)

Expected outcome: an unchanged watched configuration should normalize its
indicator-collector projection once and reuse it for later status responses;
changing `DEVELOPER_DASHBOARD_CHECKERS` must select a new projection, and the
status response bytes must remain unchanged.

Reproduction: run the 50-indicator status-route benchmark with 100 requests per
sample and 21 samples. Before the change, the same app/config snapshot called
`Config::indicator_collectors` once for every response (2,103 calls including
warmup and timed requests). Change the checker filter and request again to
confirm that the configuration selector affects the response inventory.

Root cause: `_request_config_snapshot` already reused the merged config under a
filesystem watcher, but `_page_status_payload` rebuilt the normalized
indicator-only collector array every time. The snapshot signature also omitted
`DEVELOPER_DASHBOARD_CHECKERS`, which must be considered before caching any
derived projection.

Red-first Docker tests in `t/03-web-app.t` failed as expected: two identical
requests produced two collector projections, and changing the checker filter
left the environment signature unchanged. The fix stores the projection in
the watched snapshot and includes the filter variable in the signature. The
benchmark adds a `--no-collector-cache` exact-output control; `t/672` verifies
that control and the projection count. Both focused tests pass (474 assertions).

Two reverse-order Docker A/B comparisons used identical 50-indicator fixtures,
100 requests per sample, 21 samples per mode, HTTP 200, 12,864 response bytes,
and SHA-256
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`. The
no-cache medians were 0.143151 and 0.148051 ms/request; cached medians were
0.113299 and 0.111630 ms/request, a median paired ratio of 1.29x. Projection
calls fell from 2,103 to 1, while config merge and watcher behavior remained
unchanged. This targeted gain does not establish the all-subroutine 50x goal.
The corrected full Docker coverage gate passed 284 files / 24,419 tests with
100.0% statement, branch, condition, and subroutine coverage across `lib/`
(49,525 detail rows; no stale uncoverables). The required `perldoc perlsec`
command was attempted in the container but could not load a Pod formatter; that
environment limitation is recorded rather than treated as a passed command.

### Problem 48 saved-page literal navigation root provenance and caching (2026-10-16)

Expected outcome: repeated requests to a saved page with unchanged literal
`nav/*.tt` HTML should not search all dashboard layers, reread and decode each
nav file, or allocate/parse page documents. Response bytes, deepest-layer
precedence, immediate edits, dynamic TT behavior, and path containment must
remain unchanged.

Reproduction: inside the `dev` container, run
`P48_LIB=/work/nytprof/v588/lib perl script/problem48-saved-page-route-benchmark
--iterations 100 --runs 21 --nav-fragments 20` and repeat with
`P48_LIB=/work/lib`. The profile and counters showed each route reloading the
literal fragments and resolving candidate roots even though the filename
inventory was already cached.

Root cause: `_scan_nav_directory_ids` returned nav ids but discarded the layer
that supplied each id. `_nav_items_html` then used the general saved-page
resolver, which searched configured roots and built a `PageDocument` for raw
literal HTML. PageStore reread, decoded, and wrapped those same fragments on
every request.

Red-first steps: add tests proving (a) a literal nav lookup returns exact body
without calling the full parser, (b) an unchanged second lookup does not read
the file again, and (c) editing the same file invalidates that cache. Before
implementation, Docker tests failed because `load_nav_fragment` was missing;
the initial implementation then failed the no-repeat-read assertions. Add
security and behavior guards for a cached-path containment check, symlink
replacement, invalid roots, duplicate IDs across layers, dynamic TT, structured
instructions, and bounded item/byte usage. Run `prove` for the affected tests
inside Docker, then rerun both benchmark versions and compare exact status,
length, and SHA-256.

Implementation: the nav inventory now retains the deepest supplying dashboard
root, matching `dashboards_roots` lookup precedence. Custom page resolvers remain
authoritative; the direct PageStore path is used with the built-in resolver.
PageStore verifies that root
against configured layers, checks containment and current file identity on
each request, and reads cache misses with the existing no-follow secure reader.
Literal HTML is stored in a per-store cache capped at 128 entries / 4 MiB, with
individual entries capped at 256 KiB and invalidated by high-resolution lstat
identity (device, inode, mode, size, mtime, ctime). Dynamic TT and structured
pages retain the normal parser and request-context renderer. The cache control
in the benchmark clears cached bodies before each request.

Proof: five focused Docker test files passed 971 assertions. For 20 nav fragments,
both v5.88 and current returned HTTP 200, 11,092 bytes, SHA-256
`95282bc166a550ec0dfaba8737888fcdea84b39cd695aa323fbe785442d6f388`; corrected
medians were 9.256661 and 0.699711 ms/request (13.23x). Current no-cache
measured 1.406310 ms/request and the exact same response. Fragment reads fell from
42,060 to 20. For five fragments, medians were 3.711650 and 0.531738
ms/request (6.98x) with the identical 10,042-byte response hash already recorded
in the benchmark suite. This work is a route-specific improvement, not proof of
Problem 48's 50x all-subroutine goal. Full coverage and the remaining delivery
gates must be rerun before release.

## Problem 48 follow-up: HTML attribute escaping hot path

Expected outcome: plain, long navigation attribute values should avoid
repeated substitution passes while all escaping, Unicode, taint, and overload
semantics remain unchanged.

The saved-page NYTProf report ranked `_escape_html_attr` among the hottest
exclusive helpers. It always called the body escaper and then performed two
quote substitutions, including for ordinary nav IDs. A Docker regression test
was added first to fail if an ordinary attribute called the multi-pass body
escaper; it failed before the implementation. The Perl fallback now scans
plain scalar values of at least twelve characters and returns them unchanged
when none of the five HTML-sensitive characters is present. Short values and
values requiring escaping use the existing substitutions. Red tests also cover
each individual special character and short escaped strings.

The benchmark baseline was audited during this work: it called the public body
helper, so a compiled build could accidentally benchmark XS as the "Perl"
reference. It now calls the pure-Perl helper directly and labels this path in
output. In the `dev` container, the independent 9-sample measurements were
1.63x for a common nav ID without XS and 1.80x with XS; quote-heavy text was
4.20x with XS. The short quote-heavy source-only helper measured 0.89x versus
the lower-level reference because it continues through the substitution path.
Two focused tests pass 82 assertions, including source-only and compiled XS
runs with taint preservation for the plain return path. A fresh 20-request
NYTProf run preserved the exact route response and identified path containment,
`Cwd::abs_path`, repeated saved-page ID validation, and `_state_root_for_layer`
as the next measured hot helpers. Containment will remain intact while those
costs are investigated. No 50x whole-dashboard or per-subroutine claim is made;
the full coverage gate and the rest of Problem 48 remain open.

## Problem 48 regression found by the full gate: lightweight page store

The first full Docker coverage run after the attribute change completed 284
files / 24,470 tests and exposed one failure: `t/105-web-app-coverage-2.t`,
“nav with paths lacking dashboards_layers”. Running that test alone reproduced
the same 1-of-436 failure. The test's lightweight `pages` value is an
unblessed hash; `_nav_items_html` had begun calling its `can` method while
deciding whether to use the PageStore fast path.

The expected outcome is that the direct loader is used only when `pages` is a
blessed object that implements `load_nav_fragment`; the old compatibility
resolver remains in use for a plain hash. The implementation now makes that
guard explicit. The regression test captures and prints `$@` on failure rather
than converting an exception into an empty string. Reproduction after the fix
passes all 436 tests in the affected file. The full coverage gate must be
rerun; the failed full-run coverage metrics are not treated as passing evidence.

The second full run confirmed `t/105` passed but exposed one documentation
failure in `t/15-release-metadata.t`: the new `FIXED_BUGS.md` wording used the
retired term “legacy”. It was changed to “compatibility/test”; the focused
metadata test now passes all 5,742 assertions. A third full coverage run is
required before reporting aggregate coverage.

## Problem 48 current verification update (2026-10-16)

The documentation wording was narrowed to “previous-format page sections”; the
focused `t/15-release-metadata.t` then passed all 5,751 assertions. The raw-nav
fast path also gained explicit fallback tests for section-like text that is
not a recognized page document and for URL nav files, closing the branches
identified by the prior coverage report.

The latest `d2 docker compose exec dev perl script/coverage-gate` run passed all
285 test files and 24,593 tests. Statement, branch, condition, and subroutine
coverage are each 100.0% across `lib/`, with 49,880 detail rows and no stale
uncoverable annotations. The latest matched saved-page benchmark reports an
8.01x route improvement versus v5.88 and a 1.14x improvement over forced
structured parsing for the 20-saved/50-skill-nav fixture, preserving identical
HTTP output. Problem 48 remains open: this does not achieve the all-subroutine
50x objective. The repository security source scans and required Docker
security-test trio have passed; the full documentation audit, packaging, and
release checks remain to be completed.

The latest full Docker gate (2026-10-16) supersedes the earlier test count:
285 files and 24,620 tests passed. Statement, branch, condition, and subroutine
coverage are all 100.0% across `lib/` (49,932 detail rows; no stale
uncoverable annotations). The remaining delivery work and the all-subroutine
50x performance objective are still open.

A 20-request production-route profile with 20 saved and 50 skill nav fragments
now has a matched v5.88 comparison, using repository commit `a8d1fa2a`. Both
versions returned HTTP 200 and identical 14,942-byte normalized output. The
profiler-instrumented medians were 123.889 ms/request on v5.88 and 14.439
ms/request on current source (8.58x; profiler-inflated, not wall-clock). Current
skill-layer resolutions fell from 3,000 to 1,000; saved-nav reads fell from 460
to 20 including baseline initialization and warmups. The all-subroutine 50x
target remains unproven; `_all_installed_skill_names` is the next profiling
candidate.

A static skill-nav preparation bypass was also tested and rejected. It preserved
the exact response and removed those calls, but repeated 100- and 200-request
Docker comparisons did not show a stable route improvement; the temporary code
and tests were reverted. No speedup is claimed for that candidate.

A further controlled 50-skill-nav comparison of the existing raw-fragment
parser bypass measured 4.081211 ms/request versus 4.100540 ms/request when
structured parsing was forced (1.005x) over 31 samples, with identical HTTP
output. A reverse-order pair showed greater timing variance, so this result
does not support an incremental speedup claim or a new code change.

A combined-regex rewrite of the raw skill-nav format detector was also rejected:
it matched seven representative inputs but took 1.415 s for 500,000 common raw-
HTML checks versus 0.422 s for the existing detector. This was an isolated
microprobe, not a full parity test; no production change was made.

A bounded per-dispatcher cache for pure route-segment validation was tested and
removed. Although NYTProf showed fewer validation calls, the unprofiled
100-request/31-sample route control was slower with the cache (3.981490 ms)
than with direct validation (3.777671 ms), with identical response bytes.

A fast marker-token precheck for common raw nav text also failed the matched
profile: the precheck plus detector cost 3.27 ms over 1,000 calls, versus 2.81
ms for the existing detector path. Its temporary implementation and tests were
removed; no performance gain is claimed.

Problem 48 skill-nav discovery now consumes PathRegistry's bulk installed-skill
entries for top-level skills, reusing their layered roots while resolving
nested skills through the existing path. The benchmark includes a tested
legacy-loop control. Two alternating 100-request/31-sample pairs preserved the
same HTTP 200 response hash; bulk medians were 3.773839/3.644860 ms/request
versus 4.254751/4.386990 for the former loop. Measured skill-layer resolutions
fell from 155,000 to zero. This is a fixture-specific improvement, not proof of
the 50x all-subroutine objective.

The follow-up full Docker coverage gate passed 285 files / 24,642 tests with
statement, branch, condition, and subroutine coverage all at 100.0% across
`lib/` (49,972 detail rows; no stale uncoverable annotations). The required
`perldoc perlsec` invocation was attempted after the gate but the container's
Pod::Perldoc formatter loader failed; the same installed `perlsec.pod` was
successfully rendered by `pod2text`.

A short exact-source status-route comparison against the v5.88 commit was
rerun after the latest navigation and collector changes. Five runs of 20 warmed
requests preserved HTTP 200, the exact 12,864-byte response, and its SHA-256;
the medians were 57.779455 ms/request for v5.88 and 0.104547 ms/request for
current source (552.67x on this fixture). This corroborates route performance
only; the required 50x result for every subroutine remains unproven.

The latest saved-page profile showed every literal installed-skill nav
fragment was still passed through PageRuntime although only dynamic TT or
structured instructions need it. A red-first Docker regression now proves
literal skill nav skips preparation while dynamic TT still executes. On the
20-saved/50-skill fixture, the exact 14,942-byte response and SHA-256 were
unchanged; 21 runs of 100 requests measured 3.553019 ms/request before and
3.153169 after (1.13x). This is limited to the tested route and leaves the
all-subroutine 50x requirement open.

The Linux-only inotify shortcut previously meant config snapshots were reused
only on Linux; other systems rebuilt merged configuration on each request.
Problem 48 now has a portable validator using layered-directory metadata and
SHA-256 of exact config files, so unchanged snapshots can be reused on all
platforms while file edits/additions/removals trigger a reload. Focused Docker
tests force the native watcher to be unavailable and verify cache hits,
invalidation, and fallback after runtime watcher-setup rejection. The
cross-platform GitHub workflow now runs matched automatic and forced-portable
status-route benchmarks on every runner. A reproducible paired Linux run
preserved the exact 12,864-byte response and measured 0.336020 ms/request
portable versus 0.117619 automatic (2.86x slower). macOS/Windows benchmark
results remain pending; this closes the config-snapshot cache availability
gap, not the broader all-subroutine 50x target.

### Problem 48 cross-platform native watcher follow-up (2026-10-16)

To avoid leaving the native acceleration Linux-only, the watcher adapter now
has optional Mac::FSEvents and Windows wide-character directory-change
backends alongside Linux inotify. Portable SHA-256 validation remains
available when native modules are missing or setup fails. The platform
workflow now installs those optional modules and fails if a native watcher
cannot be constructed; its real-filesystem test writes a file and checks that
each platform invalidates the cached snapshot. The focused Docker Linux test
passes 102 assertions. macOS and Windows native execution remains unverified
until GitHub Actions runs, and Problem 48 remains open.

### Problem 48 portable configuration-inventory reuse (2026-10-17)

Expected outcome: portable configuration freshness checks should inspect every
current skill layer on every request, detect newly added or changed config
files, and avoid repeating the same installed-skill discovery within one
validation pass. A red-first test using a synthetic skill layer observed four
installed-skill lookups on the initial cache fill and two on a subsequent
cache hit. The repeated call path was `_config_snapshot_watch_paths` followed
by `_config_snapshot_portable_signature`, each of which independently called
`installed_skill_entries`; the post-merge validation is a separate required
freshness check.

The implementation passes each discovered skill inventory into the portable
signature and rediscovers the inventory for the post-merge check. The test now
expects two lookups for an initial fill and one per unchanged cache hit, and
checks explicit errors for malformed optional inventory arguments. Docker
`t/03-web-app.t` passes 507 assertions. Before/after profiled runs kept HTTP 200
and the exact 12,864-byte response hash; the portable-signature inclusive
profile changed from 18.2 ms to 15.6 ms over 100 calls. This is instrumented
time on a fixture with no installed skills, not a route-level or v5.88 speedup.
The updated 21-sample portable route median is 0.251069 ms/request, but a
matched pre-change route control was not retained. No 50x claim is made.

The final Docker coverage run passed all 285 test files and 24,840 tests with
100.0% statement, branch, condition, and subroutine coverage across `lib/`
(50,496 detail rows; no stale uncoverable annotations). The direct `perldoc
perlsec` command was also attempted after the gate but failed because the dev
image has no loadable Pod::Perldoc formatter; the installed security manual
was successfully rendered with `pod2text`. The all-subroutine 50x objective
and the remaining package/image and Git delivery checks are still open.

### Problem 48 Windows path-ancestry correctness (2026-10-16)

Expected outcome: a normalized child path is recognized beneath its root on
all supported OSes, while a sibling sharing only a textual prefix is rejected.
The replication used `File::Spec::Win32->canonpath` for
`C:\Users\Alice\project` and `C:\Users\Alice`, then called the shared
already-normalized identity comparator. Before the fix, the focused test
failed for backslash children, case-tolerant paths, and a drive-root parent;
the source showed that the comparator always appended `/`.

The fix uses `File::Spec->rootdir` and queries
`File::Spec->case_tolerant($volume)` for the root's volume, preserving the
component-boundary rule and avoiding a duplicate separator when the root
already ends in one. Red-first cases also reject `C:\Users\Alicia` as a child
of `C:\Users\Alice`. After the fix, the focused Docker PathIdentity and
PathRegistry suites passed 397 assertions, and the watcher regression passed
102 assertions. This proves deterministic Win32 semantics through the
injected-platform tests, not execution on Windows; the required Windows x64
and arm64 workflow runs remain pending.

### Problem 48 literal skill-nav document reuse (2026-10-17)

Expected outcome: avoid rebuilding unchanged literal skill-nav documents on
each dashboard request, while file edits and route additions/removals remain
visible immediately and dynamic or structured pages continue through the full
parser/runtime path.

A red-first Docker regression showed repeated page construction for unchanged
literal `nav/*.tt` fragments. `Web::App` now reuses one dispatcher per app, and
that dispatcher keeps a bounded 256-entry / 8 MiB FIFO cache for literal raw
nav documents only. It still resolves the file and compares device, inode,
mode, size, high-resolution mtime, and ctime on each request. Dynamic TT and
structured pages are not cached. Docker tests cover same-size content edits,
route creation/removal, object reuse, and malformed cache state.

Two paired current-source Docker comparisons used 100 skill fragments, 20
saved nav fragments, 100 requests × 21 samples per run. Both modes returned
HTTP 200 and the exact 18,792-byte response with SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`. Mean
run medians were 4.754831 ms/request cached and 6.021790 uncached (1.2665x).
Content reads were 100 per enabled run and 210,300 per uncached run. This is
only a modest route-level gain; it does not prove the 50x target for every
subroutine. Problem 48 remains in progress.

Coverage follow-up: the complete Docker gate passed 285 test files and 24,910
tests, with statement, branch, condition, and subroutine coverage at 100.0%
across `lib/` (50,667 detail rows; no stale uncoverable annotations). Added
explicit malformed-FIFO-eviction and wrong-dispatcher-class cases. `perldoc
-T perlsec` could not load a formatter in the dev image, so the applicable
Perl 5.40 `perlsec.pod` sections were reviewed directly. The 50x objective and
hosted cross-platform workflow results remain open.

### Problem 48 skill-nav route inventory reuse (2026-10-17)

Expected outcome: avoid rescanning unchanged nested `dashboards/nav` directory
trees on every request while still observing a new or removed route on the next
request.

Before the change, `_skill_nav_route_ids` called `_relative_files` for every
layered skill on each render, even though literal page documents were already
cached. The fix adds a bounded per-dispatcher inventory cache. It validates
high-resolution metadata for every visited directory before reuse, rescans on
any difference, and keeps the existing route resolution and containment checks
for each file. Unstable scans are not cached. Red-first Docker tests verified
two initial root scans, zero repeat scans, and a rescan for a newly added route;
existing regressions also verify route removal and byte-exact response parity.

The two focused Docker files pass 295 assertions. The final full Docker
coverage gate passed 285 files / 24,976 tests with all four `lib/` metrics at
100.0% (50,889 detail rows; no stale uncoverable annotations). The 64-root
cache initially churned on this 100-root fixture, so
its bound is now 128 roots; validated route segments are reused by the internal
nav loader and still receive traversal/separator/control checks. A 100-skill
route benchmark (100 requests, 9 samples) preserved the response SHA-256 and
reduced recursive scans from 90,300 to 100. Sequential medians were 3.794620
ms/request with inventory reuse and 7.907050 ms/request with the cache-disabled
control (2.08x; not an alternating paired run). This is a small incremental route
improvement, not the requested 50x for every subroutine. The all-routine
performance objective and hosted cross-platform workflow results remain open.
The full-suite matrix covers Linux x64/arm64, macOS Intel/arm64, and Windows
x64. Windows ARM64 has a separate native watcher smoke job, not a full-suite
job, because the hosted image currently provides Perl 5.32.1 while the project
requires Perl 5.38 and the setup action does not list Windows ARM64 as a target.

### Problem 48 rejected environment-signature cache (2026-10-17)

Expected outcome: memoizing an unchanged
`Web::App::_config_snapshot_environment_signature` must preserve exact
signature changes when relevant environment values change and improve measured
runtime. A red-first Docker test established that the current implementation
JSON::XS-encodes twice for two stable calls and three times after changing
`DEVELOPER_DASHBOARD_CHECKERS`. A candidate exact-scalar cache made the focused
test pass, but an alternating 9-run microbenchmark of 50,000 calls measured
418.531 ms cached versus 331.603 ms forcing JSON::XS (0.79x). A length-framed
fingerprint alternative also regressed at 536.025 versus 332.344 ms (0.62x).
Both candidates and their temporary assertions were removed because they
regressed. Production behavior is unchanged. The current NYTProf profile and
an unprofiled paired benchmark remain the basis for the next optimization; the
50x all-subroutine target remains open.

### Problem 48 refreshed v5.88 status-route comparison (2026-10-17)

Inside the Docker `dev` container, the exact v5.88 library from commit
`a8d1fa2a` was re-extracted and measured with the current status-route
benchmark. Matched 21-run workloads used 50 indicators and 100 requests per
sample. Both sources returned HTTP 200 and the same 12,864-byte response SHA-256
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`. The
baseline measured 63.530080 ms/request and current source 0.164301 ms/request
(386.68x for this route fixture). The current run performed one config merge
and 4,205 watcher checks/hits; v5.88 performed 6,309 merges and had no watcher.
This does not prove 50x for every subroutine or workload; Problem 48 remains
open.

### Problem 48 refreshed nested skill-nav baseline and hotspot map (2026-10-17)

Inside Docker `dev`, current source and exact v5.88 library `a8d1fa2a` were
compared with 100 skill nav roots, 20 saved nav fragments, 100 requests per
sample, and 21 runs. Both returned HTTP 200 and the same 18,792-byte response
SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`. Baseline
was 70.445819 ms/request; current was 9.496582 ms/request (7.42x), below the
50x target. A warmed NYTProf run showed 10,000 calls each to `_page_location`,
`_skill_nav_inventory`, and `_load_skill_page`; `File::Spec::Unix::catdir`
accounted for 167 ms exclusive under profiling. These totals overlap and are
not production timings. The next candidate is a watcher-validated aggregate
literal-nav snapshot, retaining portable validation if a watch set is
unavailable or reports a change. The per-subroutine 50x goal remains open.

### Problem 48 watcher-validated aggregate skill-nav snapshot (2026-10-17)

A red-first Docker test exposed that `all_skill_nav_pages` repeated every
`_load_skill_page` call even after literal page content and route inventories
were warm. A bounded aggregate page array now skips that work only when all
entries are static literal nav fragments and the cross-platform watcher reports
an unchanged runtime-root and filesystem inventory. The watch set covers skill
and runtime roots, creation parents, dashboards/nav parents, and discovered
nested nav directories. An event returns to normal directory inventory and
per-file checks; unavailable or failed watchers disable the aggregate cache
with explicit diagnostics. Dynamic pages and oversized snapshots are excluded,
and dispatcher destruction closes the watcher.

Focused Docker coverage passes 239 assertions, including file edits, route
additions/removals, runtime-root changes, watcher failures, fallback, and
cleanup. The matched 100-skill/20-saved-fragment benchmark preserves HTTP 200
and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724` and falls
from 9.496582 to 2.258520 ms/request (4.21x incremental). Against v5.88's
70.445819 ms/request, this workload is 31.19x faster, still below 50x. NYTProf
now points to saved-nav rendering and `PageStore::load_nav_fragment` as the
next hot path. The all-subroutine 50x goal remains open.
### Problem 48 rejected parsed-page cache candidate (2026-10-17)

The expected result was exact saved-page response parity with a lower warmed
route latency. A watcher-backed parsed-page cache and detached document clone
passed focused correctness tests, but a Docker comparison measured 0.699959
ms/request with the cache versus 0.474980 ms/request without it (0.68x). Cloning
cost more than parsing this page, so the candidate implementation and tests
were removed. The post-removal focused Docker suites pass 676 assertions.

The matched 100-skill/20-saved-nav benchmark produced the same HTTP 200, 18,792
bytes, and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724` on exact
v5.88 (`a8d1fa2a`) and current source. Across 21 samples of 100 requests,
medians were 108.165948 and 0.377908 ms/request (286.22x for this route only).
This does not prove the requested 50x gain for every subroutine. Fresh NYTProf
data points to HTML escaping, page chrome, runtime-layer lookup, document render,
and page loading as remaining investigation candidates. Problem 48 remains in
progress.

### Problem 48 matched 100-skill route recheck (2026-10-17)

Repeated the current and v5.88 route benchmark with the same arguments: 100
installed skill nav fragments, five saved nav fragments, 100 requests per
sample, and nine samples. Both returned HTTP 200 and the same 17,742-byte body
with SHA-256
`c481093b9c88db29e384a545305c4fc02056feaf652682691a13a962939e1270`.
Medians were 102.897069 ms/request for v5.88 and 0.560360 ms/request for
current source (183.65x on this fixture). Disabling only the aggregate literal
skill-nav cache raised current latency to 21.126659 ms/request while preserving
the same body. This is strong workload-specific evidence, not proof that every
subroutine or platform is 50x faster. The full coverage gate must be rerun after
the latest test additions; Problem 48 remains in progress.

An additional exact Docker comparison used 100 skill-nav roots, 20 saved nav
fragments, 100 requests per sample, and nine samples. The v5.88 and current
responses both returned HTTP 200 with the same 18,792-byte SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`.
Medians were 135.065870 ms/request and 1.136279 ms/request (118.87x for this
route fixture). This strengthens the route-level result, but not the separate
requirement to establish a 50x gain for every subroutine and platform.
At the time of this benchmark note, the latest complete Docker run had executed
285 files and 25,135 tests successfully, but the coverage gate failed: aggregate
branch coverage was 99.8% and condition coverage was 98.9%. Follow-up focused
dispatcher and PageDocument tests passed (306 and 89 assertions, respectively).
A newer full-gate result is recorded below.

### Problem 48 full coverage gate recheck (2026-10-17)

The expected result was a passing full metric gate after the additional
dispatcher and saved-navigation-root tests. In the Docker dev container,
`./script/coverage-gate` completed the complete 285-file suite: all 25,162 tests
passed. The gate still fails its coverage thresholds. Aggregate statement,
branch, condition, and subroutine coverage is 100.0%, 99.9%, 99.3%, and 100.0%.
Remaining gaps are `SkillDispatcher.pm` at 100.0/99.8/95.7/100.0 and
`Web/App.pm` at 100.0/99.3/97.3/100.0 (same metric order); at that point the
focused dispatcher and web-app tests passed 326 and 499 assertions. Seven more
dispatcher assertions now pass in isolation, but the full gate has not been
rerun against them. This is not a gate pass. More branch and condition cases
remain. The all-routine 50x performance target also remains unmet.

### Problem 48 headerless fetch-metadata fast path (2026-10-18)

Expected behavior: requests with absent, undefined, or reference-valued
`Sec-Fetch-Site` remain non-foreign and do not trigger cross-site rejection.
Direct assertions for these cases were added first. `_fetch_site_is_foreign`
now exits before lowercase/trim normalization for those shapes. The Docker
cross-site suite passes 34 assertions, preserving the scalar cross-site and
same-site checks. Nine alternating one-million-call headerless samples
measured 370.968 ms before and 298.395 ms after (1.24x). This small common-case
gain does not establish the 50x-per-subroutine target; Problem 48 remains open.

An exact-label fast path now handles the common `same-origin` and `none`
values before normalization. The 35-assertion Docker test retains the varied
casing/spacing, same-site, and cross-site cases through the existing security
path. Nine alternating one-million-call samples for exact `same-origin`
measured 830.125 ms before and 442.506 ms after (1.88x against the previous
absent-header-only implementation). This incremental classifier result is not
a universal 50x result.

### Problem 48 full gate after fetch-metadata fast paths (2026-10-18)

The full Docker gate passed after the latest production and test changes:
285 files, 25,233 tests, and 100.0% statement, branch, condition, and
subroutine coverage across `lib/` (51,573 detail rows, no stale uncoverable
annotations). Checks skipped for optional tools are not counted as passes.
Problem 48 remains in progress because the per-subroutine 50x target and
cross-platform workflow results are not yet proven.

### Problem 48 lightweight page identifier reads (2026-10-18)

Expected behavior: read a page identifier without allocating the complete
public hash view and preserve the exact page-route output. The nav regression
was written first and failed when `PageDocument::as_hash` was replaced with a
failing stub. Added `PageDocument::id` and switched known document call sites
in the web renderer to the accessor; the full `as_hash` API is unchanged.
Focused PageDocument and web-app Docker suites pass 625 assertions. Nine
alternating million-read samples measured 5.56x for `id()` versus
`as_hash->{id}`. A matched v5.88/current 100-skill/20-saved-nav comparison
preserved HTTP 200, 18,792 bytes, and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`; medians
were 58.338089 and 0.367992 ms/request (158.53x for this fixture). This route
result is cumulative and does not prove the 50x target for each subroutine.
The full coverage gate is recorded below; Problem 48 remains in progress.

### Problem 48 full coverage gate after page-id accessor (2026-10-18)

The complete Docker coverage gate was rerun after the accessor and renderer
changes. All 285 test files and 25,236 tests passed. Statement, branch,
condition, and subroutine coverage are 100.0% across `lib/` (51,582 detail
rows, no stale uncoverable annotations). Optional browser, Windows, CPANTS,
POD, and audit-tool checks remain unverified. This does not prove the
all-subroutine 50x target; Problem 48 remains in progress.

### Problem 48 canonical flat page-id validation (2026-10-18)

A fresh profile ranked `PageStore::_validated_page_id` at 4.52 ms across 300
calls, including the common plain `welcome` identifier. Red-first Docker tests
proved canonical flat names must bypass `_normalized_page_id`; the new path is
restricted to single-segment ASCII identifiers. Prefixes, nested paths,
Unicode, whitespace, refs, and unsafe components still use the original
normalization and validation checks. The PageStore suite passes 216
assertions. Nine alternating million-call samples measured 879.049 ms for the
prior path and 430.213 ms after (2.04x), with exact returned values. This
helper gain does not establish 50x for every subroutine.

### Problem 48 full Docker coverage and refreshed profile after flat-id validation (2026-10-18)

The clean Docker `dev` coverage gate passed all 285 test files and 25,238
tests. Statement, branch, condition, and subroutine coverage are each 100.0%
across `lib/` (51,588 detail rows; no stale uncoverable annotations). Optional
browser, Windows, CPANTS, POD, and audit-tool checks remain separate. The
required `perldoc -T perlsec` command failed because the image lacks a text
formatter; the installed core `perlsec.pod` source was read directly afterward.

A fresh NYTProf run of the unchanged 100-skill/20-saved-nav fixture preserved
HTTP 200, 18,792 bytes, and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`. It
measured 1.966288 ms/request under instrumentation and ranked
`PageDocument::_parse_legacy_sections` (6.83 ms exclusive),
`PathRegistry::_write_state_metadata` (5.24 ms), `_top_chrome_html` (5.19 ms),
`_top_context_html` (5.08 ms), `_page_status_payload` (4.80 ms), and
`PageStore::_open_saved_page_at` (4.71 ms). Those instrumented costs overlap
and are not production timings. No candidate is a win before red-first
behavior tests and paired unprofiled benchmarks. Problem 48's all-subroutine
50x objective remains open.

### Problem 48 scalar mode accessor for top chrome (2026-10-18)

Expected outcome: read the display mode without materializing the full page hash
and preserve top-chrome output. A red-first Docker test replaced
`PageDocument::as_hash` with a failing stub around render-mode chrome and failed
before the change. Added `PageDocument::mode`; `_top_chrome_html` now uses it
and retains the `edit` default. The focused PageDocument and web-app suites pass
629 assertions, including exact render-mode button behavior. Nine alternating
Docker samples of one million calls measured 1,010.759 ms for
`as_hash->{mode}` and 213.278 ms for `mode()` (4.74x), with exact value parity.
This helper result does not establish 50x for every subroutine. The subsequent
clean Docker coverage gate passed all 285 files and 25,242 tests with 100.0%
statement, branch, condition, and subroutine coverage across `lib/` (51,597
detail rows; no stale uncoverable annotations). Optional browser, Windows,
CPANTS, POD, and audit-tool checks remain separate. `perldoc -T perlsec` could
not render because its formatter is absent; the installed core `perlsec.pod`
was read directly after the gate. Problem 48 remains in progress.

### Problem 48 rejected saved-nav signature cache (2026-10-18)

Expected outcome was to avoid repeated JSON serialization while preserving
watcher freshness and ordered-root identity. A red-first Docker test confirmed
serialization occurred on every cache lookup. The candidate cache passed its
focused behavior checks, but a matched Docker microbenchmark with 100 realistic
roots and 1,000 calls per sample measured 7.742 ms for JSON encoding versus
12.114 ms for cached root comparisons (0.64x). Two length-framed alternatives
were slower (0.46x and 0.29x) and were also removed. No production change or
test from this candidate remains; the established JSON signature stays in
place. Problem 48 remains open.

### Problem 48 rejected `_trim` boundary-check fast path (2026-10-18)

A nine-sample Docker benchmark of 500,000 calls compared the existing trim
substitutions with a candidate boundary-whitespace check. Exact output parity
held for plain text, edge whitespace/newlines, and Unicode non-breaking spaces,
but candidate speedups were only 0.57x, 0.92x, and 0.49x respectively. The
slower candidate was discarded and production behavior is unchanged. This is
not evidence for the all-subroutine 50x goal; Problem 48 remains in progress.

### Problem 48 repeated builtin class and signature dispatch benchmark (2026-10-18)

The Docker benchmark was rerun on Perl 5.40.1 with one million calls and nine
rotating samples. All methods returned identical values. Blessed-hash median
was 85.389 ms, signature-method median 111.106 ms, and builtin class/field
median 102.217 ms (0.77x and 0.84x relative to blessed hashes). These features
do not accelerate this dispatch workload; no global rewrite is justified by
this measurement. It does not establish a full-application or per-subroutine
50x result.

### Problem 48 refreshed Memoize path-identity comparison (2026-10-18)

In Docker, 250 unique paths repeated twice were resolved across nine
alternating samples. All ordered identities matched, and symlink retargeting
was detected at operation boundaries. Medians were 2.205 ms uncached,
1.175 ms with a request-local hash (1.88x), and 1.446 ms with Memoize flushed
per operation (1.52x). This supports the explicit request-scoped hash for this
workload, not broad Memoize use or a universal speedup claim.

### Problem 48 repeated XS attribute-escape benchmark (2026-10-18)

With the built extension loaded from `blib/arch`, nine alternating 100,000-call
Docker samples preserved exact output parity. Plain nav text measured 0.000495
versus 0.000279 ms/call (1.77x); quote-heavy input measured 0.001315 versus
0.000286 ms/call (4.59x), Perl reference versus production XS path. The gain is
limited to this helper and does not prove a route-wide or all-subroutine 50x
improvement.

### Problem 48 XS helper impact on the saved-page route (2026-10-18)

Nine alternating process pairs ran the same `/app/welcome` fixture (100
requests per sample; 20 saved-nav and 100 skill-nav fragments). All outputs
matched HTTP 200, 18,792 bytes, and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`. The
median of per-process medians was 0.343490 ms/request without XS and 0.343912
ms/request with XS (0.999x): no route-level gain was measurable. This confirms
that the isolated helper acceleration did not materially affect this workload.

### Problem 48 rejected colon-index legacy parser candidate (2026-10-18)

An experimental parser used `index` to locate the header colon before copying
the body. A four-section, 800-byte-body fixture produced identical canonical
parse output, but nine alternating 10,000-call Docker samples measured 652.764
ms for the current parser and 658.969 ms for the candidate (0.99x, with
canonical serialization checked in each iteration). The slower candidate was
not retained; production behavior is unchanged.

### Problem 48 prompt-summary list allocation reduction (2026-10-18)

A red-first Docker regression protects ordered status and Unicode alias output
for 50 rows and confirms the payload array is not consumed or mutated. The
implementation now maps directly over the status array and joins once, instead
of copying the array and constructing a second parts list. The focused web
suites pass 1,054 assertions. Nine alternating 100,000-call samples measured
865.926 ms before and 797.271 ms after (1.09x). This helper result does not
establish 50x for every routine or the full route.

### Problem 48 freshness-validated prompt-summary reuse (2026-10-18)

Expected outcome: cached top-chrome text is reused only when the existing
collector and indicator freshness checks prove no changes, while status-file
updates are reflected immediately on the next request. Before the fix,
`_prompt_summary` requested a full payload every time and never used the
existing unchanged-result contract. A red-first Docker test failed because the
summary did not pass a freshness signal and skip flag; it now verifies reuse,
changed-data refresh, and invalid cache recovery. The focused web and benchmark
suites pass 665 tests. With 50 indicators and 100 skill-nav roots, nine
unprofiled samples measured 1.117690 ms/request with summary reuse disabled and
0.435739 ms/request enabled (2.56x); both returned the identical 19,341-byte
response hash. NYTProf showed `list_indicators` calls dropping from 704 to 2.
With the native watcher forced off, the portable path preserved output but
showed no measurable speedup. Problem 48's all-subroutine 50x goal remains
open.

### Problem 48 latest saved-page profile and v5.88 route recheck (2026-10-18)

The current Docker benchmark used 100 requests, 20 saved-nav fragments, 100
literal skill-nav fragments, and 50 indicators. Against the v5.88 source, the
current-source median was 0.345440 ms/request versus 117.586670 ms/request
(340.3x for this exact route fixture). Both responses were HTTP 200, 19,341
bytes, with SHA-256
`a3c1df9346d5b1c2942fbec1354e2dbb8dcc268e0e148107787197635a7ed331`.
Each source's five-run median was measured in a separate process, so this is
not an alternating-pair result and does not attribute the cumulative gain to
one optimization. It proves a route-level result only, not 50x for every
subroutine or platform.

A fresh NYTProf run preserved that response and measured 1.661699 ms/request
under instrumentation. The highest exclusive totals were
`PathRegistry::_ensure_state_dir` (11.3 ms over 300 calls),
`Web::App::_nav_items_html` (8.67 ms over 100 calls), and
`Web::App::_render_page_html` (7.65 ms). These overlapping profile totals rank
follow-up candidates. The 100 skill-nav content reads and inventory scans were
the one-time cache warmup across the 100 fixture skills. State-directory
permission and identity checks, watcher freshness, and runtime-layer
visibility remain correctness and security invariants; the profile alone does
not justify skipping them.

An additional v5.88/current NYTProf comparison shows that `_nav_items_html`
exclusive time dropped from 32.8 ms over 10 requests to 8.67 ms over 100
(37.8x by request contribution). `_ensure_state_dir` dropped from 53.5 ms over
10 requests to 11.3 ms over 100 (47.3x contribution), with invocation count
falling from 12,600 to 300; its implementation is unchanged, and its secure
directory-mode check is still required. A candidate fast-stat rewrite measured
only 1.015x over the common existing-secure-directory case and was not adopted.
These profile timings are directional, not paired request measurements. The
per-subroutine 50x requirement therefore remains open.

The complete Docker coverage gate now passes all 285 files and 25,325 tests,
with statement, branch, condition, and subroutine coverage at 100.0% across
`lib/` (51,685 detail rows and no stale uncoverable annotations). The added
undefined and reference-id characterization cases cover the fallback guards
in `_normalized_saved_page_id`. Optional
browser, Windows QEMU, CPANTS, POD, and audit-tool checks were skipped because
their optional dependencies or runtime setup were unavailable. Problem 48
remains in progress because the 50x-per-subroutine requirement and the
cross-platform performance comparison are not established.

### Problem 48 canonical saved-page id fast path (2026-10-18)

Expected outcome: canonical flat ASCII ids return unchanged without trim or
prefix processing; nested, prefixed, whitespace-bearing, Unicode, undefined,
and other ids retain the established behavior. The red-first regression failed
because the canonical case still called `_trim`; after the change only the
narrow `[A-Za-z0-9_.-]+` class bypasses the legacy normalizer. Docker tests
`t/03-web-app.t` and `t/676-problem48-page-id-benchmark.t` pass 552 assertions.
Three alternating route pairs retained HTTP 200 and the same 19,341-byte
response hash. Old/current per-pair medians were 0.427339/0.393169,
0.422330/0.345271, and 0.365710/0.347531 ms/request; median-of-pair medians
improved from 0.422330 to 0.347531 (1.21x). This is a measured route
improvement, not 50x for every routine. The full coverage gate passes after
adding explicit undefined and reference-id fallback cases: 285 files, 25,325
tests, 100.0% statement/branch/condition/subroutine coverage across `lib/`
(51,685 detail rows, no stale uncoverable annotations). Problem 48 remains in
progress.
