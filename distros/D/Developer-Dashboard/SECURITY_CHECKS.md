## SECURITY_CHECKS.md

# Pre-Build Security Validation Protocol

**Role:** AI Security Auditor
**Objective:** Execute 3-tier security validation before running `dzil build`.
**Mandate:** If any critical check fails, the build must be aborted.

## 1. OpenSSF Scorecard

**Tool:** `scorecard` CLI

**Execution:**

```bash
bash -ic "scorecard --repo=github.com/manif3station/developer-dashboard"
```

**AI instructions:**

* Record every failing or unknown check after the local repo gates, commit, and push are complete.
* Fail the delivery loop immediately for repo-side security regressions such as `Dangerous-Workflow`, `Pinned-Dependencies`, or other newly introduced workflow and dependency issues.
* Treat `Branch-Protection`, `Code-Review`, `CI-Tests`, `Signed-Releases`, and `CII-Best-Practices` as real Scorecard checks, but distinguish checkout-fixable items from GitHub settings, merge history, release history, or external badge enrollment.
* `Signed-Releases` in this repository is backed by the tag-triggered GitHub workflow at `.github/workflows/release-github.yml`; push a `vX.XX` tag when the signed GitHub release needs to exist for Scorecard to observe it.

## 2. OWASP ASVS Level 1

**Tool:** manual audit against the repo security checks

**Execution:**

Verify the following minimum controls are implemented in the code:

* `V2.1.1` auth: all non-public pages must require authentication.
* `V5.1.3` input validation: request data must be validated against strict allowlists.
* `V13.2.1` API responses: security headers such as `X-Content-Type-Options: nosniff` must be present.

**AI instructions:**

* Perform the required grep-based audit across `lib/`, `bin/`, `doc/`, and `t/`.
* Fail immediately if raw SQL paths, missing auth gates, unsafe redirects, directory traversal, or secret leaks are introduced.

## 3. OpenSSF Best Practices

**Tool:** OpenSSF Best Practices badge program

**Execution:**

The Scorecard `CII-Best-Practices` check uses the badge state published by the OpenSSF Best Practices service for the repository URL.

**AI instructions:**

* Ensure `SECURITY.md` exists and contains a clear vulnerability disclosure policy.
* Keep project docs consistent with the badge requirements, but do not pretend the badge is satisfied until the repository is actually enrolled at `bestpractices.dev`.
* If the project is not yet registered with the OpenSSF Best Practices program, record that as an external follow-up instead of claiming the repo-side work is complete.

## Final Build Trigger

Proceed to `dzil build` only after the security gates above and the repository test and coverage gates are green.

## Integration Tips

* Automation: the AI agent can run these checks sequentially.
* Dist::Zilla integration: if checkout automation is needed later, wire a dedicated security script through `[Run::BeforeBuild]` in `dist.ini`.
* Badge program: register the project at `https://www.bestpractices.dev/` when you want Scorecard to move the `CII-Best-Practices` check above zero.
