# Stable CLI Contract

This document defines the **stable CLI contract** for `jq-lite`.

Anything described here is treated as a **compatibility promise**:
any incompatible change **MUST** require a major version bump
(or an explicit compatibility mode, which is discouraged).

This contract is **test-backed** and enforced by automated tests.

---

## Goals

- Shell scripts and CI must be stable  
  (`if jq-lite ...; then ...; fi` must not break)
- Follow `jq` expectations where practical
- Distinguish error categories via **exit codes** and **stderr prefixes**
- Keep **stdout clean on errors**

---

## Compatibility Guarantee

- This contract is **stable**
- All behaviors documented here are **backward-compatible**
- Breaking changes require:
  - a **major version bump**, or
  - an explicit compatibility flag (not recommended)

---

## Exit Codes

`jq-lite` returns one of the following exit codes:

| Code | Meaning |
|------|--------|
| 0 | Success |
| 1 | `-e/--exit-status` specified and result is `false`, `null`, or **empty output** |
| 2 | **Compile error** (query / filter parse error) |
| 3 | **Runtime error** (evaluation failed) |
| 4 | **Input error** (failed to read or decode input) |
| 5 | **Usage error** (invalid CLI arguments, invalid `--argjson`, etc.) |

### Notes

- Without `-e`, empty output is still considered success (`exit 0`)
- `-e` affects **only the exit code**, never stdout formatting

---

## stdout / stderr Rules

### stdout

- On success (exit `0` or `1`):  
  output may be written to **stdout**
- On errors (exit `2`–`5`):  
  **stdout MUST remain empty**

### stderr

- On errors (exit `2`–`5`), a diagnostic message is written to **stderr**
- The **first line MUST start with a stable prefix**

| Category | Prefix | Exit |
|----------|--------|------|
| Compile | `[COMPILE]` | 2 |
| Runtime | `[RUNTIME]` | 3 |
| Input | `[INPUT]` | 4 |
| Usage | `[USAGE]` | 5 |

#### Examples

```

[COMPILE]unexpected token at ...
[RUNTIME]cannot add number and string at ...
[INPUT]failed to parse JSON input: ...
[USAGE]invalid JSON for --argjson x

````

---

## `-e / --exit-status` Semantics

When `-e/--exit-status` is specified, `jq-lite` returns:

| Result | Exit |
|------|------|
| truthy | 0 |
| false / null / empty | 1 |

### Truthiness Rules (jq-compatible intent)

- `false` → falsey
- `null` → falsey
- empty (no output) → falsey
- everything else (`0`, `""`, `{}`, `[]`, etc.) → truthy

> NOTE:  
> Current jq-lite behavior treats `0` as falsey.  
> This is a **known deviation** and will be fixed in a future release.

---

## `--arg`, `--argjson`, and `--argfile`

### `--arg name value`

- Always binds `$name` as a **string**
- Errors occur only for missing arguments (usage error)

### `--argjson name json`

- Decodes `json` as JSON and binds to `$name`
- Scalar JSON values are allowed
  (`1`, `"x"`, `true`, `null`)
- Invalid JSON for `--argjson` MUST be treated as a **usage error**:
  - stderr prefix: `[USAGE]`
  - exit code: `5`

### `--argfile name file`

- Reads `file` contents, decodes as JSON, and binds to `$name`
- Missing or unreadable `file` MUST be treated as a **usage error**:
  - stderr prefix: `[USAGE]`
  - exit code: `5`
- Invalid JSON for `--argfile` MUST be treated as a **usage error**:
  - stderr prefix: `[USAGE]`
  - exit code: `5`

---

## Broken Pipe (SIGPIPE / EPIPE)

When downstream closes the pipe early:

```sh
jq-lite '.' | head
````

* `SIGPIPE` / `EPIPE` MUST NOT be treated as a fatal error
* `jq-lite` should exit `0` (or follow `-e` rules)
* No error message should be printed to stderr

**Rationale**:
This commonly occurs in pipelines and must not break scripts or CI.

---

## Examples

### Compile Error

```sh
jq-lite '.[
# stderr: [COMPILE]...
# exit: 2
```

### Runtime Error

```sh
printf '{"x":"a"}\n' | jq-lite '.x + 1'
# stderr: [RUNTIME]...
# exit: 3
```

### Input Error

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

---

## Test-backed Guarantee

This contract is **enforced by automated tests**.

* Contract test:

  ```
  t/cli_contract.t
  ```

Run locally:

```sh
prove -lv t/cli_contract.t
```

Any change that violates this contract will fail CI.

---

## Known Deviations / TODO

The following items are **explicitly tracked** and will be improved:

* Compile should occur before input parsing
* `-e` truthiness should fully match jq (`0` should be truthy)
* `-n / --null-input` support

These do **not** invalidate the stability of the contract itself.

---

## Summary

* `jq-lite` provides a **stable, predictable CLI**
* Compatibility is **documented, intentional, and tested**
* Scripts, CI, and downstream tools can rely on this behavior

This file, together with `t/cli_contract.t`, defines the CLI contract.

---
