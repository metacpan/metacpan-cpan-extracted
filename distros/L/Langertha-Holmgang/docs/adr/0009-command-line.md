# ADR 0009 — The `holmgang` command line

- Status: accepted
- Date: 2026-11-05
- Source: k21; CONTEXT.md §7; ADR 0005 (`bin/holmgang`, `::CLI`), ADR 0006 (report),
  ADR 0008 (evaluation, thresholds left to this slice); cai-platform at `af7561a5`:
  `CLI::Command::Evals::Run`
- Tags: cli, naming, runner, report

## Context

CONTEXT.md §7 names working commands: `holmgang lint <suite>`, `holmgang run --suite …
--target … --variant … --repeat 3 --report out.json`, `holmgang report out/*.json --by
topic`, `holmgang export-yaml`. cai-platform's `evals run` is a `MooseX::App` command over
its database, takes an OpenAI-compatible `--base-url` and `--model`, reads the key from a
`--key-file`, and ends with code 1 when a verdict fails. Holmgang has no database, speaks
every Langertha engine, and has no `::Batch` yet (k15: variants per target, bounded
concurrency, resume). The choices below are the worker's (k21), not the maintainer's.

## Decision

### Shape

- `bin/holmgang` is a thin script: `exit Langertha::Holmgang::CLI->new->run(@ARGV)`.
  `::CLI` (ADR 0005) is a Moose class with `out` and `err` handles, so the commands are
  tested in process; one test runs the script itself for the exit code.
- Options are parsed with `Getopt::Long` (core, `Getopt::Long::Parser`, no global
  configuration), not `MooseX::App`: the sibling dists' executables (`langertha-skeid`'s
  `bin/skeid`) use `Getopt::Long`, and three commands do not need a framework.
- Commands: `lint`, `run`, `report`, `help` (also `--help`, `-h`). Exit codes, the same
  for every command:

| Code | Meaning |
|---|---|
| 0 | everything loaded / ran, every verdict ok |
| 1 | a suite was refused (`lint`), a verdict is not ok (`run`, `report`), or the target answered no case of the run — every result `error`, `context_exceeded` or `no_vision` (`run`; said on stderr, the report written all the same) |
| 2 | usage or setup error: unknown option or command, missing argument, a path that is no suite, a target that does not build, a report that does not read or write, a run that aborted or was cancelled |

### `holmgang lint <dir>...`

- Each argument is a suite directory (it holds `suite.yaml`) or a search directory (each
  subdirectory with `suite.yaml` is a suite, in name order).
- Lint is the loader (`Loader->load`, lint and both mock runs included): exactly what
  loads passes, nothing else. A refused suite prints the refusal, which names the case
  file and field; the loader stops at the first refused case, and so does `lint` — a
  second check that went on past it would be a lint the loader does not run.
- Output per suite: `ok <id> (<n> cases)` and `  ok <case-id>` per case, or
  `FAIL <id>` and the refusal; a closing count. To standard output.

### `holmgang run`

    holmgang run --suite DIR [--suite DIR]... --target NAME [--model M] [--url U]
                 [--option K=V]... [--label L] [--variant K=V]... [--repeat N]
                 [--report FILE]

- **A target is a Langertha engine name plus constructor options**, no config file:
  `--target OpenAI` is `Langertha::Engine::OpenAI`, a name with `::` is a class name
  as written (loaded at runtime with `Module::Runtime`, the one runtime-plugin case).
  `--model` and `--url` are the engine's `model` and `url`; `--option K=V` passes any
  other constructor argument. A value that parses as JSON (number, `true`/`false`, an
  object, an array) is that value, else the text as given.
- **No key on the command line.** `--option api_key=…` is refused: argv is visible to
  every user of the host (`ps`). The key comes from where the engine reads it
  (`LANGERTHA_OPENAI_API_KEY` and the like) — the CLI reads no key file and no variable
  itself. There is no default target and no default endpoint: without `--target` the
  command refuses; an engine's own default URL is the engine's.
- **Two network-free targets:** `mock-solution` replays each case's reference solution
  (`Runner->mock_engine($case, 'solution')`), `mock-text` answers text only
  (`'text'`); the dash keeps them apart from every engine name. In the report they are
  `target.engine` `Virtual`, `label` the name. They are the dry run of a suite end to end,
  and what the tests run.
- `--variant K=V` (repeatable, values as for `--option`) become `Target::variant`
  settings, unchecked as that attribute is today; the report's `variant.name` is
  `default` without settings, else the sorted `K=V` pairs joined by `,`. Named variants,
  several variants per target and their checks are k15.
- `--repeat N` (1..100) for every suite; without it each suite's own `repeat`, else 1.
  The loop is sequential (one request at a time), repetition outer, cases in load order,
  no seed sent. Bounded parallel requests and resume are k15 (`::Batch`); this loop is
  private to `::CLI` and goes when `::Batch` arrives.
- One report run per suite (ADR 0006), status `complete`; a case that throws (a program
  error, not a target failure — those are statuses) aborts that suite's run: status
  `aborted`, its error through `Target->scrub`, exit 2 after the report is written.
- Output: one line per case and repetition (`<suite> <case> #<n> <status>`), then the
  evaluation as text (`Evaluation->to_text`), the suites' `threshold` as thresholds.
  `--report FILE` writes the report (outside the checkout, ADR 0003).

### `holmgang report <file>...`

- Reads every file (`Report->read`), builds one `Evaluation` and prints it:
  `--format text` (default), `markdown`, `json`.
- `--by topic` is accepted and the only value: the evaluation is per topic (ADR 0008).
- **Thresholds come from the suites, not the report** (ADR 0008's open question):
  `--suite DIR` (repeatable) loads a suite and takes its `threshold`; without it a verdict
  is judged by its hard cases alone. The report format does not change.
- Exit 1 when a verdict is not ok, as `run` and cai-platform's `evals run`.

### Not now

- `export-yaml`: format 2 is YAML already, so the command only makes sense for DSL
  suites (k18 in progress, export k19 backlog). Left out until k19.
- `--transcript` (`Report::with_transcript`), `--topic`/`--all` selection over search
  directories, cancel on a signal (`cancelled`), named variants, parallel runs, resume —
  k15 or later slices.

## Consequences

- New public names: the module `Langertha::Holmgang::CLI` (already in ADR 0005's table),
  the script `bin/holmgang`, the commands, options and exit codes above, the pseudo
  targets `mock-solution` and `mock-text`.
- k15 replaces the private loop with `::Batch` and extends `--variant`; the option names
  here stay unless its ADR says otherwise.
- `Getopt::Long` joins the cpanfile.

**Amendment 2026-11-06 (k42).** Exit 1 also when `holmgang run` measured nothing: every
result of the run is `error`, `context_exceeded` or `no_vision` (the not-measured statuses
of ADR 0006/0008), so no case got an answer from the target. The maintainer decided the
code and that the report stays exactly as it is; stderr gets
`holmgang: no case got an answer from the target (<n> <status>, …)`, the verdict logic
is untouched once one result was measured — `failed`, `uncertain` and `turn_limit` are
answers. The worker's choices: it is judged **over the whole run**, all suites and all
repetitions together, not per suite; a suite whose results are all unanswered next to a
measured one gets only a stderr note (`holmgang: suite <id>: no case got an answer from
the target (…)`), the exit code then comes from the verdicts. An aborted run stays 2,
checked first. An empty suite cannot reach the run: the loader refuses a suite without
cases (`cases: no cases`), so it is a setup error, exit 2, not a run without answers.
The engine's warnings while it is built (a notice about a setting it drops) are caught
and written to stderr as `holmgang: <text>`, cleaned like a relayed error (k41).
`Target::_strip_location` and World's Perl-error line share one location rule,
`$Langertha::Holmgang::Target::LOCATION`, which also covers Perl's `, <FH> line N` /
`chunk N` suffix.

*Note 2026-11-17 (k73).* A suite whose results are all `error` next to a measured one now
fails its verdict (ADR 0008 k73 amendment, `NOT MEASURED`): it keeps its stderr note, and
the exit code, still from the verdicts, is 1. A suite all `context_exceeded` or
`no_vision` still gets only the stderr note — those are measurements. `holmgang report`
has no no-answer rule of its own; a report whose results are all `error` exits 1 by the
same verdict.

**Amendment 2026-11-08 (k44).** The exit-code table at the top now carries the k42 rule;
the amendment above stays as its history. The maintainer decided that the run's
no-answer note quotes the first error text, cleaned as the target cleans it, on one line,
cut to about 200 characters with a visible ellipsis, the counts kept:
`holmgang: no case got an answer from the target (2 error); first: HTTP 401 Unauthorized …`. The
worker's choices: the text is the result's `error` as `Target::chat_turn_f` stored it,
already through `scrub` with the engine's key, so the CLI does not scrub it again; its
whitespace runs collapse to one space; past 200 characters it is cut there, trailing
space dropped, and ` …` (U+2026) appended. "First" is the first result in suite order,
then case order, then repetition order — the first result the run produced, since the
first case of the first repetition comes first in both orders; a result without error
text is passed over, and with none the note has no `; first:` part. World's handler
changes cut a trailing die location with the same `$LOCATION` rule (no cycle: Target
loads no Holmgang module); since k29 the haystack throws a `Langertha::Holmgang::Error`
with no location, so Structure does not use the rule.

**Amendment 2026-11-11 (k15).** The private loop of `holmgang run` is gone; the command builds a `::Batch` (ADR 0005 k15 amendment) with its one target. Chosen by the worker in the overnight run, not by the maintainer; the option names above stay:

- **`--variant`** takes `K=V` as before — the pairs of the one unnamed variant, named by its sorted pairs (`default` without any) — and `NAME:K=V`, a pair of the variant `NAME`; `NAME:` names a variant without settings. A name is `[A-Za-z0-9][A-Za-z0-9_.+-]*`; since a key cannot hold a colon, `K=V` with a colon in the value stays a pair. Variants run in the order first named, the unnamed one first; a name used twice is refused. The settings are checked and normalised (`Target::check_variant`): the variant's name in the report is built from the normalised values (`enable_thinking=off` reads `enable_thinking=false`), and what the engine would drop is refused as a setup error, exit 2. `chat_template_kwargs=…` and other raw `chat_f` options are no longer accepted; `enable_thinking=on|off` replaces the former. With several variants every output line starts with the variant name.
- **`--concurrency N`** (1..64, default 1): at most N requests open against the target. A real engine is built once per slot from the same `--target`/`--model`/`--url`/`--option` (its build notices are said once); the mocks build their engine per case as before.
- **`--resume FILE`**: the report of an earlier run of the same command; its results are taken over and only the missing repetitions run (refusals of `::Batch` — another `--repeat`, a changed suite, a run not covered — are exit 2). `--report` may name the same file.
- **Checkpoints.** With `--report`, the report is also written while the batch runs, after a result once `checkpoint_seconds` (a `::CLI` attribute, default 10, not an option) have passed since the last write; a checkpoint that cannot be written is said once on stderr and the run goes on. So a run killed mid-way leaves a report that `--resume` continues.
- **Cancel on a signal.** SIGINT or SIGTERM cancels the batch: stderr says so, no further case starts, the cases in play finish, the report is written with the run `cancelled`; a second signal ends the process at once (the default action). A cancelled run exits **2**, like an aborted one: the table row now reads "a run that aborted or was cancelled". The k42 no-answer rule is judged over the report's results in suite, case and repetition order (so the first error is exactly the order k44 names).
- **Output order.** Lines come as results end, which with `--concurrency` above 1 need not be the load order; with 1 it is the former order.

**Amendment 2026-11-11 (k19, k51).** Chosen by the worker in the overnight run, not by the maintainer.

- **`holmgang export-yaml <dir>... --out DIR [--seed ID=N]...`** (k19), the working name of CONTEXT.md §7. The arguments are taken as by `lint` (suite directories or directories of suites); every suite with `suite.pl` is written by `Loader->export` into `--out/<id>` (ADR 0007 amendment k19), each suite with `suite.yaml` gets `skip <id> (format 2 already)`. Output `ok   <id> (<n> cases) -> <dir>` or `FAIL <id>` with the refusal, then `<n> DSL suite(s): <k> exported, <m> refused`. Exit 1 when a suite was refused; 2 without `--out`, without any DSL suite among the arguments, or when a `--out/<id>` exists already — checked for every suite before anything is written, nothing is overwritten. `--out` is created when missing.
- **`--seed ID=N`** (k51) on `lint`, `run` and `export-yaml`, repeatable: the loader's seed override (`Loader->new( seeds => … )`, ADR 0007 amendment k18) for the DSL suite `ID`. `N` is 0 .. 4294967295 (`::Random`'s range). A usage error (exit 2): not `ID=N`, a number out of range, an id given twice, or an id that is no DSL suite among the command's suites (a format 2 suite, a typo) — a mistyped private seed would otherwise silently measure the public one. A DSL suite without `generate` takes the seed and changes nothing; that is not detected. The CLI builds a second loader with the same simulators, haystack, structure and lint and the seeds added, so an injected `loader` keeps its parts. `report --suite` takes no `--seed`: it reads only thresholds. The seed is not written into the report; the overridden suite has its own digest there, which `--resume` compares.
