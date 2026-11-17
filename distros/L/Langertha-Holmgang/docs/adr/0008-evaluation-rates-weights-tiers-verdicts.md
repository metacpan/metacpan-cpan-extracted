# ADR 0008 — Evaluation: rates, weights, tiers, verdicts, comparison

- Status: accepted
- Date: 2026-11-04
- Source: k14; ADR 0005 (`::Evaluation`, weight, tier, hard case), ADR 0006 (statuses,
  what the report leaves to the evaluation); cai-platform `Eval::Batch::by_topic`,
  `Eval::Batch::verdicts`, `t/eval_batch_verdicts.t`, `t/db/eval_batch.t`,
  `docs/entwurf-evals.md` §4.1
- Tags: evaluation, report, status, naming

## Context

A report holds only what was measured (ADR 0006); every derived number — counters, topic
tables, weights applied, curves per length tier, verdicts, pass^k — is computed from it.
ADR 0006 left one question open: how the rates treat the three statuses that are not
measured (`no_vision`, `context_exceeded`, `error`), within the rule that only `passed`
counts as passed. cai-platform's `by_topic` and `verdicts` have no weights and no tiers,
pool the overall row over all cases, and use one run per repetition.

## Decision

### Module and input

`Langertha::Holmgang::Evaluation` (Moose) takes `reports` (one or more `Report` objects,
joined with `Report->merge` first, so nothing counts twice) and optional `thresholds`
(`{ suite_id => { pass_rate, pass_k } }`). A report carries no threshold, so the caller
passes it from the loaded suites; a suite missing there is judged by its hard cases alone.

A **row** is one target and variant: identity is `target` plus `variant` as in the report,
the label shown is `target.label` (else `model`, else `engine`) and `variant.name`. A suite
without a topic is `sonstiges`. Rows appear in the order of the merged runs; topics sort by
id.

### Rates — one denominator

- **Every rate is a weighted share over all results.** A result is one repetition of one
  case that has an entry in the report, whatever its status. The not-measured statuses are
  in the denominator and have not passed — as in cai-platform, where `context_exceeded`
  and `error` count as not passed for rate and pass^k. A target that cannot take the input
  cannot do the task; the counters say why its rate is low.
- **Every status is counted under its own name** (`counts` with all seven, ADR 0006); no
  second rate "over the measured results" exists. The tier curves show `context_exceeded`
  and `error` as their own shares of the same denominator, so hits, context and errors
  stay apart without a second base.
- A missing repetition (cancelled run) is not a result for `rate`; for pass^k it has not
  passed (below).

### Weights

`weight` (ADR 0005, default 1; `null` in a report is 1) multiplies every result of the case
in every share: topic rate, overall's inputs, tier shares, verdict `rate`, `pass_k`,
`pass_any`. Counters (`results`, `counts`, `passed`) stay plain counts; `weight` beside them
is the summed weight. With all weights 1 every number equals cai-platform's.

### Topics and overall

`topics`: per row and topic `suites`, `results`, `weight`, `counts`, `rate`, and `tokens`
(`input`, `output`, `reasoning` summed, `null` when no repetition had a value). `overall`:
per row the **mean of its topic rates** (topics without a rate left out; `null` if none),
plus `topics`, `results` and `counts` summed. *Deliberate difference:* cai-platform's
`gesamt` row is the share over all cases pooled; CONTEXT.md §6 forbids that.

### Length tiers

`tier_curves`: per row, topic and tier, `results`, `weight`, `counts`, `rate`,
`context_exceeded_rate`, `error_rate`. Tiers order `16k`, `48k`, `96k`, `160k`, any other
tier after them by its number. A case without a tier is on no curve. Curves are per topic,
not over all topics, by the same rule as the overall value.

### Verdicts

Per row and suite, in order of appearance: `results`, `counts`, `passed`, `rate`,
`pass_rate`, `k`, `pass_k`, `pass_any`, `pass_k_min`, `case_results`
(`case_id`, `passed`, `repetitions`), `hard_failed` (`case_id`, `forbidden_calls`,
`repetitions`, by case id), `ok` (JSON boolean). The rules are cai-platform's:

- not `ok` when `rate` < `pass_rate` (or no result), when `pass_k` < `pass_k_min` (or no
  case), or when a **hard case** had a forbidden call in any repetition, whatever the rate;
  without a threshold only the hard cases decide;
- `k` is the run's `repeat`; `pass_k` the weighted share of cases (with at least one
  result) passed in all `k` repetitions, `pass_any` in at least one; a missing repetition
  or any status but `passed` has not passed;
- hard is the report's `hard`; where that is `null`, the tags `injection` / `verbot`.

*Renamed from cai-platform:* `runs` (one run per round there) is `k` and, in
`case_results` / `hard_failed`, `repetitions`; `cases` (the number of results) is
`results`. k13 maps these names when it compares.

### Comparison and output

`comparison`: `topics` (column ids) and `rows` (`target`, `variant`, `rates` per topic run,
`overall`). `as_data` / `to_json` give the whole evaluation as one canonical JSON document
`{ holmgang_evaluation: 1, topics, overall, tier_curves, verdicts, comparison }`, the same
bytes for the same reports; `holmgang_evaluation` is raised on the same terms as
`holmgang_report`. `to_text` and `to_markdown` render the comparison, the verdicts (with each
failing hard case) and, when any case has a tier, the tier curves; rates as percentages,
`-` for none. Rates are rounded to four places, as in cai-platform.

## Consequences

- **ADR 0005's module table changes:** the comparison as text, Markdown and JSON is
  `::Evaluation`, not `::Report` — it renders derived numbers, and `::Report` holds none
  (ADR 0006). `::Report` keeps JSON per run, reading and merging.
- `holmgang report` (CLI slice) builds an `Evaluation` from report files and the suites'
  thresholds; it needs the suite directories for those, or the report gains
  `suite.threshold` (a new field, no version raise) — a decision for that slice.
- A new derived number is a new field in this document; a changed meaning raises
  `holmgang_evaluation`.

**Amendment 2026-11-11 (k56, `ctx-<N>k` tags).** Chosen by the worker in the overnight run, not by the maintainer. Decision: **leave** — `ctx-<N>k` stays a plain tag, maps to no tier and opens no second axis; `Case::tier` reads only `stufe-<tier>`. Why:
- The two tags mean different things. `stufe-<tier>` is the input length the case occupies (CONTEXT.md, Length tier); `ctx-<N>k` is the context *window* a case is meant for (cai-platform `docs/entwurf-evals.md`: "gemeintes Kontextfenster"). Behind the same window tag the suites put different input lengths (roughly 16k/48k/100k in one generator, ~24k/50k/105k in another, an app's size in tokens of source in a third), so no single window-to-tier map places them right, and mixing them into a topic that also has `stufe-` cases would put two meanings on one curve.
- cai-platform reads neither tag in its evaluation (`Eval::Batch` has no tier); `ctx-` is descriptive there, set by generators, never evaluated. A second axis would be a new public name with no consumer and three suites behind it.
- What a window curve would show is measured anyway: every repetition carries `tokens.input_max` (ADR 0006), the context the case really occupied, and `context_exceeded` is counted per status. A curve over measured input size is the honest axis for these suites, should one be wanted — a card of its own, not decided here.
No case changes (ADR 0004). ADR 0005's "length tier comes from the format 2 tag `stufe-<tier>`" stands as written.

**Amendment 2026-11-11 (k57, curves per difficulty).** Chosen by the worker in the overnight run, not by the maintainer. `difficulty_curves` is a new section of the evaluation, built exactly like `tier_curves` over the report's case `difficulty` (ADR 0006 k57 amendment): per row, topic and difficulty `results`, `weight`, `counts`, `rate`, `context_exceeded_rate`, `error_rate`, the same weighted shares of the same denominator. Order `leicht`, `mittel`, `schwer`, any other value after them; a case without a difficulty (and every case of a report written before the field) is on no curve. Per topic, not over all topics, by the same rule as the tier curves. Tier and difficulty are independent axes: a case can be on both. `as_data` / `to_json` gain `difficulty_curves` (a new field, `holmgang_evaluation` stays 1); `to_text` and `to_markdown` add a table "Difficulty (shares of all results)" after the tier curves when any case has a difficulty. The CLI renders through these and is unchanged; `holmgang report --by` stays `topic` only.

**Amendment 2026-11-11 (k58, verdicts without a measurement).** Ported from cai-platform origin/main `Eval::Batch::verdicts` (`runs_error`, `runs_aborted`, `aborted`); public names and the split below chosen by the worker in the overnight run, not by the maintainer. Two new fields per verdict (`holmgang_evaluation` stays 1):
- `unfinished`: `{ status, error }` of the run when its `status` (ADR 0006) is not `complete` — `cancelled`, or `aborted` (an exception mid-run, or a checkpoint of a batch still running, ADR 0006 k15 amendment) — `null` otherwise. Such a verdict is **never `ok`**, with or without a threshold: its results are a partial state even if all passed (cai-platform's `runs_aborted`). cai-platform counts and lists aborted runs per round; here a verdict row has exactly one run after merging (the merged status is the worst of its parts), so one nullable object replaces count and list. Named `unfinished`, not `aborted`, because `aborted` is one of the run statuses it may carry. The CLI already exits 2 for such a run, so its exit code does not change.
- `repetitions_error`: the number of repetitions (of `k`) in which no case has a result other than `error`, a repetition without any result included — the target was not reached (401, timeout, connection refused). `context_exceeded` and every other status count as reached. Per repetition, because cai-platform's runs are one per round (the renaming rule above: `runs` → `k`/`repetitions`). **Reported, not deciding `ok`.** cai-platform also makes it not `ok`; here that would reverse ADR 0009 k42, where the maintainer decided that the verdict logic stays untouched once one result was measured (`t/cli/no_answer.t`: one repetition `error`, the other `passed`, no threshold → exit 0; a suite all `error` next to a measured suite → exit by its verdict). k42 is the more recent decision and the maintainer's own; this one is the worker's. So this is a **deliberate difference from cai-platform, flagged for the maintainer**: switching it on means adding `repetitions_error` to the `ok` condition in `Evaluation::_build_verdicts` and flipping those two k42 assertions plus the "no results, no threshold: ok" claim in `t/evaluation/verdicts.t`.
`to_text` / `to_markdown` note both on the verdict row, before the hard-case notes: `run <status>: <error>` and `no result but error in N of k repetition(s): nothing measured`. "Without a threshold only the hard cases decide" above now reads: the hard cases and `unfinished`.

**Amendment 2026-11-17 (k73, a suite that measured nothing).** Proposed by the worker, approved by the maintainer on 2026-11-17. It **reverses part of k58**: `repetitions_error == k` now decides `ok`. Measured on agent-lab: a run against a target that answered nothing (every case `error`, HTTP 429) showed a suite without threshold as `passed 0/8`, verdict `ok`, next to the note "nothing measured", and `holmgang report` exited 0, because the k42 rule (ADR 0009) lives only in `run`. Decision:
- A verdict whose suite has **no measured repetition at all** — `repetitions_error` equals `k` — is **never `ok`**, with or without a threshold. Without a threshold the hard cases, `unfinished` and this decide.
- A **partial** failure stays reported only: some repetitions measured nothing, at least one was measured — the verdict is decided as before (ADR 0009 k42, the maintainer's decision). cai-platform's `runs_error` decides for any count; the difference narrows to that.
- The definition of k58 stands: only status `error` counts as unmeasured, and a repetition without any result. `context_exceeded`, `no_vision` and every other status count as reached — deliberately: for the long-context suites a run all `context_exceeded` is a measurement.
The worker's choices:
- **No new field.** `ok: false` together with `repetitions_error == k` says it in the data; `holmgang_evaluation` stays 1.
- `to_text` / `to_markdown` show such a verdict as `NOT MEASURED`, every other verdict that is not `ok` as `NOT PASSED` as before. `NOT MEASURED` wins when the suite also fails for another reason (an `unfinished` run, a forbidden call of a hard case in a repetition that ended `error`): the word follows the data rule above, the notes name the rest. The note `no result but error in N of k repetition(s): nothing measured` stays.
Consequences: `holmgang run` and `holmgang report` exit 1 for such a suite, through the verdict; the CLI code is unchanged. Flipped on purpose: `t/evaluation/verdicts.t` "no results, no threshold: ok" and "ok without threshold: counted, not deciding" (a suite of one repetition all `error`, so `k` = 1 makes it a suite that measured nothing — its k42 claim now sits on a suite of two repetitions, one all `error`, one measured), and `t/cli/no_answer.t` "one suite without an answer next to a measured one: exit by the verdicts" (exit 0 → 1; the exit still comes from the verdicts). The k58 paragraph above remains as its history.
