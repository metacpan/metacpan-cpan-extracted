# CLAUDE.md

## Shared CI

- This repo hosts the composite action `.github/actions/dzil-test` that every
  `[@Author::GETTY]` dist's workflow consumes via
  `uses: Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main`.
  It is the single source of truth for the dzil CI mechanics.
- The action installs deps with **`dzil listdeps --author`** (not plain
  `listdeps`). The `--author` flag pulls develop-phase author-test deps like
  `Test::Pod` that `[PodSyntaxTests]` registers. **Never fake `Test::Pod` (or
  other author-test deps) into a dist's cpanfile `on test`** — that hack is
  what this setup removes.
- The bundle's own `.github/workflows/ci.yml` dogfoods the action via the local
  path `./.github/actions/dzil-test`.

## Git Commits

- **NEVER prefix commit subjects with `[@Author::*]` or similar bundle/plugin tags.** Describe the change directly. Example: `add [GitHub::CreateRelease] when GitHub integration is active`, NOT `[@Author::GETTY] add ...`. Plugin/module names inside the message body (e.g. `[GitHub::CreateRelease]`) are fine — only the leading `[@Author::*]` namespace prefix is forbidden. Out of ~117 commits in this repo, only 1 had such a prefix (a Claude mistake).
