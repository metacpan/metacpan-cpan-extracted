---
name: mcp-run-core
description: Architecture and invariants for p5-mcp-run — the MCP-Run distribution. Two products (mcp-run-bash MCP server, mcp-run-compress Claude Code hook), shared compression pipeline, IPC::Open3 execution, [@Author::GETTY] release bundle.
user-invocable: false
model: inherit
---

# mcp-run-core

MCP-Run bietet zwei Produkte aus einer Codebase:

1. **`mcp-run-bash`** (primär) — stdio MCP-Server mit einem `run`-Tool, das
   Shell-Commands via `bash -c` ausführt und mit 30+ command-spezifischen
   Filtern komprimierte Ausgabe liefert.
2. **`mcp-run-compress`** (Bonus) — Claude Code PreToolUse Hook, der dieselbe
   Compression-Pipeline auf das eingebaute Bash-Tool von Claude Code anwendet.

## Vocabulary

| Term | Meaning |
|------|---------|
| **tool** | Das MCP-Tool `run`, registriert via `MCP::Run` |
| **filter** | Einzelne Compression-Stage in `MCP::Run::Compress` |
| **stage** | Eine Position in der 10-Stage Pipeline |
| **wire format** | JSON über stdio (MCP-Protokoll) — einzige I/O-Variante |
| **hook** | PreToolUse Hook für Claude Code's Bash-Tool |
| **rewrite** | Umschreiben von `Bash`-Tool-Calls zu `mcp-run-compress --b64` |
| **transform_command** | Co-Authored-By Manipulation (Hook) — verwandt aber ≠ compress |

## Layer Map

```
bin/mcp-run-bash       # Stdio MCP Server, primär
bin/mcp-run-compress   # PreToolUse Hook + Installer, Bonus
lib/MCP/Run.pm         # Basis-Server, registriert das `run`-Tool
lib/MCP/Run/Bash.pm    # bash -c via IPC::Open3
lib/MCP/Run/Compress.pm        # Filter-Pipeline + 30+ command-Filter
lib/MCP/Run/Compress/Filters.pm # Filter-Definitionen mit POD
```

`MCP::Run::Bash` erbt `format_result` von `MCP::Run`. Compression ist nur aktiv,
wenn `$compress` true und der Caller den `$command` durchreicht — bei Override
in Subclasses **muss** `$command` weitergegeben werden, sonst greifen die
command-spezifischen Filter nicht.

## Core invariants

- **`allowed_commands` ist KEIN Sandbox.** Es prüft nur das erste Wort der raw
  command — `bash -c 'rm -rf /'` mit `allowed_commands => ['bash']` läuft.
  Echte Sandboxing ist eine separate Diskussion; nicht "fixen" wollen.
- **`working_directory` wird per `cd '$dir' && ...`** umgesetzt, nicht via
  `chdir`/`open3`. Heißt: quoted-paths-Escaping muss korrekt sein
  (`lib/MCP/Run/Bash.pm`, single-quote-Escape).
- **Timeout → Exit 124.** Konvention wie GNU `timeout(1)`. Nicht eigene
  Exit-Codes erfinden.
- **`mcp-run-bash` Compression default = AN** (bin/mcp-run-bash), aber
  Modul-Attribut default = AUS (lib/MCP/Run.pm). Beide Defaults sind intentional
  und **nicht** angleichen.
- **Hook schreibt nur die Bash command um**, trifft keine Permission-Entscheidung.
  Permission ist Claude Code's Job.
- **`mcp-run-compress --b64` hat hardcoded 1800s Timeout** — beim Touchen prüfen,
  ob das noch zeitgemäß ist (kommt aus dem Bonus-Hook, nicht aus dem MCP-Server).

## Pipeline (Compression)

10-Stage Filter-Pipeline in `MCP::Run::Compress`:

`strip_ansi → filter_stderr → match_output → transform → strip_lines → keep_lines → truncate → head/tail → max_lines → on_empty`

`_parse_command()` erkennt git-style subcommands, damit die 30+ Command-Filter
(ls, git, make, kubectl, cargo, cpanm, …) matchen können.

## Env-Vars MCP-Server

| Var | Default | Bedeutung |
|-----|---------|-----------|
| `MCP_RUN_ALLOWED_COMMANDS` | alle | Komma-Whitelist |
| `MCP_RUN_WORKING_DIRECTORY` | cwd | Default Working Directory |
| `MCP_RUN_TIMEOUT` | 30 | Sekunden |
| `MCP_RUN_COMPRESS` | bin: 1, modul: 0 | Compression aktiv |
| `MCP_RUN_TOOL_NAME` | run | Name des MCP-Tools |

## Env-Vars Hook

| Var | Default | Bedeutung |
|-----|---------|-----------|
| `MCP_RUN_COMPRESS_INSTALL_MODE` | native | native oder docker |
| `MCP_RUN_COMPRESS_IMAGE` | raudssus/mcp-run-compress:latest | Docker Image |
| `MCP_RUN_COMPRESS_NO_CO_AUTHORED` | — | Co-Authored-By deaktivieren |
| `CO_AUTHORED_BY` | — | Replacement |
| `ANTHROPIC_MODEL` | — | Fallback für CO_AUTHORED_BY |

**Bypass-Mechanismen** (nicht entfernen, sind intentional):
- `no-compress <cmd>` — einzelne Command ohne Compression
- Background-Commands werden nicht umgeschrieben
- Commands die `mcp-run-compress` selbst enthalten werden nicht umgeschrieben

## Test layout & traps

```
t/00-load.t          # Load Tests
t/05-base.t          # Basis-Klasse
t/10-bash.t          # bash -c, allowlist, validator, timeout, format_result
t/20-integration.t   # MCP lifecycle (initialize, tools/list, tools/call)
t/compress.t         # Compression
```

**`prove -l t/` ist non-recursive** und überspringt nichts in Subdirs — alle
Tests liegen direkt unter `t/`, aber gewöhne dir trotzdem `prove -lr t/` an,
denn sobald jemand Subdirs anlegt (z.B. `t/live/`), werden die sonst still
übersprungen. **Trap:** "Tests grün" ist falsch, wenn Subdir-Tests still
gefiltered wurden.

## Release

`dist.ini` nutzt `[@Author::GETTY]` mit `run_after_release` (GitHub Release +
Docker Hub push).

```bash
dzil release
# mit multi-arch Docker:
MCP_RUN_DOCKER_BUILD_ARGS='--platform linux/amd64,linux/arm64' dzil release
```

`run_after_release` ist im Bundle konfiguriert — `maint/release-after.pl` macht
den Rest. GH_BIN/DOCKER_BIN überschreibbar.

## Conventions

- Style, Moose patterns, Module-Loading, cpanfile-Pinning: skill `perl-core`
- Bundle/POD/Changes/{{$NEXT}} Konventionen: skill `perl-release-author-getty`
- dist.ini Plugins: skill `perl-release-dist-ini`
- MCP-Server Setup (`MCP::Server`, `$server->tool()`): skill `perl-mcp`

Diese Skills sind non-negotiable — silently anwenden.