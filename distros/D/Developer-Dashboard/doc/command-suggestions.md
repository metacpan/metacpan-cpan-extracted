Command Suggestions
===================

When `dashboard` receives an unknown command token, it now prints a direct
error plus the closest matching command suggestions before the usual help
summary.

Top-level commands
------------------

Mistyped built-in commands, layered custom commands, and other public
switchboard entries are matched against the active DD-OOP-LAYERS command set.

Examples:

```bash
dashboard dcoekr
dashboard skils list
```

The stderr guidance now points at likely corrections such as `dashboard docker`
or `dashboard skills` instead of only dumping the generic usage block.

Dotted skill commands
---------------------

Mistyped dotted skill commands use the same guidance flow, but the candidate
set is limited to installed skill commands, including nested
`skills/<repo>/skills/<repo>/...` trees.

Examples:

```bash
dashboard alpha-skill.run-tset
dashboard nest.level1.level2.hre
```

The stderr guidance points at the nearest installed dotted command such as
`dashboard alpha-skill.run-test`.

Tab completion
--------------

The generated shell bootstrap also asks the same runtime for live completion
candidates when the user presses Tab after `dashboard` or `d2`.

Examples:

```bash
dashboard complete 1 dashboard do
dashboard complete 1 d2 alpha-s
```

That completion source includes built-in commands, layered custom commands,
and installed dotted skill commands, so the interactive shell and the typo
guidance stay aligned with the same command inventory.
