# Security

## Current Baseline

Developer Dashboard now applies these runtime protections in the active codebase:

- exact `127.0.0.1` with numeric host `127.0.0.1` is the only automatic local-admin trust path
- helper access requires a stored helper account
- helper usernames are restricted to safe filename characters
- helper passwords must be at least 8 characters long
- helper user files and helper session files are written with `0600` permissions
- helper sessions are bound to the originating remote address
- helper sessions expire automatically after 12 hours
- session cookies use `HttpOnly` and `SameSite=Strict`
- HTTP responses add `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, and `Cache-Control: no-store`

## Repository Hygiene

The active tree outside `OLD_CODE` is kept free of:

- company-specific product names listed in the repo rules
- embedded sensitive material
- literal password examples in user-facing documentation

`OLD_CODE` remains read-only reference material and is not modified or committed as part of the active runtime.

## Verification

Run these checks:

```bash
prove -lr t
```
