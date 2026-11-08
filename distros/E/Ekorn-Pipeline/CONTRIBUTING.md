# Contributing

Thank you for wanting to help. Ekorn-Pipeline welcomes **bug reports
and feature requests**, as issues on the repository MetaCPAN links to.
It doesn't accept pull requests.

## Why no pull requests

Ekorn-Pipeline is written by Iain Campbell, with Claude, as the
README's Acknowledgements say, and every change goes through the same
checks: tests across every Perl from 5.36 on, with floors on how much
of the code they cover, and documentation written alongside the code.
Owning every line keeps the credit honest, and the code safe to depend
on: no one else's code can be merged in, by mistake or by design.

A good report helps more than a pull request would. Its reproduction
becomes the failing test that comes before the fix. If you have a fix in
mind, sketch it in the issue: it will be written into the code with
tests, and you'll be thanked by name in `Changes`.

## A good bug report

- The versions: Ekorn::Pipeline's
  (`perl -MEkorn::Pipeline -E 'say Ekorn::Pipeline->VERSION'`), and
  Perl's.
- The smallest program that shows the problem, with the stages and the
  values given to them.
- What you expected, and what happened instead.

## A good feature request

- What you're trying to do, more than how: the values, the stages you
  would write, and where the current interface gets in the way.
- How you'd do it without a pipeline, if you know.

Some requests will be out of scope. The README says what
Ekorn-Pipeline is for, and saying no to a good idea that doesn't fit
keeps it simple to use. A request that needs a database belongs in
DBIx-Squirrel, which is built on Ekorn::Pipeline.

## Security

Please don't report a vulnerability in a public issue. See
[SECURITY.md](SECURITY.md).

## What to expect

Ekorn-Pipeline is one person's project, kept up as time allows. Reports
are read, but a reply can take a while.
