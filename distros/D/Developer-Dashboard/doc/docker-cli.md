# Docker CLI help and completion

`d2 docker --help` and `d2 docker --help` print the Docker command
reference without calling Docker. `-h`, `help`, and no Docker subcommand show
the same reference. Unknown Docker subcommands fail explicitly and point to
the help option.

Shell completion offers `compose`, `list`, `enable`, `disable`, and
`development` after `d2 docker` or `d2 docker`. After `docker
development`, it offers `enable` and `disable`. Completion is served through
the existing `d2 complete` helper, so Bash and Zsh use the same command
definitions as the CLI.

Run the regression tests in the project Docker test environment:

```sh
prove -lv t/39-cli-suggest-complete-coverage.t t/05-cli-smoke.t
```
