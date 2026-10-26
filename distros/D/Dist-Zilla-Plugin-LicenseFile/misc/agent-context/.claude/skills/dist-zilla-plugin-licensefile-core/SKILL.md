---
name: dist-zilla-plugin-licensefile-core
description: "Use when working on the Dist-Zilla-Plugin-LicenseFile distribution — the [LicenseFile] build-time check, the dzil genlicense command, why the committed LICENSE holds the bare license and not fulltext, the filename/wanted_text/comparable contract the two halves share, or the licence-detection behaviour of GitHub/Gitea/Forgejo."
---

# Dist::Zilla::Plugin::LicenseFile — architecture and invariants

One feature, two halves that must agree:

- `lib/Dist/Zilla/Plugin/LicenseFile.pm` — a `FileMunger` plugin that on every
  build **checks** the `LICENSE` gathered from the repository against the licence
  the distribution declares, and refuses to build when it is missing or stale.
  It never writes or modifies anything.
- `lib/Dist/Zilla/App/Command/genlicense.pm` — the `dzil genlicense` command that
  **writes** `LICENSE` into the repo root. It never checks anything at build time.

The plugin checks, the command writes; neither does the other's job.

## Why the file exists at all — and why it holds the bare license

Dist::Zilla's default `[License]` plugin generates `LICENSE` *into the build*, so
the file reaches the CPAN tarball but never the repository. Hosting platforms only
see the repository: **GitHub, Gitea and Forgejo detect and link a licence from a
committed `LICENSE` file**, so a distribution built the default way shows as
unlicensed on its own project page. The fix is to commit the file and let
`GatherDir` pick it up like any source file — which is why `@Basic`'s `License`
plugin must be removed (it would generate a second `LICENSE` and abort the build).

Committing the file silently rots, though: nothing ties the committed text to the
`license` setting in `dist.ini`. This plugin closes that gap.

**The file holds `$zilla->license->license` — the bare licence — deliberately NOT
`->fulltext`.** `fulltext` (what the default `[License]` plugin writes) prefixes
the licence with a copyright notice, and that prefix defeats GitHub's detector:
verified against the live API, a `LICENSE` holding the `fulltext` of Artistic 2.0
is reported `NOASSERTION` (linked but unnamed), while the same repo with the bare
text is reported `Artistic-2.0`. Since detection is the *entire* reason to commit
the file, the bare text wins. Nothing is lost — the copyright notice still reaches
the tarball via the `LICENSE AND COPYRIGHT` POD section Pod::Weaver writes, and the
holder/year still reach `META.json`.

**Anyone "fixing" this back to `->fulltext` silently undoes the only reason the
file is committed.** This is the invariant the whole distribution exists to hold.

## The shared contract — three class methods

`filename`, `wanted_text` and `comparable` are **class methods on the plugin**, and
the command calls them on the class:

| Method | Returns |
|---|---|
| `filename` | `'LICENSE'` — the name both halves agree on |
| `wanted_text($zilla)` | `$zilla->license->license`, the bare text the file must hold |
| `comparable($text)` | the text normalised for comparison |

Both halves must agree on what counts as "the same licence text". **Never inline
that logic in the command** — if the two drift apart, a distribution can reach a
state where `dzil genlicense` reports the file as current and the build still
rejects it (or vice versa). The command reaches into the plugin class precisely so
that one definition serves both.

**`comparable` forgives trailing whitespace only** — `s{\s+\z}{}`. An editor adding
a final newline is not drift; anything else (a re-wrapped paragraph, a changed
copyright line, a different licence entirely) is a real difference and must fail.
Do not broaden this normalisation to paper over a mismatch — a mismatch is the
signal the check is there to raise.

## The `required` attribute — logs, does not skip

`required` defaults to true: a failing check aborts the build via `log_fatal`. Set
`required = 0` and the *same* complaint is emitted through `log` and the build
carries on — for migrating an existing distribution, where the first build is what
tells you the file is missing or wrong.

**`required = 0` downgrades to a log, it does not skip the check.** A distribution
running with the check downgraded still says what is wrong on every single build,
otherwise the migration never finishes. The `_complain` helper is the single point
that chooses `log_fatal` vs `log`; both messages are identical and both name the
fix (`run 'dzil genlicense' and commit the file`).

## Bootstrap: the plugin runs against itself

`dist.ini` declares `[Bootstrap::lib]` — deliberately. This distribution *runs* the
plugin it defines, so the plugin has to load from `lib/`, not from whatever version
happens to be installed in the environment. Without the bootstrap, a green `dzil
build` would exercise an installed release of the plugin instead of the code in
this tree — the check would validate itself with a stale implementation.

## Testing

- `t/00-load.t` — every module compiles.
- `t/10-check.t` — plugin behaviour, driven through `Dist::Zilla::Tester`.
- `t/20-genlicense.t` — command behaviour via `Dist::Zilla::App::Tester`, and the
  two halves together (genlicense writes, the plugin then passes).

Each test builds a throwaway dist in a tempdir. The expected licence text comes
from `Software::License::Perl_5`, constructed the same way the test `dist.ini`
declares it — so an assertion checks against the real `Software::License` output,
not a hand-copied string that would rot.

## The bundle consumer

`@Author::GETTY` in `../p5-dist-zilla-pluginbundle-author-getty` loads this plugin
and removes `@Basic`'s `License`. An attribute rename or a change to the shared
class-method surface is a cross-repo change — verify that bundle still builds, or
file a ticket on its board before landing.
