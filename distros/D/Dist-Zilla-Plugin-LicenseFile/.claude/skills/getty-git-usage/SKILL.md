---
name: getty-git-usage
description: Use when landing a branch in a Getty repo — rebase vs merge, cleaning up history before a PR, stacked branches, or cutting a release. For commit wording use getty-git-commit-style.
---

# Git usage

Short version: **keep the history linear.** A branch lands rebased, not merged.

## Landing work

```bash
git fetch origin
git rebase origin/main        # not merge
git push --force-with-lease    # after a rebase, never plain --force
```

For a pull request, `gh pr merge <n> --rebase --delete-branch`. Squash is the wrong
choice where a release is cut from commit prefixes: squashing replaces the individual
`feat:`/`fix:` subjects with the PR title, and a PR title without a prefix produces no
release at all.

Merge commits are not forbidden, they are just not the default. Reach for one when the
branch genuinely represents parallel work whose shape is worth keeping — not to avoid a
rebase.

## Stacked branches

A branch based on another branch is fine and common here, but note what GitHub does when
the lower one lands: it **closes** the dependent PR and refuses to reopen it. Rebase the
next branch onto `main`, force-push, and open a fresh PR. Reference the old number in the
body so the trail survives.

## Commits

Conventional prefixes (`feat:`, `fix:`, `docs:`, `test:`, `ci:`, `chore:`, `refactor:`),
always `--signoff`. The prefix is not decoration where a release workflow reads it:
`feat:` cuts a minor, `fix:` a patch, `feat!:` or a `BREAKING CHANGE:` body a major.
Everything else cuts nothing.

Message wording, body structure and multi-repo commits: see `getty-git-commit-style`.

## Before pushing

Run whatever the repo uses to check itself — its test script, `bash -n`, `py_compile`.
CI is a safety net, not the first place a failure should surface.

Never rewrite history that is already on `main`.
