# Problem 20: 100% Repository Test Coverage (in progress)

## Description

The canonical `script/coverage-gate` currently reports less than 100% for
statement, branch, condition, and subroutine coverage across production Perl
modules under `lib/`. No production module may be excluded and no unreachable
behavior may be hidden just to satisfy the metric.

## Expected outcome

The complete instrumented test suite passes, then the canonical coverage gate
exits 0 and reports `100.0 / 100.0 / 100.0 / 100.0` for the four metrics.

## Reproduction

Run from the repository root inside the development Docker service:

```sh
d2 docker compose --project-name problem20 \
  -f .developer-dashboard/config/docker/d2/compose.yml \
  -f .developer-dashboard/config/docker/d2/development.compose.yml \
  exec -T dev script/coverage-gate
```

The gate clears `cover_db`, runs `prove -lr t` with Devel::Cover, reports the
selected `lib/` tree, and enforces all four metrics. Do not run concurrent
coverage jobs.

## Initial result and root cause

The first full run after adding focused PAX tests executed 235 files and 21,036
tests, but exited before the coverage verdict because `t/15-release-metadata.t`
requires complete, specific POD sections in every new Perl test file. That
documentation gap was corrected. The next canonical run completed all 236 test
files and 21,098 tests successfully, but coverage correctly failed at 57.7%
statements, 54.3% branches, 33.9% conditions, and 73.3% subroutines. The major
remaining gaps are broad PAX runtime/compiler modules, especially
`StandaloneRuntime`, `CodeUnitCompiler`, `CLI`, `Gatekeeper`, and
`StandaloneAnalysis`.

## Progress

Focused Docker-run TDD suites currently bring these ten PAX modules to 100.0%
for all four metrics: `AppImage`, `Mode`, `InlineCache`, `DeoptEngine`, `OSR`,
`TypedIR`, `CPANMatrix`, `CoreSuite`, `Corpus`, and `StandaloneAnalysis`. This
does not close Problem 20; the whole-library gate remains the acceptance test.

The AppServer integration test now measures 100.0% statement, branch,
condition, and subroutine coverage in isolation. It exposed and fixed two
concrete defects: direct execution did not
preserve the requested working directory or `PAX_APP_IMAGE`, and a `local $?`
guard caused waited child exit codes to be reported as zero. Stop now verifies
the server acknowledgement. The OpenFile Java-root regression also confirmed
and fixed a warning when a candidate root is undefined.

Focused suite verification so far: `t/15-release-metadata.t`, `t/82-auth-coverage.t`,
`t/98-cli-openfile-coverage.t`, and `t/231` through `t/234` all pass in the
isolated Docker service. The auth test now drops a fixture child to an
unprivileged uid, reaching the real `get_user` unreadable-record error branch
even though the Docker test service runs as root. The complete run also logged
test warnings about package symbols used once; the relevant test references
were corrected. A fresh canonical run is required to verify the clean warning
state and updated global percentage.

The completion module's focused suite now reaches 100.0% in all four metrics.
It covers invalid arguments, both workspace-provider paths, Docker development
completion, dotted alias filtering, all built-in second-level command lists,
duplicate collector names, and collector/ticket providers. A separate fresh
focused run reports `Developer::Dashboard::Pax::AppServer` at 100.0% for all
four metrics. These module-level results do not change the failing whole-library
baseline above.

The expanded `t/235-pax-standalone-analysis-coverage.t` suite now passes 84
assertions and covers dependency classification/closure, source parsing,
module/path fallbacks, native-shape extraction, live-analysis outcomes, and
error paths. Its latest fresh focused report is 100.0% statements, branches,
conditions, and subroutines for `StandaloneAnalysis`. The lowercase package
test also exposed and fixed dependency parsing that previously rejected valid
lowercase Perl package names. This focused result does not change the overall
coverage gate; multiple PAX modules remain substantially uncovered.

## Next actions

1. Add focused TDD suites for the other production modules below 100%, starting
   with broad PAX runtime/compiler gaps. Iterate each module from focused
   reports without exclusions.
2. Repeat the complete suite and canonical coverage gate after the final fix.
3. Update the product docs and release metadata only after coverage is truly
   closed; then follow the repository release and Docker image build gates.

The new `t/236-pax-codeunitcompiler-source-contract.t` suite passes in Docker
with 78 assertions. It scans declared routines across the repository and adds
specific tests for compile routing, fallback and hybrid packaging, class and
module resolution, literal parsing, native loop shapes, and timeout behavior.
Its focused report now shows `CodeUnitCompiler` at 89.6% statements, 57.1%
branches, 57.5% conditions, and 100.0% subroutines. The timeout handler is now a
shared named callback, so its real timeout behavior is covered rather than
leaving an installed-but-never-called anonymous routine. The module still has
substantial uncovered decision paths; this focused report is progress only,
not a substitute for the full-library gate.

The latest full instrumented attempt passed all 238 files and 21,316 tests, but
the canonical coverage gate correctly failed its 100% thresholds. The measured
whole-library totals are 64.9% statements, 60.1% branches, 51.7% conditions,
and 75.3% subroutines. This is the current full-suite baseline, not acceptance.

That run first exposed two suite failures. The permission fixture now verifies
that a dropped-privilege file-open is actually denied before asserting
`get_user` behavior. The collector failure exposed the startup race described
in `t/153`: process-table matching can miss the interval before the forked
supervisor adopts its title even though the parent has written valid loop
state. `_adopt_existing_loop_if_running` now validates and consults that state
when pidfile and process-title lookup are unavailable. Red tests forced both a
process-discovery miss and invalid state PIDs; they failed before their fixes.
The full suite passed `t/153` and `t/168`, and focused Docker runs also pass
`t/15`, `t/82`, and `t/236`. A later focused assertion verifies a live but
mismatched state record is not adopted; it passes and covers the remaining
CollectorRunner condition path.

The new `t/237-pax-benchmark-coverage.t` suite passes 49 assertions in Docker
and brings `Developer::Dashboard::Pax::Benchmark` to 100.0% in every metric in
a fresh focused report. It tests real short Perl subprocesses for reference
exit statuses and stubs only the compiler pipeline used by the native timing
combiner. A narrow optional status-file argument on `_current_rss_kb` allows
the production `/proc/self/status` parser to be tested for missing files,
missing VmRSS fields, explicit values, and its default path without changing
the no-argument runtime behavior.

The new `t/239-pax-benchmark-matrix-coverage.t` suite passes 15 assertions and
reports `BenchmarkMatrix` at 100.0% statements, branches, conditions, and
subroutines in a fresh focused database. It covers empty and populated class
lists, fixture normalization, missing schema fields, constructor values, and
manifest read errors. `t/240-pax-compatibility-coverage.t` passes 19 assertions
and reports all four metrics at 100.0%, including every named feature policy,
unknown features, all compatibility levels, and the non-barrier policy path.

The new `t/241-pax-type-annotation-extractor-coverage.t` passes 31 assertions.
Its latest focused report is 100.0% statements, branches, and subroutines and
94.7% conditions. Review of the missing condition identified and removed a
redundant check: `split` always defines its first field, including as an empty
string, so only the type field can be absent for non-empty input. This is a
small module-focused result; the complete repository gate has not been rerun
since these additions and remains the only acceptance measure.

The canonical run after adding tests 239-241 ran 243 test files and 21,514
assertions, but `t/121-actionrunner-coverage-2.t` failed one timing-sensitive
assertion before the gate could produce its coverage report. The failure was
not reproduced by an isolated Docker run or an isolated instrumented Docker
run. The fixture gave an instrumented child interpreter only a 1.5-second
timeout to install its SIGTERM handler; under full-suite load, SIGTERM could
arrive before that handler was ready. The timeout window is now five seconds,
and two consecutive isolated instrumented Docker runs pass all 11 assertions.
The full canonical gate must be rerun to establish the current suite result and
repository-wide coverage; no new global percentage is claimed yet.

The next canonical run passed all 243 test files and 21,514 assertions except
for the HUP timing assertion in `t/09-runtime-manager.t`. It reproduced a real
race: `_follow_log_file` created/opened the log and applied file permissions
before installing its TERM/INT/HUP handlers, so a HUP during that setup killed
the process with the default action. A deterministic fork-and-pipe regression
now sends HUP while `secure_file_permissions` is held in setup; it failed before
the implementation change. `_follow_log_file` now installs its local handlers
before filesystem setup. The focused Docker run of `t/09-runtime-manager.t`
passes all 456 assertions after the fix. A fresh canonical full run is needed
to confirm the suite and produce the current repository-wide coverage report.

That canonical run completed: all 243 test files and 21,519 assertions passed,
but the four-metric gate remains short at 65.2% statements, 60.4% branches,
52.0% conditions, and 75.6% subroutines. The most severe uncovered production
areas are PAX `CLI`, `CLI::Progress`, `StandaloneRuntime`, `Gatekeeper`, and
`StandaloneDispatch`; these remain in scope.

Added `t/242-pax-cli-progress-coverage.t` as a focused suite for PAX progress
construction, validation, callback updates, rendering, colors, redraw, and
finish behavior. It passes 40 assertions in Docker and a fresh focused
Devel::Cover report shows `Developer::Dashboard::Pax::CLI::Progress` at 100.0%
for statements, branches, conditions, and subroutines. The constructor's task
label fallback was expressed in terms of the three reachable false-label cases
(undefined, empty, and `0`) rather than an OR against an ID already guaranteed
to be truthy. This preserves output while making the condition model testable.

Added `t/243-pax-cli-entrypoint-coverage.t` to exercise PAX CLI help/error
dispatch, interpreter mode, the legacy pipeline wrappers, and standalone image
commands using deterministic local collaborators and a temporary executable.
It passes 25 assertions in Docker. A fresh focused report for
`Developer::Dashboard::Pax::CLI` is now 37.3% statements, 24.2% branches,
13.2% conditions, and 64.2% subroutines, up from 9.4%, 0.4%, 0.0%, and 40.7%
in the last whole-suite baseline. The rest of this large facade remains
uncovered; this is an intermediate result, not an acceptance gate.

## Latest canonical gate: 2026-09-29

The full Docker coverage gate completed all 265 test files and 22,780 tests
successfully in 3,001 seconds, then failed the required 100% coverage check.
Repository totals are 71.7% statements, 66.0% branches, 56.5% conditions, and
81.2% subroutines. The largest remaining module gaps include
`Pax::StandaloneRuntime` (13.0 / 14.1 / 12.9 / 16.4),
`Pax::StandaloneImage` (77.0 / 50.1 / 40.0 / 88.7),
`Pax::CodeUnitCompiler` (89.6 / 57.1 / 57.5 / 100.0), and `Pax::CLI`
(91.3 / 82.3 / 65.3 / 100.0). Smaller remaining gaps include production
modules outside PAX, so the PAX modules alone are not the only work remaining.

This is the latest measured baseline, not a passing coverage result. It blocks
the ordered release steps (`dzil clean`, version bump, `dzil build`, Docker
image rebuild, and commit). Optional checks also skipped because the container
lacks `cpan-audit`, `Module::CPANTS::Analyse`, `Test::Pod`, and Chromium; these
must be handled or explicitly resolved before claiming all delivery gates pass.
