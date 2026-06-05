# Internal Operating Checklist

Use this checklist at the start, during, and end of every meaningful change in
Developer Dashboard.

It is a compact execution guide distilled from:

- `ELLEN.md`
- `AGENTS.override.md`
- `agents.md`
- `SECURITY.md`
- `SECURITY_CHECKS.md`
- `README.md`
- `SOFTWARE_SPEC.md`
- `doc/testing.md`
- `doc/integration-test-plan.md`
- `doc/windows-testing.md`
- `doc/update-and-release.md`
- `MISTAKE.md`
- `FIXED_BUGS.md`

If any detail here appears to conflict with those files, the higher-priority
source files win.

## 1. Operating Mindset

1. Follow `ELLEN.md` first.
2. Do not stop at symptoms, guesses, wrappers, or partial evidence.
3. Verify suspicious output directly.
4. Use the full system before claiming a blocker.
5. Treat a fix as incomplete until the result is verified and the lesson is captured.
6. Do not wait for a `yes` when the next action is already justified by the task, the current findings, or the repo rules.

## 2. Before Touching Code

1. Read the governing docs and the task-specific docs fully before making assumptions.
2. Confirm the work stays out of `OLD_CODE`.
3. Remove any legacy/company-specific logic from the solution space:
   `Companies House`, `EWF`, `XMLGW`, `CHIPS`, `Tuxedo`, `CHS`, `Grover`,
   `CIDEV`, `PBS`, credentials, and sensitive-data flows do not belong in core.
4. Identify the runtime surfaces affected:
   CLI, browser, collectors, auth, routing, packaging, Windows, Docker,
   layering, prompt, or release workflow.
5. Review related entries in `MISTAKE.md` and `FIXED_BUGS.md` before implementing.

## 3. Design And Implementation Rules

1. Follow TDD.
2. Add or update tests under `t/` first where practical.
3. Keep `dashboard` thin and lazy.
4. Do not bloat `bin/dashboard` with reusable behavior or heavy built-in bodies.
5. Treat `DD-OOP-LAYERS` as a cross-runtime contract, not a convenience feature.
6. Never suppress errors.
7. Treat warnings as errors.
8. Do not hide broken behavior behind fallback logic unless the fallback is explicit, documented, and tested.
9. Make logs visible and explicit.
10. Use:
   - `JSON::XS`
   - `LWP::UserAgent`
   - `Capture::Tiny`
11. Never use:
   - `LWP::Simple`
   - `HTTP::Tiny`
   - `JSON::PP`
   - `capture_merged`
12. Use the required `Capture::Tiny` pattern:

```perl
use Capture::Tiny qw(capture);

my ($stdout, $stderr, $exit) = capture {
   system($command);
};
```

13. Every function must document:
   - what it does
   - input arguments
   - expected output

## 4. Delivery Model

The project uses all of these at once:

- `TDD` for implementation discipline
- behavior-driven documentation and spec language for user-visible contracts
- acceptance-driven verification for installed-runtime and cross-platform proof

Use that model like this:

1. define the expected behavior from docs, tests, or a bug report
2. write or update the failing test first where practical
3. implement the smallest coherent fix
4. rerun the fast suite
5. run the environment-specific acceptance gates required by the change
6. update docs and release metadata in the same change

## 5. Security Guardrails

1. Perform a security audit on every change.
2. Run the repository security grep checks before build and before push.
3. Treat these as stop-and-fix defects:
   - raw SQL execution path
   - missing auth gate
   - missing security header
   - unsafe redirect
   - directory traversal
   - secret leak
   - forbidden library usage
4. For SQL-style tools, raw SQL must stay explicit and user-authored.
5. Do not add hidden query generation or hidden concatenation.

## 6. Documentation Rules

1. Update `doc/` for behavior changes.
2. Update `README.md`.
3. Update POD in `lib/Developer/Dashboard.pm`.
4. Keep `README.md` and the `Developer::Dashboard.pm` POD in sync.
5. Update `Changes`.
6. Update `FIXED_BUGS.md`.
7. Keep POD specific, complete, and file-accurate.
8. Never mention Markdown files inside POD in `.pm`, `.pl`, or `.t` files.
9. Regenerate the checkout manual with:

```bash
script/sync-readme-from-pod
```

## 7. Test Environment Matrix

Use the smallest set that proves the change, then add broader gates when the
surface area requires them.

### Unit And Regression Suite

Run:

```bash
prove -lr t
```

This is the default correctness gate for CLI, runtime, auth, routing,
collectors, packaging metadata, and regression coverage.

Use this for:

- almost every code change
- bug fixes
- behavior changes
- refactors

### Coverage Gate

Run the explicit `Devel::Cover` gate and keep `lib/` at 100% statement and
100% subroutine coverage.

Use this for:

- all changes under `lib/Developer/Dashboard`
- any new helper, branch, or module logic that affects runtime behavior

### Browser Verification

For browser-facing work:

- run browser-sensitive tests
- verify behavior in a real browser or the headless Chromium path
- confirm usability, not just code-path success

Fast path:

```bash
integration/browser/run-bookmark-browser-smoke.pl
```

Use this for:

- bookmark rendering
- Ajax timing and binding
- saved pages
- editor flows
- visual regressions
- practical usability checks

### Blank-Environment Installed Product Gate

Use:

```bash
integration/blank-env/run-host-integration.sh
```

This proves the built tarball works as an installed product in a blank
environment rather than only from the source checkout.

Use this for:

- packaging changes
- runtime bootstrap changes
- `@INC` or `PERL5LIB` changes
- helper staging changes
- dependency changes
- any fix that might accidentally depend on the source checkout

### Blank Container Tarball Install Gate

Build the tarball and verify it installs in a blank Docker environment with
`cpanm` and tests enabled where the repo gate requires that path.

Use this for:

- release work
- dependency changes
- install/bootstrap changes
- shell or path changes
- fixes for packaged-runtime breakage

### Windows Gates

For Windows-targeted changes:

1. forced-Windows unit tests
2. Strawberry Perl smoke
3. QEMU/Dockur full-system gate for release-grade claims

See `doc/windows-testing.md`.

Use this for:

- PowerShell dispatch logic
- path handling
- process launching
- shell quoting
- Windows install/runtime support

### Optional macOS Manual Gate

Use only when the work touches Homebrew/bootstrap/Brewfile-specific behavior.

Use this for:

- Homebrew install/bootstrap logic
- Brewfile behavior
- macOS-specific path issues

## 8. Recommended Verification Order

Use this order unless the task clearly requires a narrower or broader path:

1. run the focused failing tests first
2. run `prove -lr t`
3. run the explicit `Devel::Cover` gate
4. run browser-sensitive tests and real browser checks for browser work
5. run blank-environment and packaged-install gates for packaging, bootstrap, or release work
6. run Windows-specific gates for Windows-facing work
7. build the tarball and complete release hygiene checks
8. commit and push only after local gates are green
9. rerun live Scorecard when the task is meant to be fully closed

## 9. Browser, Docker, And Runtime Checks

1. For frontend work, verify in a browser, not only with tests.
2. For runtime or packaging work, check relevant Docker/container errors.
3. Do not inspect unrelated containers.
4. If a relevant runtime container shows a real error, treat it as part of the work.
5. For layered behavior, verify from the actual runtime path, not only from a source-tree shortcut.

## 10. Release And Packaging Gates

Before claiming a change is done:

1. all tests pass
2. coverage is 100%
3. docs are updated
4. `Changes` and `FIXED_BUGS.md` are updated
5. version metadata is aligned when version changes are involved
6. tarball is rebuilt
7. only the latest tarball remains in the working directory
8. `cover_db` does not leak into the tarball
9. kwalitee is clean
10. blank-environment install verification passes

## 11. Scorecard Gate

`SCORECARD-GATEKEEPER` is a hard gate in this repository.

Run only after local repo gates, commit, and push:

```bash
bash -ic "scorecard --repo=github.com/manif3station/developer-dashboard"
```

Rules:

1. Record every failing or unknown check.
2. Turn live failures into an explicit task list.
3. Fix repository-side causes with TDD and verification.
4. Push GitHub-side settings changes when needed for remote visibility.
5. Rerun Scorecard.
6. Repeat until every actionable check is `10 / 10`.
7. If a check cannot reach `10 / 10` because of platform/history/contributor constraints, document the blocker with evidence.

Do not declare completion while repo-fixable Scorecard failures remain.

## 12. New Incoming Work Process

When new work arrives, handle it in this order:

1. Read all relevant instructions and docs fully.
2. Classify the work:
   - bug fix
   - behavior change
   - security change
   - runtime/collector change
   - browser change
   - packaging/release change
   - Windows/bootstrap change
3. Identify affected runtime surfaces and test environments.
4. Check `MISTAKE.md` for known failure patterns in that area.
5. Write or update tests first.
6. Implement the smallest coherent fix.
7. Verify locally.
8. Update docs and metadata.
9. Run the required integration/platform gates.
10. Commit only after the change is actually proven.
11. Push only after verification is complete.

## 13. Project Management Cadence

Treat incoming work as a managed delivery loop, not ad hoc patching.

1. intake:
   classify the work and find the governing docs, tests, and past mistakes
2. scope:
   identify affected surfaces, risks, and required environments
3. proof:
   define the expected result in tests and acceptance terms
4. implementation:
   make the smallest coherent change that satisfies the proof
5. verification:
   run local, browser, integration, packaging, and platform gates required by the scope
6. documentation:
   update user docs, POD, `Changes`, and bug history in the same pass
7. release-readiness:
   build, install, verify, push, then rerun remote gates such as Scorecard
8. learning:
   record mistakes and fix patterns so the same failure mode is easier to catch next time

## 14. Recurring Mistakes To Screen For

Before and after implementation, explicitly check for these repeat failure
patterns:

1. claiming success before the runtime is truly ready
2. reading only part of the instructions or only part of the relevant docs
3. flattening layered behavior into a simpler project-vs-home shortcut
4. allowing docs, POD, or release notes to drift from real behavior
5. relying on source-checkout paths that fail after tarball install
6. weakening auth or exposing browser/runtime data incorrectly
7. trusting test output without checking real browser or SSL/runtime behavior where required
8. under-testing Windows, blank-environment installs, or packaged-runtime paths
9. treating Scorecard, coverage, or packaging as optional cleanup instead of delivery gates
10. stopping at `I can do X next` when X is already the correct next action

## 15. Definition Of Done

A task is done only when:

1. the implementation is correct
2. the required tests prove it
3. the coverage gate still passes
4. the docs and POD match reality
5. the packaging and installability gates are satisfied where required
6. the security and repo checks are clean
7. the relevant platform-specific verification is complete
8. the known mistake patterns for that area were screened and not repeated
9. Scorecard is clean for repo-fixable checks when the task is meant to be fully closed
10. ending with optional "if you want" prompts instead of executing the next justified action already implied by the task or repo rules
