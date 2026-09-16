# CLAUDE.md

This repo is the `[@Author::GETTY]` plugin bundle itself — the release/CI machinery every
other GETTY dist inherits, dogfooded on its own source via `[Bootstrap::lib]`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lanes are in `.claude/rules/dist-zilla-pluginbundle-author-getty-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug the bundle, subsection, GiteaMeta, the CI action | `dist-zilla-pluginbundle-author-getty-worker` (default) |
| Write/extend tests | `dist-zilla-pluginbundle-author-getty-test-writer` |
| Pre-release audit | `dist-zilla-pluginbundle-author-getty-release-checker` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Architecture, the shared `dzil-test` CI action
(`dzil listdeps --author`, no faked `Test::Pod`), and the commit-message convention live
in `.claude/skills/dist-zilla-pluginbundle-author-getty-core/` and the rules file — not
here.
