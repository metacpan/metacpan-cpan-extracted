---
name: git-commit-style
description: "Commit message conventions — compact, precise, complete"
user-invocable: false
---

# Commit Message Style

## Format

```
<summary line — imperative, max ~72 chars>

<body — one line per change, no filler>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

## Rules

- **Summary line**: imperative mood ("Add", "Fix", "Rename", "Remove"), describe the primary intent
- **Body**: list every discrete change on its own line, no bullets needed, no prose explanations
- **Completeness**: every file-level change must be mentioned — don't silently lump things together
- **Brevity**: state what changed, not why it's important or how it works — the diff shows that
- **No filler**: no "This commit...", no "In this change...", no "Also..."
- **No @ symbols**: never use `@` in commit messages (e.g. write `[DBIO]` not `[@DBIO]`) — platforms like GitHub interpret `@word` as user/org mentions
- **Language**: English
- **Co-Author**: always append the Co-Authored-By line when Claude wrote or co-wrote the changes

## Examples

Good:
```
Rename _dbic_connect_attributes to _dbio_connect_attributes

Storage/DBI.pm: accessor declaration and two call sites
Schema/Versioned.pm: one call site
```

Good:
```
Migrate to [@DBIO] bundle, fix _Util rename, add POD

Switch dist.ini from [@Author::GETTY] to [@DBIO].
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
[@DBIO] Dist::Zilla plugin bundle instead of the previous [@Author::GETTY]
bundle. Additionally, it fixes an issue where...
```

## Multi-repo commits

When committing across multiple repos in a workspace, each repo gets its own
commit with its own message. Don't reference other repos in the message.

## HEREDOC usage

Always pass commit messages via HEREDOC to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
Summary line

Body lines here.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```
