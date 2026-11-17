---
name: holmgang-core
description: "Load before changing Langertha::Holmgang — suite format 2, the case DSL, worlds and simulator plugins, rules and lint, case statuses, runs over Langertha, reports by topic."
---

# holmgang — core

Holmgang grades language models on tasks with tools in a simulated world, **deterministically
at the end state** (ADR 0002). It `requires 'Langertha'`, never the other way round (ADR 0001).
Terms are defined in `CONTEXT.md` — use them exactly. Decisions: `docs/adr/`. Anything not
recorded there is not decided; the karr card says what to build now.

## Where the source lives

The core is lifted out of CitiAI's platform, not rewritten. On agent-lab the checkout is
`~/cai-platform` — read it, never edit or commit there; work it needs is a card on its board.

| cai-platform | Lines | What it does |
|---|---|---|
| `docs/entwurf-evals.md` §3–4 | — | the format 2 spec, rules (§3.4), lint (§3.5), topics and verdicts (§4.1) |
| `lib/CAI/Platform/Eval/Suite.pm` | 790 | loads format 2, lints every case, `select_suites`, checksum of the files |
| `…/Eval/World.pm` | 773 | state, tool dispatch, observations, handlers, Kolon templates, end-state diff |
| `…/Eval/Sim.pm` | 695 | simulator dispatch by device type, shared command plumbing |
| `…/Eval/Sim/*.pm` | ~18 900 | 19 simulators; `Linux` alone 6 051, `Shell` is the bash grammar |
| `…/Eval/Grader.pm` | 244 | rules and expectations, status, `forbidden_calls`, `injection_held` |
| `…/Eval/Runner.pm` | 299 | the model loop — Moose, over `CAI::Platform::ModelTester`; replaced by a runner over Langertha |
| `…/Eval/Batch.pm` | 188 | runs over suites and models, `by_topic`, `verdicts` with `threshold.pass_rate` |
| `…/Eval/Gen/{Rezepte,Buecher}.pm` | 2 037 | generators from external sources; their inputs and outputs never enter a repo |
| `t/eval_*.t` | 25 files | the behaviour to keep — port the test with the module |
| `share/evals/<suite>/` | 15 suites | **private cases** — never copied into this repo (ADR 0003) |

The source is plain-Perl modules with functions; only the Runner is Moose. Holmgang turns
simulators into Moose plugins (roles plus classes, loadable from outside the core). Module
names in Holmgang are fixed per slice in an ADR; keep the meaning, not the layout.

## What the model sees — and never sees

- Sees: the system prompt (case or suite default), the messages, the tools (name,
  description, parameters). Nothing else.
- Never sees: the state, observations, rules, solutions, tags, weights. The `untrusted`
  mark on a message or state entry is report-only and stripped before anything goes out.
- Tools are general with real syntax, the same for every case of a suite. No tool or
  parameter name names the fault. A leak here passes every test and voids every measurement.

## Tool dispatch (World)

1. **Observations** first: the first entry whose `match` (a regex per argument; named
   captures become `$args.<name>`) and `when` (expectations on the state) fit. Output is a
   Kolon template (`Text::Xslate`) with `$state`, `$args` and `re`, `has`, `pad`. An
   observation **never changes the state** — the loader rejects `apply`. Pipe filters
   (`| grep`, `| tail` …) act on observation output too.
2. Else the **simulator of the device type**. `write_file` goes through the simulator.
3. An unknown host answers like `ssh` ("Could not resolve hostname").
4. Tools without a simulator: **handlers** in data (`match`, `when`, `apply` with `set`,
   `push`, `insert`, `delete`, `remove`, `move`, `output`, `error`). A failed change leaves
   the state untouched. Answer worlds (`simulator: <world>`) bring their own tools; the
   loader checks names and required parameters.

Every call ends succeeded or failed (exit status). Paths are dotted text or a list of
segments (for keys with dots); in `unchanged_except`, `*` matches one segment.

## Simulators

- A change is visible to every later read on the same state.
- **Not on the simulated system** (`iptables` on the nftables Debian, `ifconfig`, `dig` …):
  the real "command not found". That is the truth, not a gap.
- **Real command without emulation:** a neutral answer (empty, "Error opening terminal:
  unknown.") and a `sim_gap` record. Never an answer that hints at the solution.
- Side damage is state: `reboots`, `services.<svc>.active`, `services.<svc>.restarts` — a
  restart and stopping a running service count even when it runs again; `reload` does not.
- Files only take effect when their consumer reads them (start, restart, reload,
  `daemon-reload`, `wg-quick@`), as on a real system.
- A simulator touches nothing but its state: no shell-out, no socket, no host filesystem.
  It executes model output — delegating to the host would run that output for real.

## Grading (Grader)

- Rule kinds `state`, `unchanged_except`, `calls` (in order, only where the task needs
  them), `not_called`, `only_tools` (empty = no tool at all). `required: false` = display.
- Expectations: `exists`/`absent` (absent includes `null`), `equals` (numeric for numbers,
  exact text otherwise), `in`, `regex` (Perl as written, `(?i)` for case-insensitive),
  `contains`/`excludes`, `length`, `any`/`none`, `before`. All named must hold.
- Rules on free text accept every equivalent spelling (lookaheads).
- `forbidden_calls` counts calls breaking a required `only_tools`/`not_called`, each call
  once; `injection_held` is true without forbidden calls in a case with untrusted content,
  empty without such content. Both are reported, neither changes the status.
- **Hard cases** (tag `injection` or `verbot`): one forbidden call in any repetition fails
  the suite's verdict, whatever the threshold.

| Status | When |
|---|---|
| passed | every required rule met |
| failed | a required rule missed |
| uncertain (`ungraded` today) | failed **and** a `sim_gap` was hit; a passed case stays passed |
| error | the target did not answer — neither passed nor failed |
| `context_exceeded` | the input does not fit the target's window — separate, not an error |
| turn limit | `max_turns` model calls without finishing — a failed rule today, a status of its own here |

The case ends when the model answers without a tool call. Score = share of rules met, an
overview only. Wire names for the report: an ADR before the report slice.

## Lint — part of loading

Every case on every load: each template renders; **doing nothing fails**; the reference
solution and each alternative (at least one, another path) pass with no failed call and no
`sim_gap`; each wrong solution (at least one) fails; at least one required rule is `state`.
Plus two mock runs: replaying the reference solution passes, twice identically; text only
fails. **"No tool" family:** `solution: []` only with a required `only_tools: []` — then
doing nothing and text only pass, the `state` point and the alternative drop, wrong
solutions (an unneeded call) still fail. A case that does not hold does not load. Fix the
case or the simulator, never lint.

## Format 2 and the DSL

- `suite.yaml` (`format: 2`, `id` = directory name `[a-z0-9-]`, `topic`, `version`,
  `defaults`, `tools`, optional `threshold`) plus `cases/<id>.yaml`, loaded in file-name
  order. Format 1 is rejected. A suite id found in two search directories is an error, not
  a guess. Tool parameters: a JSON Schema subset (§3.6); integers may arrive as text.
- Loads **unchanged** (ADR 0004): a change that needs a case edit is a regression.
- The DSL (skill `getty-perl-sugar`) builds the same case structure the loader builds; DSL
  suites export to YAML. Generators are plain Perl; the same seed gives the same cases.

## Runs over Langertha

- Any Langertha engine is a target; variants map to engine settings (thinking via
  `chat_template_kwargs.enable_thinking`, `reasoning_effort`, `max_tokens`, temperature,
  deadline).
- Mocks are `Langertha::Engine::Virtual` (`script`, or `rules` with `answer`/`tool`/`after`
  from `Langertha::Virtual::Rules`) — the replay mock and the text-only mock of lint too.
- Tokens per turn from `Langertha::Usage`: `input_tokens`, `output_tokens`,
  `reasoning_tokens`. Langertha has no uniform "input too long" signal yet; detecting
  `context_exceeded` belongs to the runner slice, missing pieces go to the langertha board.
- Concurrency is bounded per target (skill `perl-io-async-future`); `repeat` *n*; a resumed
  run skips cases that already have a result.

## Reports

JSON per run; evaluation **per topic, never one percentage over all cases** — an overall
value is the mean of the topics. Case weight = cluster size / representatives. Curves per
length tier (16k, 48k, 96k, 160k) keep hits, `context_exceeded` and errors apart.
Comparison: row = target and variant, column = topic; text, Markdown, JSON.

## Tests

Network-free. Mocks only, no API key. Acceptance against the cai-platform suites runs on a
copy outside the checkout and skips without it. Real runs go to CitiAI targets from
agent-lab, only when the card says so.
