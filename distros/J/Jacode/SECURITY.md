# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| older   | :x:                |

## Reporting a Vulnerability

To report a vulnerability, please send e-mail to ina@cpan.org.

Do not report security vulnerabilities through public GitHub issues.

You can expect a response within a few days. If the issue is confirmed,
a patch will be released as soon as possible.

## Notes

jacode.pl and Jacode.pm perform character encoding conversion only.
They do not open network connections, execute external commands,
or write to the filesystem during normal use.

The only security-sensitive operation is the `open(FILE, $file)`
call in the bundled pkf command (invoked when running jacode.pl
directly as a script), which reads files named on the command line.
