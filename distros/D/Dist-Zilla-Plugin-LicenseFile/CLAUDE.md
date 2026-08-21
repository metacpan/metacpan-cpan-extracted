# Dist-Zilla-Plugin-LicenseFile — CLAUDE.md

## Overview

Two halves of one feature: `[LicenseFile]` checks that the `LICENSE` gathered
from the repository still matches the distribution metadata, and `dzil
genlicense` writes the file that check expects. The plugin never writes
anything, the command never checks anything at build time.

## Build System

Uses the `[@Author::GETTY]` Dist::Zilla plugin bundle. `[Bootstrap::lib]` is in
`dist.ini` on purpose — this distribution's own build runs the plugin it
defines, so it has to load it from `lib/` rather than from what is installed.

```bash
prove -l t/         # run tests directly
dzil test           # full Dist::Zilla test
dzil build          # build distribution
dzil release        # release to CPAN
```

## Project Structure

```
lib/Dist/Zilla/Plugin/LicenseFile.pm         # the build-time check
lib/Dist/Zilla/App/Command/genlicense.pm     # the writer
t/00-load.t                                  # every module compiles
t/10-check.t                                 # plugin behaviour
t/20-genlicense.t                            # command behaviour, and the two together
```

## Conventions

- **The file holds `->license`, never `->fulltext`.** The copyright notice that
  `fulltext` puts above the licence defeats GitHub's licence detection —
  verified against the live API: `NOASSERTION` with `fulltext`, `Artistic-2.0`
  with the bare text, same repository. Anyone "fixing" this back to `fulltext`
  silently undoes the only reason the file is committed.
- **`filename`, `wanted_text` and `comparable` are class methods on the plugin,
  and the command calls them.** Both halves must agree on what counts as the same
  licence text — if they drift apart, a distribution can reach a state where
  `dzil genlicense` reports the file as current and the build still rejects it.
  Never inline that logic in the command.
- **`comparable` forgives trailing whitespace only.** An editor adding a final
  newline is not drift; anything else is a real difference and should fail.
- **The `required = 0` path logs, it does not skip.** A distribution running
  with the check downgraded still has to say what is wrong on every build,
  otherwise the migration never finishes.
- The `@Author::GETTY` bundle in
  `../p5-dist-zilla-pluginbundle-author-getty` loads this plugin and removes
  `@Basic`'s `License` — check it still works after any attribute rename.
- Never write `our $VERSION` into `lib/*.pm`; `[@Author::GETTY]` injects it.

## Testing

Tests use `Dist::Zilla::Tester` for the plugin and `Dist::Zilla::App::Tester`
for the command, each building a throwaway dist in a tempdir. The expected
licence text comes from `Software::License::Perl_5`, constructed the same way
the test `dist.ini` declares it.

## When changing behavior

- Add a `Changes` entry under `{{$NEXT}}`.
- Update the POD in the module you changed.
- Update `README.md` if user-facing config or output strings change — the
  README quotes the failure message verbatim.

---

See `~/.claude/CLAUDE.md` for global Perl workspace conventions.
