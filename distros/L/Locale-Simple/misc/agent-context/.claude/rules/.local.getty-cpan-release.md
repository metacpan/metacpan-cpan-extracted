---
description: Getty's CPAN distributions — what is safe to run, and why the CPAN state never blocks anything.
---

# CPAN release

`dzil build`, `dzil test` and `prove -lr t/` are fine anytime. `dzil release` and any CPAN
upload fall under the publish gate.

- `prove -lr`, never `prove -l t/` — without `-r` tests in subdirectories silently don't run.
- A new file is invisible to `dzil build` until it is tracked (`git add`): Git::GatherDir
  only ships what git knows, so a build can pass locally and ship without it.

**Only the local working tree counts.** The repo's `$VERSION` is the next, unreleased one
and is never copied back from CPAN. A lagging CPAN version — of this distribution or of a
sibling — is never a blocker and never a ticket. Coupled distributions are released
together, on the maintainer's word.
