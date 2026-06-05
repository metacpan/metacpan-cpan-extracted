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

## 2. OWASP ASVS 5.0 Full Gate

**Tool:** manual audit against the repo security checks plus the shipped
runtime and release verification suite

**Execution model:**

This repository no longer treats OWASP as a narrow baseline-only spot check.
The gate is now a full OWASP ASVS 5.0.0 applicability review across every
chapter:

* V1 Architecture, Design and Threat Modeling
* V2 Authentication
* V3 Session Management
* V4 Access Control
* V5 Validation, Sanitization and Encoding
* V6 Stored Cryptography
* V7 Error Handling and Logging
* V8 Data Protection
* V9 Communication
* V10 Malicious Code
* V11 Business Logic
* V12 Files and Resources
* V13 API and Web Service
* V14 Configuration

**Level policy:**

* Every change must complete a full V1 through V14 applicability review.
  If one chapter is not relevant to the change, record that explicitly instead
  of silently skipping it.
* The repository security floor is ASVS Level 2 rigor for release-worthy
  runtime behavior, browser routes, auth/session handling, API behavior,
  packaging, and workflows.
* Treat Level 3 review as mandatory when the change touches high-trust
  boundaries such as authentication, session handling, credential storage,
  cryptographic handling, release signing, or externally callable API routes.

**Minimum repo-side evidence:**

Verify at least these controls and their nearby siblings whenever relevant:

* V2 and V3: non-public pages, helper login, session cookies, expiry,
  logout cleanup, and remote-address session binding
* V4: route authorization, outsider `401` behavior, saved Ajax API auth, and
  redirect-target sanitization
* V5, V12, and V13: strict input validation, route/file allowlists,
  static-file traversal blocking, safe Ajax route registration, and command or
  path injection resistance
* V6, V8, and V9: secret hashing, runtime permission tightening, secure
  cookie attributes, HTTPS redirect behavior, and TLS/SAN verification
* V7 and V14: explicit error behavior, visible logging, secure defaults,
  no-store responses, and security header coverage
* V10 and V11: no hidden background SQL generation, no silent business
  logic bypasses, and no unsafe trust in user-controlled workflow state

**Required local audit commands:**

```bash
rg -n "LWP::Simple|HTTP::Tiny|JSON::PP|capture_merged" bin lib t
rg -n "companies house|ewf|xmlgw|chips|tuxedo|chs|grover|cidev|pbs|password=|dsn=" bin lib README.md doc t
rg -n "X-Content-Type-Options|nosniff|Content-Security-Policy|X-Frame-Options|Referrer-Policy|SameSite=Strict|HttpOnly" lib doc SECURITY.md
rg -n "Transient token URLs are disabled|_transient_url_tokens_allowed|verify_user|login_response|_session_cookie" lib/Developer/Dashboard/Web lib/Developer/Dashboard/Auth.pm
rg -n "DBI->connect|\\$dbh->prepare\\(\\$sql\\)|table_info|column_info" bin/dashboard lib t
rg -n "_sanitize_redirect_target|Location|redirect" lib/Developer/Dashboard/Web lib t
rg -n "\\.\\./|rel2abs|dashboards/public|dashboards/ajax|skills/.+/dashboards" lib/Developer/Dashboard/Web lib t
rg -n "system\\(|exec\\(|open STDOUT|open STDERR|timeout_ms|alarm\\(" lib/Developer/Dashboard/ActionRunner.pm lib/Developer/Dashboard/CollectorRunner.pm lib/Developer/Dashboard/Web/Server.pm t
prove -lv t/08-web-update-coverage.t t/web_app_static_files.t t/17-web-server-ssl.t
```

**AI instructions:**

* Perform the required grep-based audit across `lib/`, `bin/`, `doc/`, and `t/`.
* Use the shipped tests as evidence for ASVS controls instead of treating the
  docs as self-proving.
* Fail immediately if raw SQL paths, missing auth gates, unsafe redirects,
  directory traversal, secret leaks, weak cookie/session handling, or unsafe
  command execution paths are introduced.

## 3. OWASP Top 10 2021 Cross-Check

**Tool:** manual threat mapping against the active change

**Execution:**

Map the change against the current OWASP Top 10 2021 categories and record any
applicable risk area:

* `A01` Broken Access Control
* `A02` Cryptographic Failures
* `A03` Injection
* `A04` Insecure Design
* `A05` Security Misconfiguration
* `A06` Vulnerable and Outdated Components
* `A07` Identification and Authentication Failures
* `A08` Software and Data Integrity Failures
* `A09` Security Logging and Monitoring Failures
* `A10` Server-Side Request Forgery

At minimum, every change that touches routes, auth, sessions, Ajax handlers,
static files, command execution, packaging, or workflows must explicitly
consider `A01`, `A03`, `A05`, `A07`, `A08`, and `A09`.

## 4. OpenSSF Best Practices

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
