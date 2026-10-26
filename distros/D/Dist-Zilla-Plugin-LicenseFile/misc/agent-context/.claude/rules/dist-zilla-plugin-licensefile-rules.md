# Dist-Zilla-Plugin-LicenseFile House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Ship the repository's committed LICENSE, and keep it honest — a Dist::Zilla plugin plus the
`dzil genlicense` command. Read first: the plugin and the command share three class methods; a
change to `filename`/`wanted_text`/`comparable` reaches both halves at once.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug the plugin, the command, cpanfile | `dist-zilla-plugin-licensefile-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `dist-zilla-plugin-licensefile-release-manager` |
| Read-only research, audit, gap analysis | `dist-zilla-plugin-licensefile-worker` ("read-only, change nothing") |

Behavior-relevant = the `munge_files` check and its messages, the `dzil genlicense` command, the
shared `filename`/`wanted_text`/`comparable` class methods, the `required` attribute,
`cpanfile`, and tests. Pure prose docs and `Changes` notes are not.

## Deviations from the house rules

- **CPAN RT counts as a public tracker** alongside GitHub issues.

## Hazards — the background is in skill `dist-zilla-plugin-licensefile-core`

- **The committed `LICENSE` holds the bare `->license`, never `->fulltext`.** The copyright
  notice `fulltext` prepends makes GitHub report `NOASSERTION` instead of the real licence;
  detection is the whole reason the file is committed, so "fixing" it back to `fulltext`
  silently defeats the distribution.
- **The plugin checks, the command writes — never the reverse.** The plugin never writes
  anything; the command never checks at build time. Keep the split on that line.
- **`comparable` forgives trailing whitespace only.** A mismatch is the signal the check exists
  to raise; do not widen the normalisation to make a failing build pass.
- **`required = 0` logs, it does not skip** the check. A downgraded check still complains on
  every build.
- **`[Bootstrap::lib]` in `dist.ini` is deliberate** — this dist runs the plugin it defines, so
  the plugin must load from `lib/`, not from what is installed. A green `dzil build` here is
  exercising the plugin against itself.
- **`@Author::GETTY` in `../p5-dist-zilla-pluginbundle-author-getty` constructs this plugin.**
  An attribute or shared-class-method rename is a coordinated change: verify that bundle, or
  file a ticket on its board before landing.

## Perl specifics — reference, don't restate

Module loading, `$VERSION`, cpanfile pinning and house style: skills `getty-perl-core`,
`getty-perl-moose` (the plugin class). `[@Author::GETTY]`, POD weaving, `{{$NEXT}}`: skill
`getty-perl-release-author-getty`. dist.ini mechanics: `perl-release-dist-ini`. Commit style:
`getty-git-commit-style`. Architecture and the shared-contract invariants:
`dist-zilla-plugin-licensefile-core`.
