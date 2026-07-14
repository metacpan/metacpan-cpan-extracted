# Security Policy

## Supported Versions

Until version 1.0.0, only the last two minor versions will receive security
updates.

| Version    | Supported          |
| ---------- | ------------------ |
| v3.0.x     | :white_check_mark: |
| v2.0.x     | :white_check_mark: |
| <= v1.0.x  | :x:                |

## Reporting a Vulnerability

If you have any issue regarding security, please disclose the information
responsibly by sending a report to
https://github.com/sanko/digest-xxhash/security/advisories/new and **not** at
the public issue tracker or via email.

## Vulnerability Disclosure Policy

Maintaining the security of our open-source software is paramount. This policy
outlines a responsible approach to addressing vulnerabilities, balancing
transparency with the need to protect users.

- Security vulnerabilities identified in the project will be assigned a unique
  identifier and (if applicable) a Common Vulnerabilities and Exposures (CVE)
  identifier.

- The project's Maintainers will be responsible for addressing the vulnerability
  through a standard pull request, backporting the fix to the immediate prior
  minor release branch, and including the fix in the next stable release.

- Release notes for the patched version will include the assigned identifier
  and, if applicable, the CVE identifier for the vulnerability.

- A grace period will be provided for Maintainers to update the vulnerable minor
  version and remove vulnerable releases from PAUSE (nothing can be done about
  backpan).

  This period will be one month for non-critical vulnerabilities and three
  months for critical vulnerabilities.

- After the grace period has elapsed, the vulnerability details will be made
  public.
