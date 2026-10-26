---
name: gatheragentcontext-core
description: Load before editing lib/Dist/Zilla/Plugin/GatherAgentContext.pm or its tests — what the plugin snapshots, the harness content rule, the built-in excludes, the strict UTF-8 decode and the build wiring.
user-invocable: false
---

# Dist::Zilla::Plugin::GatherAgentContext — the contract

The plugin snapshots a distribution's **agent context** into the build, so a tarball
records which skills, agents and rules it was built with. The module POD is the API
reference; this skill holds the decisions behind it — what a change has to keep.

## What it does

`Dist::Zilla::Role::FileGatherer` with `gather_files`: reads the **working directory**,
not git, and writes every taken file as `Dist::Zilla::File::InMemory` under
`misc/agent-context/`. Those files land in the tarball but are not installed.

- **Working directory, not git — deliberate.** `[Git::GatherDir]` would only see
  tracked files; the point is to capture skilletor-installed skills, agents and rules,
  which are git-ignored by design. Never "fix" this to read from git.
- **Relative to `$zilla->root`.** An absolute `dir`/`file` is fatal, not ignored.
- **The snapshot is a copy of the moment.** A file that changes after the gather is not
  the file in the tarball; that is what "provenance" means here.

## The attributes

| Attribute | Default | Contract |
|---|---|---|
| `harness` | `[]` (all) | `claude`, `codex`, `all`; repeatable. An unknown name is fatal. Ignored once `dir`/`file` are set. |
| `dir` | `[]` | Directories to snapshot recursively. Overrides the harness defaults. |
| `file` | `[]` | Single files to snapshot. Overrides the harness defaults. |
| `to` | `misc/agent-context` | Base path inside the build. |
| `exclude_match` | `[]` | Extra exclude regexes, applied on top of the built-in ones. Repeatable. |
| `prune_gitignore` | `1` | Skip `.gitignore` files (skilletor's per-skill management marker). |
| `missing_ok` | `1` | Skip a configured dir/file that is absent. `0` makes it fatal. |

`mvp_multivalue_args` covers `harness`, `dir`, `file`, `exclude_match` — a repeatable
attribute in `dist.ini` needs it, otherwise only the last value survives.

## Below a harness directory: content only

A harness directory — any directory named `.claude` or `.codex` — also holds local
state: login tokens, session transcripts, todos, caches, backups. The plugin reads from
disk, so a `.gitignore` keeps none of that out of the tarball. Directly below such a
directory the plugin therefore takes **only**:

- the directories `agents/`, `skills/`, `rules/`, `hooks/`, `commands/`, recursively;
- the files `CLAUDE.md`, `skilletor.json`, `skilletor.lock.json`, `skilletor-rules.md`.

Everything else there is never read, whatever it is called — a list of names to skip
would publish every name nobody thought of. To take a further subdirectory, configure it
by name (`dir = .claude/output-styles`): named explicitly, it is an ordinary directory
and is taken in full.

The rule holds for a harness directory named through `dir` and for one met deeper inside
a configured tree. Other directories (`.agents/skills`, own `dir` entries) are taken in
full.

## The built-in excludes

Always skipped, wherever they are found, before any `exclude_match` addition:

| Excluded | Why |
|---|---|
| `<name>.local.<ext>` (any depth) | machine-local overrides and their backups. A **leading-dot** `.local.<name>.md` is skilletor content and stays. |
| `.credentials.json`, `auth.json` | harness login tokens |
| `settings.json` | editor and permission config, not agent content |
| any `worktrees/` directory | agent worktrees hold full checkouts (thousands of files) |
| `.DS_Store` | — |
| `.gitignore` | unless `prune_gitignore` is 0 |

An excluded **directory** is pruned before the plugin descends into it, so its contents
are never stat-walked. A rewrite into walk-then-filter re-introduces a full walk of
`.claude/worktrees/` on every build — the thing the prune exists for.

## Encoding and symlinks

- **Strict UTF-8** (`Encode::decode('UTF-8', …, Encode::FB_CROAK)`): a binary file aborts
  the build with a fatal error. A lenient `:encoding(UTF-8)` layer would substitute
  silently. Do not soften this.
- **Symlinks are never followed** while descending — a symlinked file or subdirectory is
  skipped. A top-level path given explicitly through `dir`/`file` is resolved normally,
  so a configured entry that is itself a symlink is still read.

## Wiring in dist.ini

```ini
[GatherAgentContext]
; optional:
harness       = claude
exclude_match = (?:^|/)secrets/
```

`dir` and `file` are repeatable; `exclude_match` too. An unknown `harness` value is
fatal at build time — the plugin does not guess.

## The test gate

**`dzil test --all`** is the real gate. It runs the woven author tests (`pod-syntax`,
`changes_has_content`) that a plain `prove -l t/` silently skips, and `prove` alone
therefore reports green on a distribution that cannot be released.

`t/` is flat: `00-load.t` (the role), `10-gather.t` (the walk), `20-excludes.t` (the
exclude set), `30-files-missing.t` (`missing_ok`), `40-harness-override.t` (the
harness sets), `50-prune-excluded-dirs.t` (prune before descent). A change to one of
these behaviours belongs in the matching file, not in a new one.

## Where to look

- `lib/Dist/Zilla/Plugin/GatherAgentContext.pm` — the whole implementation; the POD in
  it is the API reference and stays in sync with the attributes.
- `README.md` — the user-facing summary; it names the content set and the attributes.
- `Changes` — the CPAN-format release notes; every behaviour change gets a line.
