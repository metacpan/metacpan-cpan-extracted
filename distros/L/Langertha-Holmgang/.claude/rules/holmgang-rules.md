# Holmgang House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Langertha::Holmgang — deterministic tool-use benchmarks for language models: cases in a Perl
DSL or suite format 2 YAML, simulated worlds, rules graded at the end state, runs against any
Langertha engine. The core is lifted out of CitiAI's `cai-platform`. Read first: `CONTEXT.md`,
the ADRs in `docs/adr/`, the karr card, and the source module in cai-platform (skill
`holmgang-core`, "Where the source lives"). The sibling Langertha repos and cai-platform each
have their own board.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `holmgang-worker` (default) |
| Simulators: device types, command grammar, `sim_gap`, answer worlds | `holmgang-sim-worker` |
| Write/extend tests | `holmgang-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `holmgang-release-manager` |
| Read-only research, audit, gap analysis | `holmgang-worker` ("read-only, change nothing") |

Behavior-relevant = runtime behavior, public API, the DSL, the format 2 loader, lint, tool
dispatch, simulators, grading and statuses, the runner, reports, the CLI, tests, performance.
Pure prose docs and `Changes` notes are not.

## Deviations from the house rules

- **Public tracker (`github.com/Getty/langertha-holmgang`) — not even reading on your own
  initiative.** No listing, viewing, commenting, editing, closing or creating unless the user
  explicitly says to handle a specific item, and every write is confirmed first.

## Holmgang-specific hazards

Mechanism and background: skill `holmgang-core`. These are the locks:

- **No real case enters this repo** (ADR 0003) — not as a fixture, an example, a quote in a
  commit message, card or ADR. Published cases with their solutions land in the next models'
  training data, and the benchmark then measures memorisation. The cai-platform suites are
  read in place or from a copy outside the checkout; tests that need them skip without it.
- **Format 2 loads unchanged** (ADR 0004). Over 200 cases depend on it and are not
  rewritten; a loader change that needs a case edit is a regression, even when every test
  here is green — the acceptance copy is the test that sees it.
- **The model sees only system prompt, messages and tool schemas.** State, observations,
  rules, solutions and the `untrusted` mark never go out. A leak passes every test and voids
  every measurement; check the outgoing request in a test, not the code path.
- **Simulators touch only their state** — no shell-out, socket or host file. They execute
  model output; a simulator that delegates to the host runs it for real.
- **Lint is part of loading.** A case that fails lint does not load. Fix the case or the
  simulator, never loosen lint to make a case load.
- **Real runs cost GPU time on CitiAI targets** and run from agent-lab, only when the card
  says so. Tests use `Langertha::Engine::Virtual`, never a key.

## Perl specifics — reference, don't restate

Module loading, Moose patterns, DSL sugar, cpanfile versioning, POD directives and commit
style live in the briefed skills (`getty-perl-core`, `getty-perl-moose`, `getty-perl-sugar`,
`perl-ai-langertha`, `perl-io-async-future`, `getty-perl-pod`,
`getty-perl-release-author-getty`, `getty-git-commit-style`). Do not duplicate that content
here.
