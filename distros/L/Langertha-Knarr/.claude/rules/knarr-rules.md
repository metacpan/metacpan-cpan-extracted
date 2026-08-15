# Knarr House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills force-loaded
via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Present alternatives when ambiguous. Push back when a simpler approach exists. Stop when
   confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative. No
   abstractions for single-use code.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments, or formatting. Match existing style.
4. **Goal-driven execution** — Define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more
   recent / more tested), explain why, flag the other for cleanup. Don't blend.
6. **Read before you write** — Before new code, read the Handler role, the Protocol module
   pair, and `Request`/`Response`/`Stream`. "Looks orthogonal" is dangerous across the
   handler-decorator chain (Tracing/RequestLog wrap any handler).
7. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave a
   regression test behind. A test that can't fail when the logic changes is wrong.
8. **Checkpoint after every significant step** — Summarize: done / verified / left.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
   Surface a harmful convention; don't fork silently.
10. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
    wrong if any were skipped. Surface uncertainty, don't hide it.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  Knarr code yourself — delegate to `knarr-worker`. Your lane: coordinate, inspect, plan,
  review diffs, run tests, manage git, edit non-behavioral docs. When in doubt, delegate.
  Why: the `knarr-*` agents get their skills force-loaded via `briefing.skills`
  (perl-ai-langertha, perl-moose, perl-moo, …); you get no briefing and would touch the
  proxy internals with too little context. Specialist lanes:

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `knarr-worker` (default) |
  | Write/extend tests | `knarr-test-writer` |
  | Pre-release audit | `knarr-release-checker` |

- **You cannot spawn subagents** (you ARE a `knarr-*` agent): The delegation lock does not
  apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior, public API, request/response handling, the raw
passthrough path, protocol formatting and streaming, routing, tracing, config parsing,
error handling, tests, performance. Pure prose docs and `Changes` notes are not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the `karr` skill first, just use it. Git-native kanban; board state lives in
`refs/karr/*` in this repo (own board; the sibling Langertha repos each have their own —
cross-repo work is a ticket on that repo's board, never a direct edit). Day-to-day:

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr edit ID -a "note"` · `--claim NAME` · `--block "why"` — update
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

**Serialize board mutations when fanning out.** Keep implementation parallel, then loop
`karr move`/`handoff`/`sync` sequentially — N of them landing at once has OOM-rebooted
this host before.

## Public issues (GitHub) — never act without instruction

**karr** is the internal agent board, churned freely. **GitHub issues/PRs**
(`github.com/Getty/langertha-knarr`) are the public tracker, written under the
maintainer's name. **Never act on a public issue or PR on your own initiative — not even
to read it.** No listing, viewing, commenting, editing, closing, or creating unless the
user explicitly says to handle a specific item, and every write is confirmed first.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` is STRICTLY forbidden without
the maintainer's explicit go-ahead — and here it is bigger than CPAN: the
`run_after_release` chain also creates a GitHub release and pushes three Docker tags to
`raudssus/langertha-knarr` on Docker Hub. Same lock applies to standalone `docker push`
and `gh release`. For anything heading toward release: stop and ask.

## Knarr-specific hazards

- **The passthrough seam is bytes, not messages.** Unconfigured models pipe all HTTP bytes
  1:1 to the upstream API — that is the feature (preserves tool_use, usage,
  cache_control, SSE framing). A "cleanup" that parses and re-serializes on that path
  looks harmless and passes the fake-backed tests, but silently strips real-provider
  metadata. Protocol translation belongs only in `Protocol::*` on the routed path.
- **Streaming end markers** differ per protocol (table in CLAUDE.md); a wrong marker means
  a hung client, not a test failure. Any streaming change runs
  `prove -lv t/40_streaming_live.t t/41_streaming_protocols_live.t`.
- **`*_live.t` needs no API keys** — those tests start a real server on a local port with
  `Handler::Code` fakes. Keep them key-free; nothing in `t/` may hit an external service.

## Perl specifics — reference, don't restate

Module loading, Moose vs. Moo house patterns, cpanfile versioning, POD directives, and
commit style live in the briefed skills (`perl-core`, `perl-moose`, `perl-moo`,
`perl-io-async-future`, `perl-release-author-getty`, `git-commit-style`). The Moose/Moo
module split itself is in CLAUDE.md. Do not duplicate that content here.
