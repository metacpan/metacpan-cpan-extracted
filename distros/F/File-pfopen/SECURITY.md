# Security Policy

## Supported versions

Only the latest release of File::pfopen on CPAN receives security fixes.

## Reporting a vulnerability

Please report security problems privately, by email to Nigel Horne
<njh@nigelhorne.com>, or through
[GitHub's private vulnerability reporting](https://github.com/nigelhorne/File-pfopen/security/advisories/new).
Please don't open a public issue or RT ticket for a security problem.

Include the version of File::pfopen, your version of Perl and operating
system, and the smallest example that shows the problem.
You should get a reply within a week.

## Security-relevant behaviour

* Only file modes are accepted (`<`, `>`, `>>`, `+<`, `+>`, `+>>`, with
  optional I/O layers), so a found file can never be run as a command.
  Before version 0.04 any mode was accepted, including the pipe mode `-|`.
* Names are opened with the three-argument form of `open`, so characters
  such as `|`, `<` and `>` in a name have no special meaning.
* `$prefix` can contain directories, including `..`, so it can find files
  outside the listed directories. Check it before passing it in if it comes
  from an untrusted source.
* In taint mode, writing to a file with a tainted name dies, and a call with
  tainted arguments never uses or adds to the remembered results.
  Before version 0.04 a remembered result could let a tainted write succeed.
