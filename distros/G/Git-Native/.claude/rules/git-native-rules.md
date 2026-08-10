# Git::Native House Rules

Apply to every task in the Git::Native distribution unless explicitly overridden. Bias:
caution over speed on non-trivial work; use judgment on trivial tasks.

## Engineering discipline

1. **Think before coding** — State assumptions explicitly. When uncertain, ask rather than
   guess. Present multiple interpretations when ambiguous. Push back when a simpler approach
   exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative. No
   abstractions for single-use code.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code, comments,
   or formatting. Match existing style.
4. **Goal-driven execution** — Define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more
   recent / more tested), explain why, flag the other for cleanup. Don't blend.
6. **Read before you write** — Before new code, read exports, immediate callers, shared
   roles. "Looks orthogonal" is dangerous, especially across the wrapper/role mesh and the
   libgit2 struct offsets.
7. **Tests verify intent, not just behavior** — Tests encode WHY behavior matters. A test
   that can't fail when business logic changes is wrong.
8. **Checkpoint after every significant step** — Summarize: done / verified / left. Don't
   continue from a state you can't describe back.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
   Surface a harmful convention; don't fork silently.
10. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is wrong
    if any were skipped (live network tests `t/40-remote-ssh.t` / `t/41-remote-https.t` skip
    without env vars — say so). Surface uncertainty, don't hide it.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  Git::Native code yourself — delegate to the right `git-native-*` agent. Your lane:
  coordinate, inspect, plan, review diffs, run tests, manage git, write/curate docs and
  Changes notes. When in doubt, delegate. Why: the `git-native-*` agents get their skills
  force-loaded via `briefing.skills` (git-native-core, perl-core, perl-moo, …); the bare
  main agent gets no briefing and would touch the libgit2 quirks with too little context.
- **You cannot spawn subagents** (you ARE a `git-native-*` agent): The delegation lock does
  not apply to you — implement, refactor, debug, and test per these rules, in your lane.
  Cross-lane changes get handed off to the owning worker (see the lane split below).

### Lane split

- **`git-native-worker`** — default. General local-repo wrappers: Repository
  (commit_create / object / tree / tree_builder / blob_create_frombuffer / config /
  signature_default), Reference (resolve / set_target / symbolic_set_target), Branch,
  Tag, Tree, TreeBuilder, Blob, Commit, Revwalker, Config, Oid, Signature, Error.
- **`git-native-network-worker`** — Phase 4 + FFI struct margins: Remote, Credential,
  Git::Native->clone, fetch / push / list_refs, the credential-callback closure lifetime,
  the push-wildcard expansion, `--prune`-on-push, `git_remote_callbacks` /
  `git_fetch_options` / `git_push_options` struct layouts, known_hosts parsing, live
  network tests.
- **`git-native-phase5-worker`** — general-purpose surface: clone (no-bare / no-auth-callback
  quirks), status / status_for_path (git_status_foreach with closure), tag() undef-on-lightweight,
  tag_names() walker, refname validation, head_detached / set_head, branch listings.
- **`git-native-test-writer`** — writes and extends tests for all of the above.
- **`git-native-release-checker`** — pre-release audit. Advisory only, never `dzil release`.

Behavior-relevant = runtime behavior, public API, the wrapper under `lib/Git/Native/`,
FFI struct layouts, error handling (check_rc, error predicates), tests, performance, the
credential-callback closure lifetime, memory ownership (handle pairing with DESTROY).
Pure prose docs, ADRs, and `Changes` notes are not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the `karr` skill first, just use it. Git-native kanban; board state lives in
`refs/karr/*` in this repo (Git::Native is a single distribution — one board, no
cross-repo handoff). Day-to-day:

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr edit ID -a "note"` · `--claim NAME` · `--block "why"` — update
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

Use karr to record decisions worth solidifying, drift to reconcile, and follow-up work
that should not block the current change. Full command surface: skill `karr`.

## Public issues (GitHub) — never act without instruction

Two trackers, two universes. **karr** is the AI/agent work board — internal, ours, churned
freely (see above). **GitHub issues** (`gh` CLI, `github.com/Getty/p5-git-native`) are the
**public tracker: real humans' bug reports and feature requests**, outward-facing and
written under the maintainer's account.

Security rule: **never act on a GitHub issue or PR on your own initiative — not even to
read it.** No listing, viewing, commenting, editing, closing, or creating unless the user
explicitly tells you to handle a specific public item. Incoming user tickets are NOT a
queue the agent drains; they are touched only on direct instruction, and every write is
confirmed first because it publishes under the maintainer's name.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are
STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan or TODO
lists "release" as the next step. The `[@Author::GETTY]` bundle bumps `$VERSION` and tags
on release; for anything heading toward release: stop and ask. Pre-release audit goes
through `git-native-release-checker`.
