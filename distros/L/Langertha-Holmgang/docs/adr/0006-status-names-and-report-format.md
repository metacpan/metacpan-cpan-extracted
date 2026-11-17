# ADR 0006 — Status names and report format

- Status: accepted
- Date: 2026-11-04
- Source: karr k11; k27 (status `no_vision`, no images in reports); cai-platform at
  `af7561a5`: `Eval::Grader::grade`, `Eval::Runner::run_case`, `Eval::Batch`,
  `CLI::Command::Evals::Run` (`--report`), `t/eval_context_exceeded.t`
- Tags: report, status, grading, runner

## Context

cai-platform knows four case statuses on the wire (`passed`, `failed`, `ungraded`, `error`)
plus `context_exceeded`, added later. Hitting `max_turns` is not a status there: the
grader appends a synthetic, failed rule of kind `turns`, the case becomes `failed` or
`ungraded`, and a separate flag `exceeded` marks it. Its `--report` JSON nests one run per
repetition, per-case numbers (`prompt_tokens`, `completion_tokens`, `prompt_tokens_max`,
`turns`, `duration_ms`, `tool_calls` as a count, `sim_gaps` as bare strings,
`forbidden_calls`, `injection_held`) and derived numbers (`topics`, `verdicts`, counters,
`usage`); rules and the end-state diff live only in the database. k27 adds a target that
cannot see images. The report slice (k12), the runner (k9), the evaluation (k14) and the
acceptance comparison against cai-platform (k13) all need fixed names first.

## Decision

### Statuses

Seven wire names. The first that applies wins:

| # | Wire name | When | Class |
|---|---|---|---|
| 1 | `no_vision` | the case carries an image and the target cannot see it: the capability check, an error signature ("image input is not supported", "not a multimodal model"), or the suite's sight test found the image dropped (k27) | not measured |
| 2 | `context_exceeded` | the target rejected a request because it exceeds its context window | not measured |
| 3 | `error` | the target did not answer for any other reason | not measured |
| 4 | `turn_limit` | `max_turns` model calls without an answer free of tool calls | graded |
| 5 | `passed` | every required rule met | graded |
| 6 | `uncertain` | a required rule missed, a `sim_gap` was hit (in a call or in a rule's check), and no call was forbidden | graded |
| 7 | `failed` | a required rule missed | graded |

- **`turn_limit` is a status of its own.** The rules are still graded and reported as they
  stand at the end state, but no synthetic rule is added; a turn limit is never `passed`,
  `failed` or `uncertain`, with or without a gap.
- `ungraded` is renamed `uncertain`. A forbidden call still makes a missed case `failed`,
  never `uncertain`; a passed case stays passed whatever gaps it hit.
- **Every status is counted under its own name** in every aggregate; none is folded into
  another (cai-platform folds `exceeded` into `failed`/`ungraded`). Only `passed` counts as
  passed — for pass^k too, as in `Eval::Batch::verdicts`. How the rates treat the three
  "not measured" statuses is k14's to fix, within that rule.
- The sight test of k27 is a pre-check per target and suite, never a graded case.

### Report

One JSON document per invocation, UTF-8, `JSON::MaybeXS` with `canonical`, booleans as
`true`/`false`. Every field below is always present; an unknown value is `null`, never
absent and never `0`. The same mock run gives a byte-identical report apart from the fields
marked *volatile*.

```
{ "holmgang_report": 1,
  "generator":   { "holmgang": "<version>", "langertha": "<version>" },   volatile
  "started_at":  ISO-8601, "finished_at": ISO-8601,                       volatile
  "runs": [ <run>, … ] }

<run> = {
  "target":  { "label", "engine", "model", "url" },
  "variant": { "name", "settings": { … } },
  "suite":   { "id", "version", "topic", "digest" },
  "repeat":  n,
  "status":  "complete" | "cancelled" | "aborted",
  "error":   text | null,
  "cases":   [ <case>, … ] }                     in the suite's load order

<case> = {
  "case_id", "title", "tags": [ … ], "tier", "weight",
  "hard": bool, "untrusted": bool,
  "repetitions": [ <repetition>, … ] }           repetition 1..n

<repetition> = {
  "repetition": i, "seed": int | null,
  "status": <wire name>, "score": 0..1, "error": text | null,
  "finish_reason": text | null,                  of the last model response
  "duration_ms": int,                            volatile; sum over the turns
  "rules": [ { "title", "kind", "required": bool, "passed": bool,
               "reason": text, "sim_gap": text | null } ],
  "diff":  [ { "path", "before", "after" } ],    end state against initial state
  "turns": [ { "input_tokens", "output_tokens", "reasoning_tokens",
               "duration_ms", "finish_reason", "calls": n } ],
  "tokens": { "input", "output", "reasoning", "input_max" },
  "calls": [ { "tool", "args", "succeeded": bool, "sim_gap": text | null } ],
  "sim_gaps": [ { "call", "tool", "gap" } ],     call = 0-based index into calls
  "forbidden_calls": int,
  "injection_held": bool | null,                 null without untrusted content
  "transcript": [ … ] | null }                   only on request, otherwise null
```

- **`holmgang_report`** is the format version: an integer, raised on any change a reader of
  the old version would misread (rename, removal, changed meaning). New fields do not raise
  it; readers ignore fields they do not know and refuse a higher version.
- **One run** = one target and variant over one suite with its *n* repetitions (CONTEXT.md);
  the repetitions sit under each case, not in sibling runs. A resumed run fills in the
  repetitions that lack a result.
- **Tokens** come from `Langertha::Usage` per turn: `input_tokens`, `output_tokens`,
  `reasoning_tokens`, each `null` when the target sent none. `tokens` sums the turns per
  field (`null` when no turn had a value); `input_max` is the largest `input_tokens` of one
  turn — the context the case occupied. A turn that hit no target (`no_vision` from the
  pre-check) does not appear in `turns`.
- **The report holds no derived numbers** beyond `score`, `tokens` and the call indices:
  counters, topics, weights applied, curves per tier and verdicts are computed from the runs
  by `holmgang report` (k14), so merging several report files cannot double-count.
- **`tier` and `weight`** are the case's fields as ADR 0005 defines them (`null` / its
  default when the case has none).
- **`target`** never carries a key, a token or credentials in `url`; error texts pass the
  engine's scrubbing first.
- **No image content in a report** — not as base64, not as a `data:` URL. Wherever a message
  with an image appears (`transcript`), the image is `{ "image", "sha256", "bytes" }` (k27).
- `transcript` keeps the messages and tool results without the system prompt, the
  `untrusted` mark stripped as on the wire; the switch that turns it on belongs to k12.
- A report of a private suite is as private as its cases (ADR 0003): rule titles, diffs and
  arguments quote the case. Reports are written outside the checkout, never as fixtures.

### Mapping from cai-platform's `--report`

For the acceptance comparison (k13). cai-platform rows with the same target and suite, in
start order, become repetitions 1..n of one run.

| cai-platform | Holmgang |
|---|---|
| status `passed` | `passed` |
| status `failed` or `ungraded` with `exceeded: true` | `turn_limit` |
| status `ungraded` | `uncertain` |
| status `failed`, `error`, `context_exceeded` | same name |
| — | `no_vision` (no counterpart; k13 compares no case with images) |
| `score` | `score`, after dropping the rule of kind `turns` and recomputing |
| `turns` (count) | number of `turns` entries |
| `prompt_tokens`, `completion_tokens`, `prompt_tokens_max` | `tokens.input`, `tokens.output`, `tokens.input_max`; missing usage there is `0`, here `null` |
| `tool_calls` (count) | number of `calls` entries |
| `sim_gaps` (strings) | `sim_gaps[].gap` |
| `forbidden_calls`, `injection_held`, `duration_ms` | same |
| grading JSON in the database: `rules[].detail`, `required`/`passed` as 0/1, `diff` | `rules[].reason`, booleans, `diff` |
| `target` (label or model), `suite_id`, `topic` | `target.label`, `suite.id`, `suite.topic` |
| `cases_*`, `usage`, `topics`, `verdicts`, `repeat_by_suite` | derived by `holmgang report`, compared there |

k13 compares per target, suite, case and repetition: status after the mapping, each rule's
`passed`, `forbidden_calls`, `injection_held`, and the `sim_gaps` count. Against a mock
target everything else except `duration_ms` must match too; against a real target tokens
and finish reasons are reported, not compared.

## Consequences

- The runner (k9) records per turn and per call, not just sums; `turn_limit` is decided in
  the runner, the grader no longer appends a rule for it.
- Code that compares statuses with cai-platform's names (`ungraded`, the `exceeded` flag)
  goes through the mapping above, never through aliases in the report.
- A new status needs an ADR and raises `holmgang_report` — an old reader would count it
  wrong. `no_vision` is part of version 1 from the start, before k27 lands.

**Amendment 2026-11-04 (k14).** How the rates treat the not-measured statuses is fixed in ADR 0008: every result is in the denominator, only `passed` passes, each status keeps its own counter.

**Amendment 2026-11-05 (k38).** Langertha has no scrubbing of its own yet (langertha k389); until it does, "the engine's scrubbing" for error texts is `Langertha::Holmgang::Target::scrub` (ADR 0005, k38), which every repetition's `error` passes. A run-level `error` (k15) goes through the same method.

**Amendment 2026-11-05 (k13).** Acceptance 2 ran against the copy af7561a5: cai-platform's `Eval::Runner::run_case` against `Eval::FakeTarget` (in-process, no database), repeat per suite with the round as seed, and `holmgang run --target mock-solution|mock-text` over the same suites, both modes. Per suite, mode, case and repetition the statuses, scores, rules, diffs, calls with arguments and gaps, `sim_gaps`, `forbidden_calls`, `injection_held`, turns and errors are identical, and so are the counters, the verdicts and the rate per topic. What "everything else must match" above does not hold for, all deliberate: rule `reason`s are English here, German there (`Grader`, k2 — identical after translating cai-platform's fixed phrases); `tokens` are `null` (the mock estimates none, ADR 0005 k9); `seed` is `null` for a suite with `repeat` above 1 (the CLI sends none, ADR 0009); the overall rate is the mean of the topic rates, not cai-platform's pooled share (ADR 0008). `t/acceptance_mock_runs.t` repeats the per-repetition comparison against a stored cai-platform baseline (`HOLMGANG_ACCEPTANCE_BASELINE`, kept outside the checkout like the suites) and skips without it.

**Amendment 2026-11-11 (k30).** `suite.digest` stays the field name, and it is now the only name: the suite attribute it comes from and the key of `Loader::list` are `digest` too (ADR 0005, k30), so the value carries one name from the loader to the report.

**Amendment 2026-11-11 (k27, `no_vision` and the sight test).** Chosen by the worker in the overnight run, not by the maintainer; the card's clarification (2026-11-04) fixes that the sight test is a pre-check, not a graded case, and that Langertha's `image_input` and `probe_model_capabilities_f` replace an own `/props` query.
- **Where.** `Target::vision_check_f` is the pre-check of one target; the CLI runs it once per suite that has a case with images, before the suite's cases (not per repetition), prints `<suite> vision check: seen (…) | no_vision -- <reason> | not ruled out -- <note>`, and passes the reason to every case (`Runner::run_case_f` option `no_vision`). Cases without images in the same suite run as usual — `no_vision` is per case with an image (row 1 above), not per suite.
- **Order, first decision wins.** (1) The wire: an engine that does not compose `Langertha::Role::ImageInput` → `no_vision` (a plain `Langertha::Engine::Virtual` is the "mock without vision"). (2) `probe_model_capabilities_f` (a no-op without a metadata endpoint; a failure decides nothing): a learned `image_input => 0` for the engine's `chat_model` → `no_vision`. A static "no claim" decides nothing, because Langertha clears `image_input` for every self-hosted server (vLLM, llama.cpp before the probe) and gateway — treating that as blind would make every self-hosted target `no_vision`. (3) The sight test.
- **The sight test** sends two requests through `chat_turn_f` (the variant applies, `max_tokens` 16): a fixed short text, then the same text with `sight_test_image`, a 512×512 grey checkerboard PNG built in memory. If the image request fails with a `no_vision` signature → `no_vision`. If the image adds fewer than `sight_test_min_tokens` (200, the card's number) input tokens → `no_vision` ("the target drops the image"). The difference of two requests rather than the absolute `prompt_tokens` of one, because a chat template's own preamble can exceed 200 tokens and hide a dropped image; 512×512 so that common vision models spend well above 200 on it (Gemma 3 and InternVL 256, Qwen2.5-VL about 324, LLaVA 576, Pixtral 1024). Known limit: a model that encodes such an image in fewer than 200 tokens (MiniCPM-V style 64-token slices) would be called blind. A target without usage, or a request failing otherwise, decides nothing; the cases then run and show what they get.
- **Report.** The sight test is no case and leaves no repetition; a `no_vision` repetition has the reason as `error`, `turns: []`. A transcript keeps the placeholder `{ image, sha256, bytes }` in the message's `content` list after `{ type: text }`, as above.

**Amendment 2026-11-11 (k15).** A run-level `error` of a batch goes through `Target::scrub`, as the k38 amendment demands, and is cut at 2000 characters; so is every repetition's `error` (ADR 0005 k15 amendment). Run `status` gets no new wire name: a report written while a batch still runs (a checkpoint) has its unfinished runs as `aborted` with the error `unfinished: the batch was still running when this report was written`, a run cut off by a cancel is `cancelled`. A resumed run fills in the repetitions that lack a result and takes the status of the run that resumed it. Chosen by the worker in the overnight run.

**Amendment 2026-11-11 (k57, `difficulty`).** Chosen by the worker in the overnight run, not by the maintainer. `<case>` gains `"difficulty"`: the case's `difficulty` as format 2 writes it (`leicht` | `mittel` | `schwer`), `null` without one; `Case::report_meta` carries it, `Report::add_run` copies it. A new field, so `holmgang_report` stays 1. Unlike every other field it may be **absent** when a report is read — reports written before it came stay readable and read it as `null` (the reader's field spec marks it `optional`; every other field is still required). `Report::merge` takes a `null` difficulty on one side as the other side's value, so an older report merges with a newer one of the same run; two different values still croak as differing case meta. `from_cai_platform` takes `difficulty` from each case row of cai-platform's `--report` (it writes one there), falling back to `suites.<id>.cases.<case>.difficulty`. The field is a plain text, not an enum: the loader enforces the three values, and the reader stays as open as for `tier`.

**Amendment 2026-11-11 (k58, acceptance on cai-platform origin/main).** Acceptance 1 and 2 ran again on a new copy outside the checkout, `git archive` of cai-platform origin/main 993637ab, with a baseline made by cai-platform's own code on that copy (the k13 driver, unchanged: `Eval::Runner::run_case` against `Eval::FakeTarget`, repeat per suite, round as seed). cai-platform's loader sees 36 suites and 708 cases; Holmgang loads the same 36 with lint green and the same 708 cases (the `pii-*` corpus left out as before; a directory without `suite.yaml` is no suite in either). Per suite, mode (`solution`, `text`), case and repetition everything k13 compares is identical, over all 72 suite × mode pairs; the denken checkers agree with cai-platform's Python vectors of that commit. Decisions on cai-platform's eval-core changes since af7561a5, by the worker in the overnight run:
- `Eval::World` (a dying simulator becomes a gap, the model gets no Perl text): Holmgang has had this since k32, with its own wording, kept: the model gets `Fehler: interner Fehler beim Ausführen des Aufrufs.` where cai-platform sends an empty output, and the gap is `simulator error: <text>` where cai-platform writes `<tool>: interner Fehler: <text without directories>`; Holmgang also replaces a Perl error line a simulator caught and returned. Both keep the state and fail the call. A case that hits a dying simulator would differ in the tool output and the gap text; none of the 708 does in either mode (no gap at all in the baseline).
- `Eval::Batch::verdicts` (`runs_error`, `runs_aborted`): ported as `unfinished` and `repetitions_error`, see ADR 0008 k58 amendment — `repetitions_error` deliberately does not decide `ok` (ADR 0009 k42).
- `Eval::Batch::run`, `Eval::Runner` key handling (tester tokens, `api_key` only in memory): cai-platform's database and catalog; Holmgang stores no key anywhere (ADR 0009) — not ported.
- `Eval::Runner::_nul` (NUL to U+FFFD before storing): PostgreSQL cannot hold NUL; Holmgang writes JSON, where NUL round-trips as `\u0000` — not ported, the text the model wrote is kept as it is.
- `Eval::FakeTarget` (recognise the case by all leading user messages, not the first): Holmgang's mock engine is built per case (`Runner->mock_engine`), there is no lookup to get wrong — not ported; the baseline was made with cai-platform's fixed lookup.
- `Eval::Suite`: the excerpt part `auszug` is k52; the topic title `Übersetzung` is display text of cai-platform's tables — Holmgang reports topic ids and has no titles — not ported.

**Amendment 2026-11-17 (k17, acceptance 4).** Real runs from agent-lab, Holmgang 84a8736 as checked out there, the suites read in place from cai-platform (`share/evals`), reports kept outside the checkout (`~/holmgang-abnahme/scratch/k17`). Tokens per case and per turn, and the evaluation per topic and difficulty: a run against cortex (TensorFold, OpenAI-compatible, `Qwen3.8-Flash-Next`) over two suites, concurrency 4. `context_exceeded`: cortex's 262k window holds even the 160k tier, so the case went to synapse (`qwen3.8-flash`, llama.cpp behind Skeid, 131072 tokens per slot), `--target OpenAI`, concurrency 1. The run was an excerpt of `langkontext-stufen`: the 16k and 160k cases of the three families that carry their long input in the task. The 160k cases all came back as `context_exceeded` within 2.5–3.1 s (llama.cpp rejects before prefill: `request (N tokens) exceeds the available context size (131072 tokens)`, matched by `Target`'s context pattern unchanged), with tokens `null`. The 16k cases were measured, with tokens per turn; reasoning tokens were `null` because llama.cpp reports none. The tier curve shows 160k at 100 % `context_exceeded`, 16k at 0 %. The run's exit 1 came from the verdict (below the suite's threshold), as ADR 0009 says. Measured, for whoever reads the tier names: with this tokenizer the "160k" cases are 169k–245k input tokens and the "16k" cases start at 17k–25k. The tier tag is approximate by design (ADR 0008's note on measured input size). A run against OpenAI's API got only 429 (no credits) for every case: exit 1 by ADR 0009 k42, and the verdict finding became k73.
