# Workspace Change-Directory Flag

`dashboard workspace -c <name>` and `dashboard workspace <name> -c` change
directory before starting the workspace.

When the workspace name is registered in the dashboard paths inventory, the
same registered names the shell `cdr` helper resolves (configured
`path_aliases` plus the path registry), the command:

1. resolves the registered directory for the workspace name
2. changes into that directory first
3. plans and starts the tmux workspace session from there

So `dashboard workspace -c foobar` behaves like:

```sh
cdr foobar
dashboard workspace foobar
```

The flag position is flexible; both of these are equivalent:

```sh
dashboard workspace -c foobar
dashboard workspace foobar -c
```

Because the directory change happens before session planning, the tmux
session starts inside the registered directory and the layered `.env` refresh
walks the ancestor chain of that directory, not of wherever the command was
typed.

Failure behavior is explicit, never silent:

- a name that is not a registered dashboard path fails with
  `Workspace '<name>' is not a registered dashboard path, so -c has no directory to change into`
- a registered target that is not a directory fails with an error naming the
  resolved path
- a directory the user cannot enter fails with the underlying `chdir` error

Without `-c`, `dashboard workspace` behavior is unchanged: the session starts
from the current working directory.
