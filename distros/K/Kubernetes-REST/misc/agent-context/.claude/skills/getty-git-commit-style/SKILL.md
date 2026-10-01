---
name: getty-git-commit-style
description: Use when writing or amending a commit message in a Getty repository, including a commit that spans several repos.
---

# Commit Message Style

## Format

```
<summary line — imperative, max ~72 chars>

<body — one line per change, no filler>

Co-Authored-By: Claude <Model> <noreply@anthropic.com>
```

## Rules

- **Summary line**: imperative mood ("Add", "Fix", "Rename", "Remove"), describe the primary intent
- **Body**: list every discrete change on its own line, no bullets needed, no prose explanations
- **Completeness**: every file-level change must be mentioned — don't silently lump things together
- **Brevity**: state what changed, not why it's important or how it works — the diff shows that
- **No filler**: no "This commit...", no "In this change...", no "Also..."
- **No @ symbols**: never use `@` in commit messages (e.g. write `[DBIO]` not `[@DBIO]`) — platforms like GitHub interpret `@word` as user/org mentions
- **Language**: English
- **Co-Author**: append the Co-Authored-By line whenever Claude wrote or co-wrote the changes.
  Name the model that actually did the work — read it from the session rather than
  copying a version out of an older commit or out of this file. If the harness
  prescribes its own trailers (a session link, a different spelling), use those verbatim.

## Examples

Good:
```
Rename _dbic_connect_attributes to _dbio_connect_attributes

Storage/DBI.pm: accessor declaration and two call sites
Schema/Versioned.pm: one call site
```

Good:
```
Migrate to [DBIO] bundle, fix _Util rename, add POD

Switch dist.ini from [Author::GETTY] to [DBIO].
Fix DBIO::_Util -> DBIO::Util in Storage::ASE.
Fix _dbic_cinnect_attributes typo in Storage::FreeTDS.
Add inline POD to all four modules.
Clean up cpanfile, remove deps already in DBIO core.
Add CLAUDE.md and README.md.
```

Bad (too vague):
```
Update driver code and documentation
```

Bad (too verbose):
```
This commit updates the Sybase driver distribution to use the new
[DBIO] Dist::Zilla plugin bundle instead of the previous [Author::GETTY]
bundle. Additionally, it fixes an issue where...
```

## Changelog entries

Where the repo carries a `Changes` or `CHANGELOG`, the entry belongs in the same commit
as the change it describes, and the rules above apply to it unchanged. One thing makes
it harder than a commit message: a message is written once and never seen again, while
the unreleased section stays open for weeks and is edited again every time the same
area is touched.

**One topic, one entry.** Before writing a bullet, read the unreleased section for the
topic you are about to describe. If it already has one, **rewrite that bullet** to say
where the code now stands — never append a second. Three bullets circling one option
are three chances to contradict each other, and the reader wants the released state,
not the sequence of attempts that produced it.

**Describe the destination, not the journey.** No "used to", no "previously", no
walkthrough of the mechanism, no defence of the alternative that lost. Name what is
true now and what a user does differently because of it. The reasoning has homes that
keep it — the commit body, the ticket, an ADR; a changelog is read by someone who
never saw the old behaviour.

**Reference only the tracker the repo publishes.** In a changelog a `#123` earns its
place when the reader can open it — GitHub or Gitea issues on a repo that has them. An
internal board ticket is unreadable outside the workspace, so it does not appear there
at all: name the change instead of the number. A commit message may carry one, written
in the board's own notation (karr ids are `k254`) — never as `#254`, which every
hosting platform resolves against *its* issue 254: a dead link today, someone else's
bug once the repo has that many.

Aim for one to three lines per entry, and let the count of entries fall out of the
work rather than the detail per entry. For scale: a mature Getty distribution carries
320 releases in a 348-line `Changes` — a whole history shorter than a single unreleased
section that was allowed to accrete.

## Multi-repo commits

When committing across multiple repos in a workspace, each repo gets its own
commit with its own message. Don't reference other repos in the message.

## HEREDOC usage

Always pass commit messages via HEREDOC to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
Summary line

Body lines here.

Co-Authored-By: Claude <Model> <noreply@anthropic.com>
EOF
)"
```
