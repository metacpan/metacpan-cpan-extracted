# Security Policy

## Reporting A Vulnerability

Report security issues privately to:

- `security@manif3station.local`
- `https://github.com/manif3station/developer-dashboard/security/advisories`

Include:

- the affected version
- a short reproduction
- the expected impact
- any suggested mitigation

Do not open a public issue for an unpatched security problem.

## Coordinated Disclosure Expectations

We aim to acknowledge a vulnerability report within 3 business days, provide a
status update within 14 days, and work toward a coordinated disclosure window
of 90 days unless the impact or the fix timeline requires a different schedule.

If a report is not actually a vulnerability, or if the impact turns out to be
different after triage, we will still reply with that outcome so the reporter
is not left guessing about the disclosure status.

## Supported Releases

Security fixes are applied to the latest active release line in this repository.

## Additional Context

The runtime-facing security baseline and verification notes remain documented in
[`doc/security.md`](doc/security.md), including the `dashboard doctor` command
used to audit and repair owner-only runtime permissions.
