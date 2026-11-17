# Holmgang — Vision, Vocabulary, Scope

What Holmgang is for, the words it is written in, and what the first version must carry. Use
these words in code, tests, tickets and ADRs. Decisions live in `docs/adr/`, open work on the
karr board — not here.

## Vision

A *holmgang* was a Norse duel under fixed rules: on a small island (*holmr*), with witnesses,
a marked-out ground, agreed weapons and shields. Whoever left the ground had lost. At the end
stood a verdict everyone accepted. That is what this framework is for language models.

Holmgang measures models on **tasks with tools** and grades them **deterministically**: no
judge model, no text comparison. Only what the model brought about through tools in a
simulated world is graded. It builds on Langertha and can measure every engine Langertha
knows.

The grading principle runs today in CitiAI's platform (`cai-platform`,
`CAI::Platform::Eval::*`, a few dozen suites, several hundred cases) and has proven itself there. Holmgang
lifts it out, generalises it and adds a Perl DSL for writing cases. Afterwards `cai-platform`
only depends on Holmgang (ADR 0001).

## Language

| Term | Meaning |
|---|---|
| **Suite** | A set of cases sharing tools, system prompt and defaults. Has `id`, `topic`, `version`, title, licence and sources. |
| **Case** | One task: messages, optional system prompt, the suite's tools, the initial world, observations, rules, reference solution, alternatives, wrong solutions, tags, difficulty, length tier, weight. |
| **World** | The simulated state: devices and services, or a world without devices for answer tools. |
| **Device** | An entry in the world with a `type` (`linux`, `routeros`, `ios`, …) that picks its simulator. |
| **Simulator** | A plugin that executes real commands on the state of its device type. |
| **Simulation gap** (`sim_gap`) | A real command the simulator does not model: it answers neutrally and records the gap. A command that does not exist on the simulated system gets the real "command not found" — that is not a gap. |
| **Observation** (`observe`) | Case-supplied output for diagnostic commands whose answer lies outside the state (ping across devices, logs). Never changes the state. |
| **Handler** | A tool effect described in data, for small worlds without a simulator. |
| **Answer world** | A world without devices whose tools take answers: give the answer, report a finding, rate a clause, hand in a translation. Model: `Sim::Kueche` in cai-platform. |
| **Fixture** | Checked-in fixed output for cases that need it (pre-rendered HTML …). |
| **Rule** | One check with a title and exactly one kind: `state`, `unchanged_except`, `calls`, `not_called`, `only_tools`, `check`, `packet`, `login` (ADR 0005). Required unless marked display-only. |
| **Expectation** | What a `state` rule demands of a value: `exists`/`absent`, `equals`, `in`, `regex`, `contains`/`excludes`, `length`, `any`/`none`, `before`. |
| **Reference solution** | Tool calls that must pass. **Alternative**: another correct path that must pass too. **Wrong solution**: a typical mistake that must fail. The model never sees any of them. |
| **Lint** | The self-check every case passes on every load (below). |
| **Target** | An endpoint plus model, reached through a Langertha engine. |
| **Variant** | Settings per target: thinking on/off (`chat_template_kwargs.enable_thinking`), `reasoning_effort`, `max_tokens`, temperature, deadline. |
| **Run** | One target and variant over one suite, optionally repeated *n* times; resumable. |
| **Status** | The outcome of one case in one repetition (table below). |
| **Score** | Share of rules met — an overview only; it never decides pass or fail. |
| **Topic** | The category a suite belongs to and the axis of every evaluation. |
| **Weight** | A case stands for a cluster of similar cases: weight = cluster size / representatives. |
| **Length tier** | Context-length step of a case: 16k, 48k, 96k, 160k tokens. |
| **Generator** | Plain Perl that produces cases; a fixed seed yields the same cases every time. |
| **Untrusted content** | A message or state entry marked as not coming from the user. The mark is report-only; the model never sees it. |

### Statuses

| Status (brief) | Meaning | Today in cai-platform |
|---|---|---|
| bestanden — passed | every required rule met | `passed` |
| durchgefallen — failed | a required rule missed | `failed` |
| unsicher — uncertain | failed, but the model hit a simulation gap | `ungraded` |
| error | the target did not answer | `error` |
| `context_exceeded` | the input does not fit the target's context window; counted separately, **not** an error | `context_exceeded` |
| `no_vision` | the case carries an image the target cannot see; counted separately, **not** an error | — |
| rundengrenze — turn limit | too many turns without finishing | a failed rule |

The wire names (`passed`, `failed`, `uncertain`, `error`, `context_exceeded`, `turn_limit`, `no_vision`) and the report format are fixed in ADR 0006.

## What it must cover

### 1. Cases in a Perl DSL

Cases and suites are written in Perl with a small language in the style of `Test::More`,
Moose or Dancer. A sketch (keywords, collisions, generators and discovery: ADR 0007):

```perl
use Langertha::Holmgang;

suite 'example-web' => sub {
  title   'Example: web servers';
  version 1;
  topic   'betrieb';
  system_prompt file 'system.md';
  tool run_command => ( description => '...', simulator => 'run_command', parameters => {...} );
  tool write_file  => ( description => '...', simulator => 'write_file',  parameters => {...} );

  case '01-nginx-stopped' => sub {
    title 'Shop down after an update';
    device web1 => linux => { services => { nginx => { active => 0 } } };
    ask 'The shop on web1 is down since the last update. Get it back up.';
    rule 'nginx runs'         => at 'web1.services.nginx.active', equals => 1;
    rule 'nothing else moved' => unchanged_except [ 'web1.services.nginx.*' ];
    solution    run web1 => 'systemctl start nginx';
    alternative 'enable and start' => run web1 => 'systemctl enable --now nginx';
    wrong       'reboot instead'   => run web1 => 'reboot';
  };

  generate seed => 4711, sub {
    my ( $rng ) = @_;
    for my $tokens ( 16_000, 48_000, 96_000 ) {
      case "clause-$tokens" => sub { ask [ 'Check the clause.', haystack kind => '...', tokens => $tokens ]; ... };
    }
  };
};
```

- Constructs: case, message(s), system prompt, tools, world, rules, reference solution,
  alternatives, wrong solutions, tags, difficulty, length tier.
- **Generators are plain Perl** (loops, seed, templates). A fixed seed always yields the same
  cases.
- The DSL builds the same internal case structure as the YAML loader. Both lead into the same
  runner (ADR 0004).

### 2. YAML stays a load format

- Suite format 2 (`suite.yaml` plus `cases/*.yaml`) must **load unchanged**: the 200+ cases
  from cai-platform are not rewritten in one go.
- An export of DSL suites to YAML is wanted, so cases stay readable and comparable without
  Perl.

### 3. Worlds and tools

- Simulators execute real commands on the state. In cai-platform today: Linux (ip, nft, wg,
  sysctl, systemd, files, shell grammar), PostgreSQL, MariaDB, Redis, Postfix, DNS,
  Kubernetes, RouterOS, IOS, storage, backup, monitoring, sshd, logrotate, calendar, accounts,
  kitchen.
- Simulators are **plugins** (Moose roles and classes) and can be written outside the core.
- A simulator that cannot do a command answers like a real system and records a **simulation
  gap**. A case that hits one is uncertain, not failed.
- **Answer worlds** without devices for answer tools.
- Checked-in **fixtures** for cases with fixed outputs.
- **Tools reveal nothing.** No tool or parameter name names the fault.

### 4. Grading

| Rule kind | checks |
|---|---|
| `state` | a value in the end state against expectations |
| `unchanged_except` | nothing else changed — side damage shows up |
| `calls` | required calls, only where the task needs them |
| `not_called` | forbidden calls |
| `only_tools` | the main rule of injection cases |

- **Passed** means every required rule is met. The score is only the share of rules met.
- **Injection:** `forbidden_calls` and `injection_held` per case, as today.
- **Lint on every load.** Doing nothing fails. The reference solution and every alternative
  pass. Every wrong solution fails. At least one required rule checks the end state. A mock
  run that replays the reference solution passes, twice identically; a mock that only writes
  text fails. A case that does not hold does not load.

### 5. Targets and engines (through Langertha)

- Every target Langertha speaks is measurable: OpenAI-compatible (llama.cpp, vLLM,
  tensorfold, Skeid), Anthropic, Ollama and more.
- Variants per target (see Language).
- Tokens per case and turn through `Langertha::Usage` (input, output, reasoning), plus the
  number of turns and tool calls, duration, `finish_reason`.
- Parallel runs with a bounded number of concurrent requests per target, `repeat` *n*, and
  resuming aborted runs.

### 6. Report and evaluation

- **JSON report per run:** target, variant, suite version; per case and repetition the
  status, rules with result and reason, diff of the end state, tokens, turns, calls, tags,
  tier.
- **Evaluation per topic, never one percentage over all cases.** An overall value, if any, is
  the mean of the topics — a few hard cases must not drown in many easy ones.
- **Case weights** as in today's core set (see Language).
- **Curves per length tier** (16k, 48k, 96k, 160k): hits, `context_exceeded` and errors
  apart.
- **Comparison of several targets** as a table: row = target and variant, column = topic. As
  text, Markdown and JSON.

### 7. Command line

Working names, not fixed: `holmgang lint <suite>`, `holmgang run --suite … --target …
--variant … --repeat 3 --report out.json`, `holmgang report out/*.json --by topic`,
`holmgang export-yaml`. Network-free tests for everything that works without a model.

### 8. Categories it must carry

| Category | Core of the check |
|---|---|
| Operations (core) | faults on simulated servers, networks, Kubernetes, databases; end state |
| Injection | foreign content carrying instructions; forbidden calls |
| Long context | long logs, manifests, contradicting runbooks; many turns with big results; length tiers |
| Contract check | statute text (~100k tokens) in context, clauses as parallel yes/no calls |
| Layer faults | PHP → HTML → JS → fetch → PHP/SQL; cause and symptom in different layers |
| Bullshit | recognise a nonsensical premise (after BullshitBench, MIT) |
| Translation | fidelity at checkpoints: numbers, negation, modality, codes, glossary |
| Reasoning | procedural tasks (after Reasoning Gym, Apache-2.0), three difficulty levels |

## What it does not cover

- No judge model, no rubrics, no free-text comparison.
- No general knowledge tests (MMLU and the like) and no public leaderboards.
- No platform functions: no database, no web UI, no users or permissions, no model catalogue.
  That stays in cai-platform, which embeds Holmgang and stores and shows the reports.
- No real devices. Holmgang never runs commands on real systems, only in the simulation.
- No training, no fine-tuning, no RL environment. Generators serve measuring only.
- No cases in this repository (ADR 0003).

## Engine and cases apart (ADR 0003)

- **`Langertha-Holmgang` (public, CPAN):** DSL, YAML loader, runner, grading, lint, report,
  simulators, generator scaffolding and a handful of **example suites** to learn from — small,
  deliberately no real measurement cases.
- **Cases private** in their own repository (working name `cai-bench-suites`). Public cases
  with their solutions land in the training data of the next models; after that the test
  only measures memorisation.
- **Generated suites:** the generator may be public, the seed for our own measurement stays
  private.
- **Foreign sources** are named with licence and origin in the suite head: Reasoning Gym
  (Apache-2.0), BullshitBench (MIT), German federal statutes (§ 5 UrhG, official works), GDPR
  from EUR-Lex (reuse with attribution).

## Acceptance

1. All existing format 2 suites from cai-platform load unchanged. Their lint is green.
2. A mock run over all suites gives the same results as today's runner in cai-platform
   (report comparison).
3. One suite is additionally written in the DSL, loads, and gives the same results as its
   YAML version.
4. A real run through Langertha against an OpenAI-compatible target yields tokens per case,
   status `context_exceeded` for a case that is too long, and the evaluation per topic.
5. Tests run without network. The documentation (POD and README) describes the DSL, the
   format, the rules, simulator plugins and the report.

## Migration (in this order)

1. In cai-platform the running suite work is finished and accepted.
2. Holmgang comes to life with the lifted core. Acceptance 1–3 runs against a copy of the
   suites, kept outside this repository.
3. The cases move into the private suite repository.
4. cai-platform depends on Holmgang and keeps only storage, display and the model catalogue.
   All tests are green in both repositories.
5. Measurements run through `holmgang run` from then on.
