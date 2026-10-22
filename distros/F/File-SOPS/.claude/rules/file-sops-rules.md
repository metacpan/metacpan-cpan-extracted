# File::SOPS House Rules

Apply to every task here unless explicitly overridden. Bias: caution over speed on non-trivial work;
judgment on trivial ones. Subagents get their conventions from `briefing.skills` — skill content is
not restated here.

## Engineering discipline

1. **Think before coding** — State assumptions; ask rather than guess when uncertain; offer
   alternatives if ambiguous. Push back if simpler exists; stop when confused, name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code, comments or
   formatting. Match existing style.
4. **Read before you write** — Read the callers and the twin: value→bytes conversion and the type
   ladder exist in more than one place; changing one alone is this distribution's signature bug.
5. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave a regression
   test behind. A test that can't fail when the wire format changes is no test here.
6. **Match the codebase's conventions, even if you disagree** — Conformance > taste; surface a
   harmful convention, don't fork silently.
7. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is wrong if any
   were skipped. Surface uncertainty, don't hide it.
8. **A red test is a claim before it is a failure** — Before turning a test green, say what it
   asserts and whether your fix keeps or replaces that claim. If the claim is wrong, fix the claim.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant code
  yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run tests, edit prose
  docs. Why: only the `file-sops-*` agents get their skills via `briefing.skills`; you get none and
  would touch format-critical internals blind.

| Task | Agent |
|---|---|
| Value types, encoding, AES-GCM, MAC/AAD, backends | `file-sops-wire` |
| Public API, guards, error behaviour, rule policy | `file-sops-api` |
| Parsers, emitters, quoting, the order-preserving reparse | `file-sops-format` |
| Write/extend tests, reproduce interop bugs | `file-sops-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `file-sops-release-manager` |

Pick the lane by what the change *moves*, not by which file it starts in: a `Format/YAML.pm` edit
that changes what gets hashed belongs to `file-sops-wire`; when a ticket spans lanes, run them in
sequence and let each report what it handed on — parallel workers in the same file overwrite each
other.

- **You cannot spawn subagents** (you ARE a `file-sops-*` agent): The delegation lock does not apply
  — implement, refactor, debug, and test per these rules.

Behavior-relevant = `lib/`, the tests, and any change to the wire format, MAC, AAD derivation, type
detection or serialization; prose docs, `README.md` and `Changes` wording are not. **Only
`file-sops-release-manager` commits**; workers hand over a commit-ready tree and their card.

## Interop and crypto — the Go implementation is the spec

**Never report a green suite as evidence for a format-touching change.** `t/04-interop.t` is the
only compatibility proof and skips without a `sops` binary — say which run you did; self-consistency
proves nothing about what `sops` accepts.

Nonce sizes, tag handling, AAD, key derivation and the MAC follow the reference implementation, not
your taste. What looks wrong is more likely a deliberate Go-compatibility choice than a bug — verify
against the reference before "fixing" it; **never weaken a check to make a test pass**.

Secrets, age keys and plaintext values never land in logs, commit messages or ticket bodies.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't invoke
the `kanban-issues-karr-coordination` skill first, just use it. Board state lives in `refs/karr/*`.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --body '…'` · `karr edit ID -a "note" --block "why"`
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note` — review

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any CPAN upload are
STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan lists "release" next.
Stop and ask. After a release the `$VERSION` bump is a separate, deliberate commit.

## GitHub issues — never act without instruction

`karr` is the internal board. GitHub issues on `Getty/p5-file-sops` are the **public tracker**: real
people's reports under the maintainer's account. **Never act on one on your own initiative — not
even to read it.** No listing, viewing, commenting, closing or creating unless told to handle one.

## Perl specifics — reference, don't restate

House Perl style lives in `getty-perl-core`, `getty-perl-moo`, `getty-perl-release-author-getty`;
wire format and invariants in `file-sops-core` (all force-loaded). Do not duplicate them here.
