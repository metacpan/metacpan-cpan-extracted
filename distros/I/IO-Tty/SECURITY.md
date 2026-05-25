# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in IO::Tty, please report it
responsibly.

**Contact:** Todd Rinaldo <toddr@cpan.org>

**Preferred method:** Open a [GitHub Security Advisory](https://github.com/cpan-authors/IO-Tty/security/advisories/new) (private by default).

Alternatively, email the contact address above. Please include:

- A description of the vulnerability
- Steps to reproduce
- Affected versions (if known)

We aim to acknowledge reports within 48 hours and provide a fix or
mitigation within a reasonable timeframe.

## Scope

IO::Tty allocates pseudo-terminals and exposes terminal constants.
Security-relevant areas include:

- Pseudo-tty allocation and file descriptor handling
- Controlling terminal setup (`make_slave_controlling_terminal`)
- Terminal ioctl operations
