# Security

This is the security policy for Ekorn-Pipeline, the Perl distribution of
Ekorn::Pipeline and its modules.

## Reporting a vulnerability

Please report a vulnerability privately, never in a public issue,
either way:

- on GitHub, with **Report a vulnerability** on the Security tab of the
  repository MetaCPAN links to (Security → Advisories → Report a
  vulnerability);
- by email, to the maintainer, Iain Campbell, at <cpanic@cpan.org>.

If you can't reach the maintainer, or have had no reply after a
reasonable time, contact the CPAN Security Group, at
<cpan-security@security.metacpan.org>.

A useful report has the version of Ekorn::Pipeline, and of Perl; a
reproduction, as small as you can make it, with the stages and values
that show it; and what an attacker could do with it. You'll get a reply
when it has been read, and credit in the advisory and in `Changes` if
you'd like it.

## Scope

This policy covers the modules in this distribution. A vulnerability
in a module that uses Ekorn::Pipeline, such as DBIx::Squirrel, belongs
to that project, and one in a stage you wrote is yours, though a report
here that it reaches through Ekorn::Pipeline is welcome.

## Supported versions

Only the latest release is supported, on Perl 5.36 or later.

## Fixes

Fixes go into a new release, and `Changes` says what it fixes. A
release on CPAN is never changed: a version with a vulnerability may be
deleted from CPAN, though BackPAN keeps it, and the fixed one replaces
it.

This project doesn't pay for reports.
