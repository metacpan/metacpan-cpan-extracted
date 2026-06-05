# Security

## Current Baseline

Developer Dashboard now applies these runtime protections in the active codebase:

- exact `127.0.0.1` with numeric host `127.0.0.1` is the only automatic local-admin trust path
- home-runtime directories under `~/.developer-dashboard` are created and tightened to `0700`
- home-runtime files under `~/.developer-dashboard` are written and tightened to `0600`, while owner-executable scripts stay at `0700`
- helper access requires a stored helper account
- helper usernames are restricted to safe filename characters
- helper passwords must be at least 8 characters long
- helper user files and helper session files are written with `0600` permissions
- helper sessions are bound to the originating remote address
- helper sessions expire automatically after 12 hours
- session cookies use `HttpOnly` and `SameSite=Strict`
- HTTP responses add `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, and `Cache-Control: no-store`

## OWASP Gate

Developer Dashboard now treats OWASP as a full security gate, not a
baseline-only checklist.

The shipped OWASP compliance SOW now records the chapter-by-chapter evidence
matrix and the current claim boundary. Use that record when deciding whether a
public statement should stay at `OWASP-aligned` / `OWASP-gated` or can safely
move to a stronger blanket compliance claim.

The repository security review is aligned to OWASP ASVS 5.0.0 across the
full chapter set:

- V1 Architecture, Design and Threat Modeling
- V2 Authentication
- V3 Session Management
- V4 Access Control
- V5 Validation, Sanitization and Encoding
- V6 Stored Cryptography
- V7 Error Handling and Logging
- V8 Data Protection
- V9 Communication
- V10 Malicious Code
- V11 Business Logic
- V12 Files and Resources
- V13 API and Web Service
- V14 Configuration

Every change must complete a V1 through V14 applicability review. If one
chapter is not relevant to the change, that should be stated explicitly rather
than skipped implicitly.

The practical repo policy is:

- ASVS Level 2 rigor is the default floor for release-worthy runtime, browser,
  auth, API, packaging, and workflow changes
- Level 3 review is mandatory when a change touches higher-trust boundaries
  such as authentication, session handling, cryptographic handling, release
  signing, or externally callable API routes

The same gate is also cross-mapped to the OWASP Top 10 2021 categories:

- `A01` Broken Access Control
- `A02` Cryptographic Failures
- `A03` Injection
- `A04` Insecure Design
- `A05` Security Misconfiguration
- `A06` Vulnerable and Outdated Components
- `A07` Identification and Authentication Failures
- `A08` Software and Data Integrity Failures
- `A09` Security Logging and Monitoring Failures
- `A10` Server-Side Request Forgery

For this repository, route, auth, session, Ajax, static-file, command
execution, packaging, and workflow changes must always be checked against at
least `A01`, `A03`, `A05`, `A07`, `A08`, and `A09`.

The current shipped status record does not yet authorize an unqualified public
`OWASP compliant` claim. The stronger claim stays blocked until the matrix,
repo-side evidence, and the remaining governance and release gates are all
closed together.

## Repository Hygiene

The active tree outside the read-only older reference tree is kept free of:

- company-specific product names listed in the repo rules
- embedded sensitive material
- literal password examples in user-facing documentation

That older reference tree remains read-only reference material and is not modified or committed as part of the active runtime.

## Verification

Run these checks:

```bash
dashboard doctor
dashboard doctor --fix
prove -lr t
```

For security-sensitive changes, the local verification loop must also include
the OWASP-driven repo audit commands from `SECURITY_CHECKS.md`, including the
auth/session, redirect, traversal, command-execution, header, and raw-SQL grep
checks plus the focused web and SSL regressions.

Recent repo audit summary:

- no obvious new raw SQL execution path was found
- no obvious missing auth gate was found on the main protected web surfaces
- no obvious unsafe open redirect was found outside the existing sanitized
  local redirect flow
- no obvious directory traversal hole was found in the current static-file
  and saved-file route surfaces from the grep review
- the current gap was process, not a discovered exploit: the formal OWASP gate
  was narrower than the repo’s actual security posture, so the gate itself has
  now been widened

## Private Reporting

The published root security policy lives in [`SECURITY.md`](../SECURITY.md) and
currently directs private reports to:

- `security@manif3station.local`
- `https://github.com/manif3station/developer-dashboard/security/advisories`

That root file now also documents the coordinated-disclosure timing contract:

- acknowledge vulnerability reports within 3 business days
- send a status update within 14 days
- aim for a 90-day disclosure window unless impact or remediation needs require
  a different schedule

The repository also treats the live OpenSSF Scorecard report as a security and
release gate. Run:

```bash
bash -ic "scorecard --repo=github.com/manif3station/developer-dashboard"
```

before closing a task that changes repository policy, workflows, releases, or
security posture.
