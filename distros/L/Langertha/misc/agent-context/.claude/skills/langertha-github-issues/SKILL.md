---
name: langertha-github-issues
description: Use whenever GitHub, the gh CLI, public issues, pull requests or user bug reports come up in Langertha. Not the agent work board — that is kanban-issues-karr-cli.
---

# Langertha GitHub User Issues (`gh`)

Langertha has **two separate trackers. Do not confuse them.**

| Tracker | What it holds | Tool | Who writes it |
|---|---|---|---|
| **karr** | AI/agent work board — internal kanban in `refs/karr/*` | `karr` CLI | agents, internally |
| **GitHub issues** | **PUBLIC user tickets** — real humans' bug reports & feature requests | `gh` CLI | the community |

`karr` is *ours*, internal, churned freely. GitHub issues are **outward-facing and written by
real people**. They are a different universe — never route agent/internal work there, and
never treat a GitHub issue as if it were a karr ticket.

## THE HARD RULE — `gh` only on explicit instruction

**Never invoke `gh` against issues/PRs on your own initiative — not even to read.** No
proactive listing, searching, viewing, commenting, editing, or closing of GitHub issues or
pull requests. You touch this tracker *only* when the user explicitly tells you to (e.g. "look
at GitHub issue #42", "reply to that bug report"). With no such instruction, stay out of `gh`
issue/PR commands entirely.

Even **with** an instruction, every *write* (`create` / `comment` / `edit` / `close`) is
published to a public tracker under **the signed-in GitHub account** — outward-facing and hard
to take back. Confirm the exact wording before sending; when in doubt, show the draft and ask.
Reading (`view` / `list`) needs the instruction but no extra confirmation.

## Setup — authenticate first (each person, each machine)

`gh` acts under **whoever is logged in**, not a shared account. Nothing below works until:

```bash
gh auth login       # sign in to github.com (browser/token flow); once per machine
gh auth status      # confirm the signed-in account
```

If `gh auth status` errors, you are not logged in — there is no access until `gh auth login`
is run (and only do so when the user actually wants `gh` used; see the hard rule). The repo's
`origin` is `github.com/Getty/langertha`, so `gh` targets it by default; `-R Getty/langertha`
makes it explicit.

## Reading issues (only when instructed)

```bash
gh issue list                              # open issues on this repo
gh issue list -s all -S "tool calling"     # search; -s open|closed|all
gh issue list -l bug -A <user>             # filter by --label / --assignee
gh issue view 42                           # title + body of issue #42
gh issue view 42 -c                        # include comments
```

`gh pr list` / `gh pr view <id>` read pull requests the same way.

## Writing issues (only when explicitly instructed — outward-facing)

```bash
gh issue comment 42 -b "Fixed in <sha>, thanks for the report."   # public comment
gh issue create -t "Title" -b "…"          # or -F FILE; omit -b/-t opens $EDITOR
gh issue edit 42 --title|--body|--add-label # edit a field
gh issue close 42 -c "Resolved in vX.Y"    # close, optional closing comment
```

Prefer `-F/--body-file` for anything multi-line so the published text is exactly what was
reviewed. Same shape for `gh pr comment|edit|close|merge`.

## Quick guard checklist

- [ ] Did the user explicitly ask me to touch GitHub / `gh` / a user issue? If not → **do not run `gh` issue/PR commands at all.**
- [ ] Is this a *user* ticket (GitHub), not an *agent* ticket (karr)? Right tool for the tracker.
- [ ] Writing? It is public and under the signed-in GitHub account → confirm the wording first.
