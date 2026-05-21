# CLAUDE.md

## Git Commits

- **NEVER prefix commit subjects with `[@Author::*]` or similar bundle/plugin tags.** Describe the change directly. Example: `add [GitHub::CreateRelease] when GitHub integration is active`, NOT `[@Author::GETTY] add ...`. Plugin/module names inside the message body (e.g. `[GitHub::CreateRelease]`) are fine — only the leading `[@Author::*]` namespace prefix is forbidden. Out of ~117 commits in this repo, only 1 had such a prefix (a Claude mistake).
