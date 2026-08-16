# Kubernetes::REST House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work. Subagents get their conventions from the skills force-loaded via
`briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions; ask rather than guess. Push back when a
   simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first, surgically applied** — Minimum code that solves the problem, nothing
   speculative. Touch only what you must; don't "improve" adjacent code or formatting.
3. **Goal-driven execution** — Define success criteria, loop until verified.
4. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more recent
   / more tested), explain why, flag the other. Don't blend.
5. **Read before you write** — Before new code, read the pipeline in `lib/Kubernetes/REST.pm`
   (`_prepare_request` → `io->call` → `_check_response`/`_inflate_*`) and
   `Role/IO.pm`. Request building, transport and inflation are one mechanism; "looks
   orthogonal" is dangerous here.
6. **Tests verify intent, not just behavior** — A test that only checks the return value
   cannot fail when path building or encoding breaks, which is the failure that actually
   reaches the cluster. Reproduce a bug before fixing it; leave the regression test behind.
7. **A red test is a claim before it is a failure** — Before changing code to turn a test
   green, say what the test asserts and whether your fix keeps that claim or replaces it.
8. **Checkpoint and fail loud** — Summarize done / verified / left after each significant
   step. "Done" is wrong if anything was skipped silently; "tests pass" is wrong if any
   were skipped — say so.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run tests,
  manage git, edit `Changes`/`README`. When in doubt, delegate. Why: only the
  `kubernetes-rest-*` agents get their skills force-loaded via `briefing.skills`; you get no
  briefing and would touch the pipeline and the IO seam with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug anything under `lib/` or `bin/` | `kubernetes-rest-worker` (default) |
  | Write or extend tests in `t/` | `kubernetes-rest-test-writer` |
  | POD, on the core, the backends or the CLI | `kubernetes-rest-doc-writer` |
  | Pre-release audit | `kubernetes-rest-release-checker` |

- **You cannot spawn subagents** (you ARE a `kubernetes-rest-*` agent): the lock does not
  apply — implement, refactor, debug and test per these rules.

Behavior-relevant = everything under `lib/` and `bin/`, the request/response pipeline, the
IO backends, path building, the resource map, kubeconfig parsing, the CLI, and the tests.
Prose in `README.md` and `Changes` bullets are not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the skill first, just use it. Git-native kanban; state lives in `refs/karr/*` in this
repo.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` · `karr edit ID -a "note"`
  · `--claim NAME` · `--block "why"` · `karr move ID in-progress` — full surface: skill `karr`

Record drift and follow-up work as tickets rather than growing the current change. A defect
that turns out to live in the object model belongs on **`../io-k8s-p5`**'s board, not this
one — `cd` there and create it, then note the pointer here.
**Serialize board mutations when fanning out** — parallel implementation is fine, but collect
results and then loop `karr move`/`handoff`/`sync` sequentially.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are STRICTLY
forbidden without explicit go-ahead — even if a plan lists "release" as the next step.
This distribution is **co-maintained**: `authority = cpan:JLMARTIN`, the remote is
`github.com/pplu/kubernetes-rest`, Getty is a co-author. Releasing is not a unilateral call.

## Public issues (GitHub) — never act without instruction

`github.com/pplu/kubernetes-rest` is a **public tracker on someone else's repository**. Never
act on an issue or PR there on your own initiative — not even to read it. No listing,
viewing, commenting, editing, closing or creating unless explicitly told to handle a
specific item. Every write publishes under the maintainer's account.

## Hazards specific to this distribution

- **`prove -l t/` is not recursive** and silently skips subdirectory tests, exiting 0. Use
  `dzil test` or `prove -lr t/`. Reserve non-`-r` for a single named file.
- **An untracked file does not exist as far as dzil is concerned.** `[@Author::GETTY]`
  gathers through `Git::GatherDir`, whose `include_untracked` defaults to false and is not
  overridden here. A new test file that was never `git add`ed is silently absent from
  `dzil build`, from the release test gate and from the CPAN tarball — `prove -lr t/` runs
  it and passes, so nothing anywhere says the release never saw it. `git add` a new file
  as soon as it exists, and make `git status` the last check before any release.
- **Bytes on the wire, characters in objects.** The internal JSON encoder uses `utf8 => 1`
  and IO backends must return undecoded bodies (`decoded_content(charset => 'none')` under
  LWP). Decoding in a backend causes silent mojibake, not an error; dropping `utf8 => 1`
  makes every non-ASCII request body die in HTTP::Message. Both directions are pinned by
  `t/24_encoding.t` — run it after touching JSON, a backend or response handling.
- **One `package` per file, `$VERSION` in every file, all identical.** `RewriteVersion` and
  `BumpVersionAfterRelease` rewrite only the *first* `our $VERSION` per file, so a second
  package silently keeps a stale version while the metadata reports the release version —
  five packages sat at 1.003 until 1.106. `t/25_one_package_per_file.t` keeps it removed.
  The `$VERSION`-everywhere part is also correct and must not be "cleaned up" to the main
  module: the bundle narrows `version_finder` to `:MainModule` only for `no_cpan` dists.
- **Seven methods are published API for `Net::Async::Kubernetes`**: `build_path`,
  `prepare_request`, `check_response`, `inflate_object`, `inflate_list`,
  `process_watch_chunk`, `process_log_chunk`. Additive changes only, plus a `Changes`
  bullet. The `_`-prefixed originals behind them may move freely.
- **The object model belongs to `IO::K8s`** (`../io-k8s-p5`). Wrong field names or types are
  bugs there; do not paper over them here.
- **Removing public API is a breaking change with a protocol**: the tombstone goes into the
  separate `Kubernetes-REST-Deprecated` distribution (its own CPAN dist, not a module in
  this repo), and `Changes` states the changed failure mode. See the 1.105 removal of the
  1002 `Call::*` classes.
- **Tests never touch a real cluster.** The mock harness is the only path; the live path is
  gated behind `TEST_KUBERNETES_REST_KUBECONFIG`, deliberately named so nobody points the
  suite at production by accident. Never set it, never widen a test to depend on it.

## Perl conventions — reference, don't restate

Module loading, Moo patterns, dependency pinning and house style live in skills `perl-core`,
`perl-moo`, `kubernetes-rest-core`, `perl-kubernetes-rest` and `perl-release-author-getty`
(force-loaded per lane via `briefing.skills` — `.claude/agents/` defines which agent briefs
which). Do not duplicate that content here.
