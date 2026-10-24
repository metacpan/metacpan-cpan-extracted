---
name: mcp-run-core
description: Load before editing p5-mcp-run — the mcp-run-bash server, the IPC::Open3 execution, the command allowlist, the MCP protocol contract.
user-invocable: false
model: inherit
---

# mcp-run-core

MCP-Run bietet zwei Produkte aus einer Codebasis:

1. **`mcp-run-bash`** (primär) — stdio MCP-Server mit einem `run`-Tool, das
   Shell-Commands via `bash -c` ausführt und mit 30+ command-spezifischen
   Filtern komprimierte Ausgabe liefert.
2. **`mcp-run-compress`** (Bonus) — Claude Code Hook, der dieselbe
   Compression-Pipeline auf das eingebaute Bash-Tool von Claude Code anwendet.

Hier steht die Server-Seite — Ausführung, Protokoll, Env-Vars. Pipeline, Hook,
Filter und die Compression-Env-Vars stehen in `mcp-run-compress`.

## Vocabulary

| Term | Meaning |
|------|---------|
| **tool** | Das MCP-Tool `run`, registriert via `MCP::Run` |
| **filter** | Einzelne Compression-Stage in `MCP::Run::Compress` |
| **stage** | Eine Position in der 11-Stage Pipeline |
| **wire format** | JSON über stdio (MCP-Protokoll) — einzige I/O-Variante |
| **hook** | Zwei Hooks für Claude Codes Bash-Tool: PreToolUse (Co-Authored-By, `no-compress`-Marker), PostToolUse (Compression) |
| **marker** | `\n# mcp-run-compress: no-compress`, von PreToolUse angehängt, von PostToolUse gelesen — PostToolUse sieht nur die *umgeschriebene* Command |
| **transform_command** | Co-Authored-By Manipulation (Hook) — verwandt aber ≠ compress |

## Layer Map

```
bin/mcp-run-bash       # Stdio MCP Server, primär
bin/mcp-run-compress   # Pre+PostToolUse Hook + Installer, Bonus (Compression in PostToolUse)
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
- **`working_directory` wird per `chdir` im Kindprozess gesetzt** (k42), nicht
  als `cd '$dir' &&`-Präfix: ein Präfix ließ Kettenglieder nach `;`, `&` oder
  Zeilenumbruch im Aufrufer-cwd laufen. Scheitert der `chdir`, meldet das Kind es
  über eine Close-on-exec-Pipe, der Befehl startet nie (Exit 1, Fehlertext).
- **Timeout → Exit 124.** Konvention wie GNU `timeout(1)`. Nicht eigene
  Exit-Codes erfinden.
- **MCP >= 0.15 ist Pflicht** (cpanfile-Pin, bewusst ohne Kompatibilitätsweichen).
  Ab 0.15 ist die Protocol-Revision Teil *jedes* Requests: `params._meta` braucht
  `protocolVersion` (gegen `MCP::Constants::SUPPORTED_VERSIONS`) und
  `clientCapabilities`, sonst weist `MCP::Server::_check_meta` **vor** dem Dispatch
  mit `Missing protocol version` ab. Wer im Test einen nackten
  `MCP::Server::Context` baut, umgeht den Transport und landet im modernen Pfad —
  dann fallen scheinbar unabhängige Subtests gleichzeitig um, und die eine echte
  Ursache versteckt sich hinter vier Symptomen. `initialize` heißt dort
  `server/discover`, `serverInfo` liegt in `result._meta`. Revision nie hardcoden,
  immer aus `MCP::Constants` ziehen.
- **Echte stdio-Clients laufen über `MCP::Server::Legacy`** (klassischer
  `initialize`-Handshake, `_check_meta` übersprungen) — deshalb war der
  Protokollbruch ein reines Testproblem. MCP dokumentiert diesen Pfad aber als
  temporär; wenn er fällt, verlieren Clients mit klassischem Handshake den Zugang
  zu `mcp-run-bash` (karr #7, offene Produktfrage).
- **`serverInfo` kommt aus Klassen-Defaults, nicht aus dem bin-Skript.**
  `MCP::Run::Bash` setzt `name`/`version` und überschreibt damit die
  `MCP::Server`-Defaults (`PerlServer`/`1.0.0`). Identität gehört in die Klasse,
  damit Library-Nutzer sie mitbekommen — nicht in `bin/mcp-run-bash`.

## Env-Vars MCP-Server

| Var | Default | Bedeutung |
|-----|---------|-----------|
| `MCP_RUN_ALLOWED_COMMANDS` | alle | Komma-Whitelist |
| `MCP_RUN_WORKING_DIRECTORY` | cwd | Default Working Directory |
| `MCP_RUN_TIMEOUT` | 30 | Sekunden |
| `MCP_RUN_COMPRESS` | bin: 1, modul: 0 | Compression aktiv |
| `MCP_RUN_TOOL_NAME` | run | Name des MCP-Tools |

## Test layout & traps

```
t/00-load.t          # Load Tests
t/05-base.t          # Basis-Klasse
t/10-bash.t          # bash -c, allowlist, validator, timeout, format_result
t/20-integration.t   # MCP lifecycle (server/discover, tools/list, tools/call)
                     # + protocol contract: fehlendes _meta / alte Revision
t/50-bash-bin.t      # bin/mcp-run-bash als Subprozess über echtes stdio
                     # (Legacy-Handshake): Compression an/aus, serverInfo-Identität
```

Die Compression-Tests: `mcp-run-compress`.

**Negative Assertions allein fangen einen toten Server nicht.** In `t/50-bash-bin.t`
gingen `unlike $text, qr/drwxr-xr-x/` und `unlike $text, qr/total \d+/` auf dem
kaputten Build *leer* durch — ein leeres Ergebnis enthält auch keine Rechte-Spalte.
Was den Test trägt, ist die positive Assertion (`like ... qr/^- README\.md$/m`)
gepaart mit einem `MCP_RUN_COMPRESS=0`-Lauf, der das rohe Listing behalten muss.
Erst diese Paarung verhindert, dass sich ein Crash durch stilles Abschalten der
Compression "beheben" lässt. Beim Schreiben von Filter-Tests immer so paaren.

**`prove -l t/` ist non-recursive** und überspringt nichts in Subdirs — alle
Tests liegen direkt unter `t/`, aber gewöhne dir trotzdem `prove -lr t/` an,
denn sobald jemand Subdirs anlegt (z.B. `t/live/`), werden die sonst still
übersprungen. **Trap:** "Tests grün" ist falsch, wenn Subdir-Tests still
gefiltert wurden.

## Release

`dist.ini` nutzt `[@Author::GETTY]` für das komplette Release: `GitHub::CreateRelease`
legt das GitHub-Release an (CPAN-Tarball als Asset, ChangeLog-Notes), und der
`[@Author::GETTY::Docker / compress]` Subsection baut+pusht das Docker-Image
(`raudssus/mcp-run-compress`, `target=compress`, `build_arg=MCP_RUN_VERSION=%v`).
Kein `maint/release-after.pl` mehr — die Bundle-Plugins machen alles. Braucht
`~/.github-identity` und `docker login`. Multi-Arch ist nicht wired (`Docker::API`
baut single-arch). Die Prozedur steht in `getty-perl-release-author-getty` und
`perl-release-dist-ini`.

## Conventions

- Style, Moose patterns, Module-Loading, cpanfile-Pinning: skill `getty-perl-core`
- Mojo::Base (Attribute, Defaults, lazy `sub {}`, Rollen) — die ganze Distribution
  baut darauf auf: skill `perl-mojo`
- Bundle/POD/Changes/{{$NEXT}} Konventionen: skill `getty-perl-release-author-getty`
- dist.ini Plugins: skill `perl-release-dist-ini`
- MCP-Server Setup (`MCP::Server`, `$server->tool()`): skill `perl-mcp`

Diese Skills sind non-negotiable — silently anwenden.
