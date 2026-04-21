Shell Bootstrap
===============

`dashboard shell <bash|zsh|sh|ps|pwsh>` prints the shell bootstrap snippet that
integrates Developer Dashboard into an interactive shell session.

Generated helpers
-----------------

The generated snippet exposes these helpers:

- `cdr`: resolve a saved dashboard path alias or search below the current
  directory and change into the chosen target.
- `dd_cdr`: compatibility wrapper that forwards to `cdr`.
- `d2`: short shell shortcut that forwards directly to `dashboard`, so commands
  such as `d2 version`, `d2 doctor`, and `d2 docker compose ps` work without
  typing the full command name.
- `which_dir`: print the same resolved target or match list that `cdr` would
  use, without changing directory.
- live completion for `dashboard` and `d2`: generated from the runtime so
  built-ins, layered custom commands, and installed dotted skill commands can
  all appear in shell suggestions.
- live completion for `cdr`, `dd_cdr`, and `which_dir`: generated from the
  runtime so the first argument can suggest saved aliases plus matching
  directories, and later arguments can suggest matching directory basenames
  below the resolved search root.

Shell-specific behavior
-----------------------

- bash: keeps the compact `dashboard ps1` prompt with `\j` job counts and
  wires `_dashboard_complete` for `dashboard` and `d2`, plus
  `_dashboard_complete_cdr` for `cdr`, `dd_cdr`, and `which_dir`, through
  `complete -F`.
- zsh: refreshes the prompt through `precmd`, uses `${#jobstates}`, and wires
  `_dashboard_complete_zsh` for `dashboard` and `d2`, plus
  `_dashboard_complete_cdr_zsh` for the cdr-family helpers, through `compdef`.
- POSIX `sh`: uses prompt-safe functions instead of bash-only prompt escapes.
- PowerShell and `pwsh`: install a `prompt` function, a `d2` alias that
  forwards into the dashboard command, and `Register-ArgumentCompleter`
  handlers for `dashboard`, `d2`, `cdr`, `dd_cdr`, and `which_dir`.

Examples
--------

```bash
eval "$(dashboard shell bash)"
d2 version
cdr bookmarks_root
which_dir foobar alpha
```

```bash
dashboard complete 1 dashboard do
dashboard complete 1 d2 sk
```
