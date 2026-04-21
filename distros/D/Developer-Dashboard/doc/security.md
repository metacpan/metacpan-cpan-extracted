# Security

## Current Baseline

Developer Dashboard now applies these runtime protections in the active codebase:

- exact `127.0.0.1` with numeric host `127.0.0.1` is the only automatic local-admin trust path
- home-runtime directories under `~/.developer-dashboard` are created and tightened to `0700`
- home-runtime files under `~/.developer-dashboard` are written and tightened to `0600`, while owner-executable scripts stay at `0700`
- project-local `./.developer-dashboard/config/api-dashboard` is tightened to `0700` when the API workspace uses it, and saved Postman collection JSON files there are tightened to `0600`
- project-local `./.developer-dashboard/config/sql-dashboard` and `./.developer-dashboard/config/sql-dashboard/collections` are tightened to `0700` when the SQL workspace uses them, and saved SQL connection profile plus SQL collection files there are tightened to `0600`
- helper access requires a stored helper account
- helper usernames are restricted to safe filename characters
- helper passwords must be at least 8 characters long
- helper user files and helper session files are written with `0600` permissions
- when a user explicitly enables `sql-dashboard` password saving, the password is kept in plaintext inside that owner-only profile JSON file rather than in a share URL
- when a user saves `api-dashboard` requests with request-level auth, those auth values are kept in plaintext inside the owner-only Postman collection JSON file, so placeholder variables remain the safer choice when the operator does not want a live secret written to disk
- `sql-dashboard` share URLs carry only the portable `dsn|user` connection id and current SQL text, so another machine never receives a password through the URL; it must already have a matching saved profile locally or the user must add the password there
- helper sessions are bound to the originating remote address
- helper sessions expire automatically after 12 hours
- session cookies use `HttpOnly` and `SameSite=Strict`
- HTTP responses add `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, and `Cache-Control: no-store`

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
