# Git::Libgit2

Low-level FFI::Platypus bindings to libgit2, via Alien::Libgit2. A 1:1 surface
of the C API as Perl subs: opaque handles, return codes, manual `*_free`. No
Moo, no RAII, no policy — that is `Git::Native`, one layer up.

```
App::karr > Git::Native > Git::Libgit2 (here) > Alien::Libgit2 > libgit2
```

## Sources of truth

- `README.md` — the bound surface (all 236 functions, grouped), helpers,
  lifetime and OID-buffer rules, the struct-layout warning. Keep its function
  count and group lists in step with `_attach_all()`.
- `lib/Git/Libgit2/FFI.pm` — every binding plus its `=func` POD; group
  headings are `=head1`.
- `TODO.md` — the unbound surface, Group B (wanted) and Group C (on demand),
  with per-family FFI gotchas.
- `Changes` `{{$NEXT}}` — every user-visible change, at the time it is made.
- karr board (`karr list`) — open tickets; release blockers carry that tag.

## Non-negotiables

- `Git::Libgit2::FFI` is a process-wide singleton; all bindings attach there,
  `Git::Libgit2` only re-exports helpers.
- A `git_*` binding never throws. `check_rc` is the one explicit helper that
  turns a negative rc into a thrown `Git::Libgit2::Error`; consumers opt in.
- `*_options_init`, never `*_init_options` (gone in libgit2 1.7).
- Struct offsets are probed at runtime (`fetch_options_prune_offset`), never
  compiled in — layouts move between 1.x releases.
- Every test isolates git config (`GIT_CONFIG_GLOBAL`/`GIT_CONFIG_SYSTEM` to
  `/dev/null`) and pins `refs/heads/main` after init before committing.
- `prove -lr t/` — the `-r` is load-bearing, plain `prove -l t/` skips
  subdirectories silently.

## Build / release

`[@Author::GETTY]` Dist::Zilla bundle; pure Perl + FFI, no compiler at
install. `Alien::Libgit2` is the hard runtime dep and must be on CPAN at the
pinned version before this releases.

## Delegation

Behaviour-relevant code goes to an agent, not the main context: the main
agent scopes, delegates, reviews, and reports. The principle is the shared rule
`agent-delegation` (skilletor bundle `getty-cpan-dist@getty`); the lane
boundaries are in `.claude/rules/libgit2-rules.md`. Agents carry their skills
via `briefing.skills` (`.claude/agents/`); skill sources live in
`.claude/skills/` — the shared ones are installed by skilletor from
`Getty/skills`, `libgit2-core` is owned by this repo. Never edit an installed
skill copy; change the source it comes from.

| Task | Agent |
|---|---|
| Implement / refactor / debug bindings or tests | `libgit2-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `libgit2-release-manager` |
