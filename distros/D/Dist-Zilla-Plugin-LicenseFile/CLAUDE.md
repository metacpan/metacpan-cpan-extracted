# Dist-Zilla-Plugin-LicenseFile — CLAUDE.md

`[LicenseFile]` checks that the committed `LICENSE` still matches the distribution's
declared licence; `dzil genlicense` writes the file that check expects. The plugin never
writes, the command never checks at build time.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the principle is a shared house rule (skilletor bundle `getty-cpan-dist@getty`); the lane is
in `.claude/rules/dist-zilla-plugin-licensefile-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug the plugin, the command, cpanfile | `dist-zilla-plugin-licensefile-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `dist-zilla-plugin-licensefile-release-manager` |

The agents carry their conventions via `briefing.skills` (see `.claude/agents/`); the
main agent delegates rather than loading them. Architecture, the fulltext-vs-license
rationale and the shared `filename`/`wanted_text`/`comparable` contract live in skill
`dist-zilla-plugin-licensefile-core` (source under `.claude/skills/`). House rules,
delegation lock and the release-permission gate are in `.claude/rules/`.

Work is tracked on this repo's `karr` board (`karr board`).

## Build and test

```bash
prove -l t/         # run tests directly
dzil test           # full Dist::Zilla test
dzil build          # build distribution
dzil release        # release to CPAN — never without explicit permission
```

`[Bootstrap::lib]` is in `dist.ini` on purpose: this distribution's own build runs the
plugin it defines, so the plugin loads from `lib/` rather than from what is installed.

See `~/.claude/CLAUDE.md` for global Perl workspace conventions.
