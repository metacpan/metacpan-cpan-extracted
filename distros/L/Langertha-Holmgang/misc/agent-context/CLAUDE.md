# Langertha::Holmgang — CLAUDE.md

## Status: scaffold, extraction starting

Deterministic tool-use benchmarks for language models: cases in a Perl DSL or suite format 2
YAML, simulated worlds, rules graded at the end state, runs against any Langertha engine.
Sibling-dist pattern like `langertha-knarr` / `langertha-raider` / `langertha-skeid`
(`requires 'Langertha'`, never the other way round). Repo: github.com/Getty/langertha-holmgang.

The core is lifted out of the evaluation core of CitiAI's `cai-platform`
(`CAI::Platform::Eval::*`). The repo holds the distribution base, the agent team and the
decisions so far; the code arrives in small vertical slices. Where things live:

- **`CONTEXT.md`** — vision, vocabulary, scope, acceptance, migration order. Read before any
  non-trivial change.
- **`docs/adr/`** — every decision. Anything not recorded there is not decided.
- **karr board** — all open work and slices (`karr list --compact`).
- **Source of the extraction** — `~/cai-platform` on agent-lab: `lib/CAI/Platform/Eval/`,
  `t/eval_*.t`, `docs/entwurf-evals.md`. Read only; the map is in skill `holmgang-core`.

Development happens on agent-lab (`~/langertha-holmgang`), next to cai-platform and the
CitiAI targets. Real benchmark cases never enter this repo (ADR 0003).

Don't create new planning or status files in the repo root: decisions become ADRs, open work
becomes tickets.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle is a shared house rule (skilletor bundle `getty-cpan-dist@getty`), the lanes are in
`.claude/rules/holmgang-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `holmgang-worker` (default) |
| Simulators: device types, command grammar, `sim_gap`, answer worlds | `holmgang-sim-worker` |
| Write/extend tests | `holmgang-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `holmgang-release-manager` |
| Read-only research, audit, gap analysis | `holmgang-worker` ("read-only, change nothing") |

Every subagent is a `holmgang-*` agent — never the built-in `general-purpose`/`Explore`/`Plan`.

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main agent
delegates rather than loading them. The skills are installed by skilletor from
`.claude/skilletor.json` (sources getty, karr, langertha) into `.claude/skills/` — gitignored
build artifacts; change a skill in its source repo and `skilletor sync`, never edit the
installed copy. `holmgang-core` is this repo's own skill and tracked here.

## Build and test

Uses the `[@Author::GETTY]` Dist::Zilla plugin bundle.

```bash
prove -lr t/        # recursive: simulator tests live in subdirectories
dzil test           # build and test
```

`LICENSE` is committed (`dzil genlicense`, then `git add LICENSE`); the bundle checks it
against `dist.ini` and gathers only tracked files.
