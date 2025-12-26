# CLI Contract (Stable)

This document defines the **stable CLI contract** for `jq-lite`.
Anything described here is treated as a compatibility promise: changes MUST be
backward-compatible or require a major version bump.

## Goals

- Shell scripts must be stable: `if jq-lite ...; then ...; fi` should not break across releases.
- Follow `jq` expectations where practical.
- Distinguish errors by category via exit codes and stderr prefixes.
- Keep stdout clean on errors.

## Exit Codes

`jq-lite` returns one of the following exit codes:

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | `-e/--exit-status` was specified and the final result was `false`, `null`, or **no output** (empty) |
| 2 | **Compile error**: query/filter parse error |
| 3 | **Runtime error**: evaluation failed while executing a valid query |
| 4 | **Input error**: failed to read or decode input (JSON/YAML/etc.) |
| 5 | **Usage error**: invalid CLI arguments/options, invalid `--argjson` value, incompatible flags |

### Notes

- Without `-e`, empty output is still considered success (exit `0`).
- `-e` only affects the exit code; it should not change stdout formatting rules.

## Error Flow (stdout / stderr)

### stdout

- On success (exit `0` or `1`), `jq-lite` may write results to **stdout** as normal.
- On errors (exit `2`–`5`), `jq-lite` MUST NOT write partial/diagnostic output to stdout.

### stderr

- On errors (exit `2`–`5`), `jq-lite` writes a diagnostic message to **stderr**.
- The first line MUST start with a stable, machine-friendly prefix:

| Category | Prefix | Exit |
|----------|--------|------|
| Compile | `[COMPILE]` | 2 |
| Runtime | `[RUNTIME]` | 3 |
| Input | `[INPUT]` | 4 |
| Usage | `[USAGE]` | 5 |

#### Example

- `[COMPILE]unexpected token at ...`
- `[RUNTIME]cannot add number and string at ...`
- `[INPUT]failed to parse JSON input: ...`
- `[USAGE]invalid JSON for --argjson foo`

## `-e / --exit-status` Semantics

When `-e/--exit-status` is specified, `jq-lite` returns:

- `0` if the final result is **truthy**
- `1` if the final result is `false`, `null`, or **empty (no output)**

Truthiness rules (aligned with `jq` conventions):

- `false` → non-truthy
- `null` → non-truthy
- empty (no output) → non-truthy
- everything else (`0`, `""`, `{}`, `[]`, etc.) → truthy

## `--arg` and `--argjson`

### `--arg name value`

- Always binds `$name` as a **string**.
- Errors only occur for missing arguments (usage error).

### `--argjson name json`

- Decodes `json` as JSON and binds to `$name`.
- Scalar JSON values are allowed (e.g. `1`, `"x"`, `true`, `null`).
- Invalid JSON for `--argjson` MUST be treated as a **usage error**:
  - stderr prefix: `[USAGE]`
  - exit code: `5`

## Broken Pipe (SIGPIPE / EPIPE)

When downstream closes the pipe early (e.g. `jq-lite ... | head`):

- `SIGPIPE` / `EPIPE` MUST NOT be treated as a fatal error.
- `jq-lite` should exit `0` (or follow `-e` rules if applicable), without printing an error.

Rationale: this commonly occurs in pipelines and should not break scripts/CI.

## Compatibility Policy

- This contract is **stable**.
- Any behavior change that violates this document requires:
  - a major version bump, **or**
  - an explicit compatibility mode flag (discouraged; default must remain stable).

## Examples

### Compile error

```sh
jq-lite '.['
# stderr: [COMPILE]...
# exit: 2
````

### Runtime error

```sh
printf '{"x":"a"}\n' | jq-lite '.x + 1'
# stderr: [RUNTIME]...
# exit: 3
```

### Input error

```sh
printf '{broken}\n' | jq-lite '.'
# stderr: [INPUT]...
# exit: 4
```

### `-e` falsey result

```sh
printf 'false\n' | jq-lite -e '.'
# stdout: false
# exit: 1
```

### `--argjson` invalid JSON

```sh
jq-lite --argjson x '{broken}' '.'
# stderr: [USAGE]invalid JSON for --argjson x
# exit: 5
```
