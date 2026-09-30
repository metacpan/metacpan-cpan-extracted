# Dist::Zilla::Plugin::GatherAgentContext

A Dist::Zilla `FileGatherer` plugin that snapshots a distribution's agent context
(`.claude/`, `.codex/`, `CLAUDE.md`, `AGENTS.md`, ...) into the build under
`misc/agent-context/` for provenance — see `lib/Dist/Zilla/Plugin/GatherAgentContext.pm`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/gatheragentcontext-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug / test the plugin | `gatheragentcontext-worker` (default) |
| Commits, `Changes`, pre-release audit | `gatheragentcontext-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main agent
delegates rather than loading them. Skills are installed via skilletor
(`.claude/skilletor.json`) under `.claude/skills/` and are git-ignored — which is exactly the
context this very plugin snapshots into a build.

## Build & test

- `dzil test --all` — full gate (includes the woven author tests `prove` skips)
- `dzil build` — inspect the built tarball (README/POD are woven here)
