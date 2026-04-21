# Scorecard Actions

## Purpose

This file is the working checklist for `SCORECARD-GATEKEEPER`.

Nothing is done until:

1. every repository-side Scorecard failure has been fixed
2. every GitHub-side setting that can be changed from the available token has been changed
3. the live Scorecard report has been rerun
4. any remaining non-`10 / 10` checks have a documented external blocker with evidence

## Required Command

On this machine the live command is:

```bash
bash -ic "scorecard --repo=github.com/manif3station/developer-dashboard"
```

## Live Baseline

Initial live result observed on `2026-04-08`:

- aggregate `2.8 / 10`
- `Binary-Artifacts` `10 / 10`
- `Dangerous-Workflow` `10 / 10`
- `Vulnerabilities` `10 / 10`

Remaining non-`10 / 10` checks at that point:

- `Branch-Protection` `0 / 10`
- `CI-Tests` `?`
- `CII-Best-Practices` `0 / 10`
- `Code-Review` `0 / 10`
- `Contributors` `0 / 10`
- `Dependency-Update-Tool` `0 / 10`
- `Fuzzing` `0 / 10`
- `License` `0 / 10`
- `Maintained` `0 / 10`
- `Packaging` `?`
- `Pinned-Dependencies` `0 / 10`
- `SAST` `0 / 10`
- `Security-Policy` `0 / 10`
- `Signed-Releases` `?`
- `Token-Permissions` `0 / 10`

Current repo-side remediation work after the first push:

- `Dependency-Update-Tool` improved to `10 / 10`
- `Packaging` improved to `10 / 10`
- `SAST` improved to `10 / 10`
- `Security-Policy` improved to `10 / 10`
- `License` improved to `9 / 10`
- `Pinned-Dependencies` improved to `8 / 10`
- `Token-Permissions` stayed at `0 / 10` until top-level workflow writes were removed
- `Fuzzing` stayed at `0 / 10` until a Scorecard-supported fuzzing marker was added
- `Signed-Releases` stayed inconclusive until a real GitHub release exists with attached release assets that Scorecard can inspect
- the JS fuzz workflow also needs the Perl runtime because it shells into `dashboard encode` / `dashboard decode`; without `cpanm --installdeps --notest .`, the first property case dies on `Capture::Tiny` before fuzzing actually starts

## Task Breakdown

### Repository-side fixes

- [ ] add a tracked top-level `LICENSE`
- [ ] add a tracked top-level `SECURITY.md`
- [ ] add `.github/dependabot.yml`
- [ ] add a SAST workflow
- [ ] add a fuzzing signal that Scorecard can detect
- [ ] reduce workflow token permissions to the minimum required
- [ ] pin every GitHub Action by full commit SHA
- [ ] remove weak workflow bootstrap patterns where practical
- [ ] add a packaging workflow Scorecard can detect
- [ ] publish a real GitHub release with attached tarball, checksum, and detached signature assets
- [ ] add tests that lock these guardrails in place

### GitHub-side fixes that need API access or settings changes

- [ ] enable branch protection or a ruleset on `master`
- [ ] ensure pull-request review is required before merge
- [ ] create at least one PR-backed CI run that Scorecard can observe
- [ ] create reviewed PR history that Scorecard can observe
- [ ] create GitHub releases with attached artifacts and signatures

### Checks that may remain externally blocked

- [ ] `Maintained`
  because the repo was created on `2026-03-30`, which is inside the Scorecard
  90-day new-project window
- [ ] `Contributors`
  because Scorecard counts contributing organizations, not code quality
- [ ] `CII-Best-Practices`
  because it depends on the external OpenSSF Best Practices program state
- [ ] `Branch-Protection`
  if the available token still lacks `administration` permission
- [ ] `Code-Review`
  if no second reviewer or historical reviewed PR exists

## Evidence Notes

- GitHub API reported repo `created_at = 2026-03-30T22:39:05Z`
- GitHub branch-protection API returned:
  `Resource not accessible by personal access token`
- local repo inspection showed no tracked root `LICENSE`
- local repo inspection showed no tracked root `SECURITY.md`
- local repo inspection showed no `.github/dependabot.yml`
- local repo inspection showed no SAST workflow

## Operating Rule

If a check stays below `10 / 10`, rerun the loop:

1. diagnose the exact cause
2. fix what is actually fixable
3. test it
4. push it if Scorecard needs remote visibility
5. rerun Scorecard
6. update this file
