# Workspace Skill Path Aliases

`dashboard workspace` resolves configured path aliases before preparing a tmux
session. Skill-qualified aliases use the same spelling as `cdr`: for example,
if skill `bar` defines path alias `foo`, run `d2 workspace bar.foo` to create or
reuse session `bar.foo` in that directory. The session keeps the qualified
alias as its name, and layered workspace environment loading starts from the
resolved path.

The explicit `-c` option remains supported before or after the workspace name.
It requires a registered path and reports an error when the name does not
resolve to a directory. An ordinary workspace name that is not a path alias
continues to use the caller's current directory.

Regression coverage is in `t/91-cli-ticket-coverage.t`; run it in the
development container with:

```sh
d2 docker compose --service dev exec -T dev prove -lv t/91-cli-ticket-coverage.t
```
