# Reference implementation

This is an original teaching implementation, not a compatibility layer for an existing DSL or
production workflow engine. All code comments, examples, and documentation are English.

## Module map

| Layer | Modules |
|---|---|
| Core-only | `Registry`, `Predicate`, `Plan`, `Executor`, `Schema` |
| Moose integration | `Example::Sugar`, `RoleDSL`, `Owners`, `Runner` |
| Consumers | `Example::Flow::Probe`, `Example::Flow::Check` |

All names above are under `lib/`; helper names without a prefix are under
`Example::Sugar::`. The five core modules use Perl/core-library dependencies only.
The example code targets Perl 5.20 or later syntactically; it was executed only on
a single Perl version.
No untested version-range certification is implied.

## Run without Moose

```sh
perl demo-core.pl
perl schema-demo.pl
prove -Ilib t
```

`demo-core.pl` uses a plain Perl subject and explicit owner lists to exercise the
same registry, planner, predicate evaluator, and executor used by the Moose adapter.
It neither emulates Moose nor proves Moose integration. The script makes no network
requests; its example URL is an inert string.

The default `prove` invocation executes core tests and explicitly skips optional
integration files when their real dependencies are missing.

## Run the actual Moose example

Install Moose through your normal CPAN workflow, then run:

```sh
perl demo-moose.pl
prove -Ilib t/70-moose.t
```

Install Future and IO::Async for `t/80-future.t` and `t/90-io-async.t`. To prohibit
integration skips across the suite:

```sh
SUGAR_REQUIRE_INTEGRATIONS=1 prove -Ilib t
```

The environment-variable spelling above is POSIX shell syntax.
The `cpanfile` records dependencies, but no dependency installer runs automatically.

## Public declaration syntax

```perl
step $label => $key => sub { return { data => 1 } },
  phase => 'gather', requires => [], revision => '1';

step_if $predicate => $label => $key => sub { return { data => 1 } },
  phase => 'analyse', requires => ['earlier'];
```

Supported phases: `gather`, `analyse`, `score`, `render`. Unknown or repeated options
are errors. Every body returns one unblessed hashref of JSON-compatible data.
`requires` is this example's per-step dependency option, not a claim about a class-level
`step_requires` API in an existing DSL.

The class exporter supplies Moose sugar and installs a small runner role. The role
exporter supplies Moose::Role sugar. Both use `with_meta` and pass ownership to the
same backend. Cleanup uses the matching `no Example::Sugar` or
`no Example::Sugar::RoleDSL`. Classes are made immutable only after declarations.

## Ordering and activation

Owner discovery is base-first reverse MRO; discovered role names are lexically
ordered and deduplicated. This is an explicit example policy, not Moose's business
execution-order guarantee. The planner sorts by phase and stable dependency order.
Merged duplicates, unknown dependencies, cycles, and phase inversions fail.

Predicates support reader names, all-equal scalar maps, and trusted callbacks.
Expression strings are rejected. Binding evaluates predicates once against unchanged
configuration. Active steps cannot require disabled producers. Callbacks must not
read results, call the executor, perform domain I/O, or mutate run state.

## Execution and introspection

Moose consumers expose `run`, `result`, `has_result`, `results`, `steps`, and
`progress`. `steps` returns a data-only structural manifest; it does not invoke
bodies or predicates. Other runtime methods can lazily bind the plan. Treat runner
method names and `_sugar_*` names as reserved in this example.

`run` is synchronous. Validated results and activation decisions are retained only
inside the same execution object. An explicit rerun skips its successful steps and
reattempts unfinished active steps. Unchanged inputs and retry-safe side effects are
assumed; the executor does not prove either condition. Use a fresh object for new
inputs. Results returned to callers are detached copies.

## What is intentionally not implemented

| Capability | Status |
|---|---|
| Class/role declarations and inherited owners | Included; real Moose tests are dependency-gated |
| Local/merged validation, DAG, predicates, synchronous execution | Implemented and core-tested |
| Pure schema helpers | Implemented; real JSON Schema payload tests included |
| Future aggregation and actual event-loop timer overlap | Separate dependency-gated tests, not integrated into the executor |
| `par_step`, `par_group`, concurrency limits | Design references only; not accepted DSL keywords |
| Durable resume, leases, crash recovery, transactional checkpoints | Design references only |
| `tool`, authorization, provider envelopes | Design references only |
| `config_attribute`, `user_input`, generated forms | Design references only |
| `validation_step`, cache promotion, localization | Design references only |
| Class-plan caching and reload invalidation | Not implemented; structural lookup recomputes |

Do not deploy the example as a security boundary or claim exactly-once execution.
See the focused references listed in [SKILL.md](../../SKILL.md) before adding those features.
