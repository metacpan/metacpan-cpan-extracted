# Problem Report

Problems are listed in numeric order. This file is the current status index;
`doc/problem-report.txt` retains the historical investigation and release log.
Statuses distinguish functional verification from release/commit delivery.

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

### Problem 25: Keep Dashboard help on internal CLIs and preserve external CLI help — in progress (5.51; image-build gate failed)
Help metadata and completion include nested actions/options; delegated grep, Docker Compose, and dotted skill-command help pass through to their owning CLIs. The private `skills _exec` dispatch sentinel is not treated as a public help action. The isolated Docker reproduction, full Docker test suite (257 files / 22,957 tests), 100% statement/branch/condition/subroutine coverage, and clean-container 5.51 tarball integration passed. `d2 docker.images.build` did not produce a new image: Docker BuildKit failed at the Dockerfile's first `RUN curl ... | sh` layer with `mount options is too long` (the wrapper continued and returned success). Do not treat Problem 25 as complete until that required image gate succeeds. Tests include `t/265-cli-help-completion-contract.t` and `t/266-cli-help-dispatch.t`.

### Problem 26: Preserve full branch labels in `ps1` across all shells — done in 5.37/5.38
Branch names retain slashes; `origin/` is removed only when an equivalent local branch exists. Full evidence is in the historical report.

### Problem 27: Restore `of` content grep and complete Perl `@INC` lookup (78d6573d; package follow-up) — done
`d2 of grep` searches content safely via argv and module lookup traverses every `@INC` root. Focused tests cover matches, errors, print mode, editor dispatch, and multiple roots.

### Problem 28: Resolve collector working-directory path aliases (78d6573d) — done
Collector `cwd` accepts config aliases and skill Folder.pm aliases, with config-first precedence. Regression coverage: `t/103-collectorrunner-coverage.t`.

### Problem 29: Determine whether stopping a collector stops its child processes — investigation pending
The requested Docker reproduction and verified stop-propagation result are missing from the tracked report. Do not infer process-tree behavior from dispatcher shutdown; complete an isolated container investigation before marking done.

## Problems 30–34: Collector, marker, completion, and Compose behavior

### Problem 30: Repair config.json collector cron scheduling — done in 5.44
Five-field cron expressions support names, lists, ranges, steps, crontab day matching, and per-minute deduplication; missing/invalid schedules fail visibly. Regression coverage: `t/103-collectorrunner-coverage.t`.

### Problem 31: Honor Docker service markers at every layer — done in 5.44/5.45
Markers are discovered and removed across active service layers; newly written markers use the selected home runtime. Regression coverage: `t/10-extension-action-docker.t`, `t/361-dockercompose-coverage.t`.

### Problem 32: Separate command/path completion and make cdr completion responsive — done in 5.48
Root command completion no longer mixes path aliases; `workspace` completion includes configured and Folder.pm aliases. `cdr` completion lists direct children and narrows one directory level per entered term. Docker regressions: `t/69-cli-complete-coverage.t`, `t/90-cli-paths-coverage.t`; measured fixture returned 40 candidates in 0.131 seconds.

### Problem 33: Keep an unregistered first `cdr` word as a search pattern — done in 5.48 (existing behavior regression-guarded)
If the first `cdr` word is not a registered alias, it remains a search term and participates in later TAB narrowing. Current implementation already preserves it; new targeted assertions in `t/90-cli-paths-coverage.t` verify resolution and `t/69-cli-complete-coverage.t` covers completion behavior. No production code change was needed for this report item.

### Problem 34: Limit automatic Compose services to the local Compose project — done in 5.48
When cwd contains a supported Compose file, it is the base and only runtime services declared by that file are automatically merged. Explicit service selection remains possible, and runtime discovery is unchanged when no local base exists. Red-first and follow-up Docker regressions: `t/94-dockercompose-coverage.t`, `t/10-extension-action-docker.t`.

### Problem 35: Configure a real Dist::Zilla releaser for `dzil release` — done in 5.50
`dist.ini` now configures `Dist::Zilla::Plugin::UploadToCPAN`, so an explicit `dzil release` has a real PAUSE upload action. The release-metadata test failed before the stanza and passes after it; `dzil authordeps` lists the plugin, Dist::Zilla resolves it as a `-Releaser`, and `dzil build` succeeds and produces `Developer-Dashboard-5.50.tar.gz`. The matching Docker image built successfully and reports version 5.50. A fresh blank Docker environment installed the tarball with `cpanm` (without `--notest`) and completed its full integration script. The release command was not run, so no package was uploaded.

## Current-cycle verification (2026-10-03)

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
