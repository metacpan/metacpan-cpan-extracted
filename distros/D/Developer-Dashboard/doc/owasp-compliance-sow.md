# OWASP Compliance SOW

## Purpose

This document is the shipped scope-of-work and evidence record for the
repository's OWASP security claim boundary.

It exists so Developer Dashboard does not drift into a vague marketing claim
such as `OWASP compliant` without a concrete requirement matrix, evidence map,
status record, and closure criteria.

## Safe Public Claim

Today the safe public wording is:

- `OWASP-aligned`
- `OWASP-gated`
- `uses OWASP ASVS 5.0 and OWASP Top 10 2021 as active security verification gates`

Do not claim blanket `OWASP compliant` yet.

That stronger claim is reserved for the state where:

1. the ASVS matrix below is fully reviewed and kept current
2. the repo-side evidence remains green
3. the repository governance and release gates needed to support the claim are closed
4. the remaining GitHub-side and release-side blockers are no longer open

## Scope

The active scope is:

- OWASP ASVS 5.0.0 chapters `V1` through `V14`
- OWASP Top 10 2021 risks `A01` through `A10`
- repository runtime behavior
- browser routes and saved Ajax routes
- helper authentication and session handling
- packaging and installed-runtime verification
- release and workflow security gates

The target rigor is:

- ASVS Level 2 as the default floor
- Level 3 review for higher-trust work such as auth, sessions,
  cryptographic handling, release signing, and externally callable API routes

## ASVS Matrix

### V1 Architecture, Design and Threat Modeling

- Status: repo-side reviewed
- Evidence:
  - `SECURITY_CHECKS.md` defines the full-gate review requirement
  - `doc/security.md` defines the active security baseline and review model
  - `t/47-owasp-gate.t` enforces the chapter span and evidence wording

### V2 Authentication

- Status: repo-side reviewed
- Evidence:
  - `lib/Developer/Dashboard/Auth.pm`
  - `lib/Developer/Dashboard/Web/App.pm`
  - helper credential verification through `verify_user`
  - auth/session grep checks in `SECURITY_CHECKS.md`
  - focused route and auth regressions in `t/08-web-update-coverage.t`

### V3 Session Management

- Status: repo-side reviewed
- Evidence:
  - helper sessions bound to remote address
  - session expiry handling
  - `HttpOnly` and `SameSite=Strict` cookie attributes
  - auth/session grep checks in `SECURITY_CHECKS.md`
  - focused web regressions in `t/08-web-update-coverage.t`

### V4 Access Control

- Status: repo-side reviewed
- Evidence:
  - protected route behavior in `lib/Developer/Dashboard/Web/App.pm`
  - outsider `401` and `403` behavior
  - saved Ajax API route allowlists
  - redirect-target sanitization checks
  - focused route regressions in `t/08-web-update-coverage.t`

### V5 Validation, Sanitization and Encoding

- Status: repo-side reviewed
- Evidence:
  - redirect target sanitization
  - route and static-file allowlist checks
  - path and traversal grep checks in `SECURITY_CHECKS.md`
  - traversal regressions in `t/web_app_static_files.t`

### V6 Stored Cryptography

- Status: repo-side reviewed
- Evidence:
  - machine secret hashing for saved Ajax API auth
  - release-signing and signed-release expectations in the release gate
  - auth and release code paths covered by shipped tests and release workflows

### V7 Error Handling and Logging

- Status: repo-side reviewed
- Evidence:
  - repo rules forbid silent failures and suppressed errors
  - explicit error-path expectations in the security and release gates
  - tests treat warnings as failures across the suite

### V8 Data Protection

- Status: repo-side reviewed
- Evidence:
  - home-runtime directory and file permission tightening
  - helper-user and helper-session file permissions
  - no-store and cookie protections documented in `doc/security.md`
  - runtime permission audit through `dashboard doctor`

### V9 Communication

- Status: repo-side reviewed
- Evidence:
  - HTTPS redirect and TLS verification expectations
  - `t/17-web-server-ssl.t`
  - security-header coverage and secure transport wording in the shipped docs

### V10 Malicious Code

- Status: repo-side reviewed
- Evidence:
  - release and workflow checks through Scorecard and workflow hardening
  - fuzzing and SAST signals required by the repo security gates
  - forbidden-library checks in `SECURITY_CHECKS.md`

### V11 Business Logic

- Status: repo-side reviewed
- Evidence:
  - no hidden background SQL generation
  - explicit user-authored SQL rule for SQL-style tools
  - no silent bypass rule across runtime and route handling

### V12 Files and Resources

- Status: repo-side reviewed
- Evidence:
  - static-file traversal blocking
  - saved-file and public-file route checks
  - `t/web_app_static_files.t`
  - traversal grep checks in `SECURITY_CHECKS.md`

### V13 API and Web Service

- Status: repo-side reviewed
- Evidence:
  - saved Ajax API machine-auth routing
  - helper-session compatibility on approved API routes
  - auth header pass-through and enforcement
  - route and auth tests in `t/08-web-update-coverage.t`

### V14 Configuration

- Status: repo-side reviewed
- Evidence:
  - secure defaults and security headers
  - runtime permission repair path
  - release and packaging verification docs
  - `t/47-owasp-gate.t`

## OWASP Top 10 2021 Mapping

- `A01 Broken Access Control`
  - covered by route auth, outsider denial, and API allowlists
- `A02 Cryptographic Failures`
  - covered by hashed stored secrets, cookie controls, and signed-release expectations
- `A03 Injection`
  - covered by no hidden SQL generation, raw-SQL grep checks, and route/path validation
- `A04 Insecure Design`
  - covered by the full-gate review model and closure criteria in this SOW
- `A05 Security Misconfiguration`
  - covered by security headers, runtime permissions, and release/workflow checks
- `A06 Vulnerable and Outdated Components`
  - covered by dependency-update tooling, packaging checks, and release verification
- `A07 Identification and Authentication Failures`
  - covered by helper auth, session handling, and API auth verification
- `A08 Software and Data Integrity Failures`
  - covered by signed-release expectations, workflow hardening, and packaging gates
- `A09 Security Logging and Monitoring Failures`
  - covered by explicit-error and no-silent-failure rules
- `A10 Server-Side Request Forgery`
  - reviewed in route and HTTP-entrypoint changes even where not currently a primary runtime feature

## Repo-Side Evidence Set

The minimum repo-side proof set is:

- `SECURITY_CHECKS.md` audit commands
- `doc/security.md` baseline and gate statement
- `doc/update-and-release.md` release-gate wording
- `t/47-owasp-gate.t`
- `t/08-web-update-coverage.t`
- `t/web_app_static_files.t`
- `t/17-web-server-ssl.t`
- `prove -lr t`
- the explicit `Devel::Cover` gate
- the blank-environment and tarball-install verification gates

## Closure Criteria For Blanket Compliance Claim

Do not switch public wording from `OWASP-aligned` or `OWASP-gated` to blanket
`OWASP compliant` until all of these are true:

1. this SOW is kept current with a chapter-by-chapter evidence record
2. the repo-side OWASP evidence tests are green
3. the local audit commands in `SECURITY_CHECKS.md` are green
4. release and packaging verification are green
5. the live repository governance gate no longer shows actionable unresolved blockers
6. any GitHub-side settings needed for branch protection, review enforcement,
   signed releases, or equivalent governance proof are actually in place

## Status As Of 2026-06-05

- repo-side OWASP gate wording exists and is tested
- repo-side OWASP evidence matrix now exists and is shipped
- the stronger blanket public claim is still not closed

Current blockers outside the repo-only document-and-test gap include the live
governance and release signals that still need full closure, including:

- `Branch-Protection`
- `Code-Review`
- `CII-Best-Practices`
- `CI-Tests`
- `Signed-Releases`
- `Contributors`
- `Maintained`

That means the repo is now materially better aligned and documented, but the
honest public statement is still `OWASP-aligned` or `OWASP-gated`, not an
unqualified blanket `OWASP compliant`.
