# dashboard which

`dashboard which <target>` explains what the public `dashboard` switchboard
would run for one command target without executing the target itself. If you
add `--edit`, it re-enters `dashboard open-file` with the resolved command file
path instead of only printing the inspection output.

## Supported targets

- Built-in helpers such as `jq` or `paths`
- Layered custom commands such as `layered-tool`
- Skill commands such as `example-skill.somecmd`
- Nested skill commands such as `nest.level1.level2.here`

## Output

The command prints:

- `COMMAND /full/path` for the resolved runnable file
- `HOOK /full/path` for each participating hook file in runtime execution order

## Examples

```bash
dashboard which jq
dashboard which layered-tool
dashboard which example-skill.somecmd
dashboard which nest.level1.level2.here
dashboard which --edit jq
```

## DD-OOP-LAYERS behavior

For built-in helpers and custom commands, the hook list follows the
participating runtime layers from home to leaf, which matches the actual hook
execution order. For skill commands, the helper prints the resolved command
file from the deepest matching skill layer and any matching hook files from the
participating skill layers for that command.
