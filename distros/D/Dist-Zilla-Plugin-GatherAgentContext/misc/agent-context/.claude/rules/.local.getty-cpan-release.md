---
description: Getty's CPAN distributions — what is safe to run, and why the CPAN state never blocks anything.
---

# CPAN release

`dzil build`, `dzil test` and `prove -lr t/` are fine anytime. `dzil release` and any CPAN
upload fall under the publish gate.

**Only the local working tree counts.** The repo's `$VERSION` is the next, unreleased one
and is never copied back from CPAN. A lagging CPAN version — of this distribution or of a
sibling — is never a blocker and never a ticket. Coupled distributions are released
together, on the maintainer's word.
