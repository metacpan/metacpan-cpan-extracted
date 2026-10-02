# Langertha::Raider — CLAUDE.md

## Status: assembled, redesign decided, implementation starting

The extraction is done: this dist ships the `Langertha::Raider` engine (from `langertha`
core) plus the former `App::Raider` CLI/Hall/ACP app as `Langertha::Raider::*`
(`App::Raider` → `Langertha::Raider::CLI`; the six old `App::Raider*` names ship as
reserved stubs). Sibling-dist pattern like `langertha-knarr` / `langertha-skeid`
(`requires 'Langertha'`, never the other way round). Repo: github.com/Getty/langertha-raider.

The code works but is structurally messy; the redesign is decided and lands in small
vertical slices. Where things live:

- **`CONTEXT.md`** — vision and vocabulary. Read before any non-trivial change.
- **`docs/adr/`** — every decision. Anything not recorded there is not decided.
- **karr board** — all open work, defects and slices (`karr list --compact`).
- `docs/RAIDER-REDESIGN-HANDOFF.md` — frozen research input the ADRs cite (fixtures
  F01–F40, prompts). A proposal, not a spec. Its "S0" (`STATE-AND-VISION.md`) and the
  old `TODO.md` / `MIGRATION-FROM-LANGERTHA.md` were folded into the above and removed;
  read them via `git show f939a69:<file>` if ever needed.

Don't create new planning/status files in the repo root: decisions become ADRs, open work
becomes tickets.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/raider-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `raider-worker` (default) |
| Write/extend tests | `raider-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `raider-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. The skills are installed by skilletor from
`.claude/skilletor.json` (sources getty, karr, langertha) into `.claude/skills/` —
gitignored build artifacts; change a skill in its source repo and `skilletor sync`,
never edit the installed copy.
