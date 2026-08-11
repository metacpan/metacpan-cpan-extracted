# CLAUDE.md

MCP-Run bietet zwei Produkte:

1. **mcp-run-bash** (primär) – Ein stdio MCP-Server mit einem `run`-Tool, der
   Shell-Commands via `bash -c` ausführt und mit 30+ command-spezifischen
   Filtern komprimierte Ausgabe liefert. Für Claude Desktop, `.mcp.json` und
   andere MCP-Clients. Das ist das Hauptprodukt.
2. **mcp-run-compress** (Bonus) – Ein Claude Code PreToolUse Hook, der dieselbe
   Compression-Pipeline auf das eingebaute Bash-Tool von Claude Code anwendet.
   Praktisch: durch das Docker-Image (`raudssus/mcp-run-compress`) ist der Hook
   auch ohne Perl-Toolchain auf dem Host installierbar.

## Projektstruktur

```
p5-mcp-run/
├── bin/
│   ├── mcp-run-bash       # MCP stdio Server (PRIMÄR)
│   └── mcp-run-compress   # PreToolUse Hook + Installer (BONUS)
├── lib/
│   └── MCP/
│       ├── Run.pm         # Basis-Server mit run-Tool
│       └── Run/
│           ├── Bash.pm    # bash -c Execution via IPC::Open3
│           └── Compress.pm # Filter-Pipeline (30+ Filter)
├── t/                     # Tests
├── dist.ini               # [@Author::GETTY] + [@Author::GETTY::Docker]
└── Dockerfile             # Multi-stage build
```

## Key Commands

```bash
prove -l t              # Tests
prove -l t/10-bash.t    # Einzeltest
dzil build              # Distribution bauen
dzil test               # Test mit dzil
```

## mcp-run-bash (primär)

Einstieg: `mcp-run-bash` oder `MCP::Run::Bash->run_stdio`.

**Env-Vars:**
| Variable | Default | Beschreibung |
|----------|---------|-------------|
| `MCP_RUN_ALLOWED_COMMANDS` | alle | Komma-getrennte Whitelist |
| `MCP_RUN_WORKING_DIRECTORY` | cwd | Default Working Directory |
| `MCP_RUN_TIMEOUT` | 30 | Timeout in Sekunden |
| `MCP_RUN_COMPRESS` | Modul: 0, bin: 1 | Compression aktivieren (bin/mcp-run-bash default: 1) |
| `MCP_RUN_TOOL_NAME` | run | Name des MCP-Tools |

**Compression:** `compress: true` im Tool-Call oder `MCP_RUN_COMPRESS=1`. Der
original command wird an `$compressor->compress()` durchgereicht, sodass
command-spezifische Filter (ls, git, make, …) im MCP-Server-Modus greifen.

**Tool Schema:**
```json
{ "command": "ls -la", "working_directory": "/tmp", "timeout": 10, "compress": false }
```

## mcp-run-compress (Bonus)

Claude Code PreToolUse Hook für das eingebaute Bash-Tool. Wendet dieselbe
Compression-Pipeline auf Bash-Output von Claude Code an. Standalone via Docker
installierbar (`raudssus/mcp-run-compress`) — kein Perl auf dem Host nötig.

**Modi:**
- `native` (default): Hook ist `mcp-run-compress --hook`, rewrite zu `--b64`
- `docker`: Hook ist `docker run ... --hook`, host-seitiges Pipe-Snippet

**Env-Vars:**
| Variable | Default | Beschreibung |
|----------|---------|-------------|
| `MCP_RUN_COMPRESS_INSTALL_MODE` | native | native oder docker |
| `MCP_RUN_COMPRESS_IMAGE` | raudssus/mcp-run-compress:latest | Docker Image (pinned in image) |
| `MCP_RUN_COMPRESS_NO_CO_AUTHORED` | - | Co-Authored-By deaktivieren |
| `CO_AUTHORED_BY` | - | Replacement für Co-Authored-By |
| `ANTHROPIC_MODEL` | - | Fallback für CO_AUTHORED_BY |

**Bypass:**
- `no-compress <cmd>` – einzelne Command ohne Compression
- Background Commands werden nicht umgeschrieben
- Commands mit `mcp-run-compress` werden nicht umgeschrieben

## Architektur

**MCP::Run** (lib/MCP/Run.pm):
- Registriert das `run`-Tool
- Prüft `allowed_commands` und `validator`
- Ruft `execute` auf (subclass) und `format_result($tool, $result, $compress, $command)`

**MCP::Run::Bash** (lib/MCP/Run/Bash.pm):
- `execute()` via `IPC::Open3` als `bash -c`
- `IO::Select` für stdout/stderr
- `alarm` für Timeout → Exit 124
- Erbt `format_result()` von `MCP::Run`

**MCP::Run::Compress** (lib/MCP/Run/Compress.pm):
- 10-Stage Filter-Pipeline: strip_ansi, filter_stderr, match_output, transform, strip_lines, keep_lines, truncate, head/tail, max_lines, on_empty
- 30+ Command-spezifische Filter (ls, git, make, kubectl, cargo, cpanm, etc.)
- `_parse_command()` für git-style subcommands

## Testing Notes

**Vorhanden:**
- `t/00-load.t` – Load Tests
- `t/05-base.t` – Basis-Klasse
- `t/10-bash.t` – Bash Execution, allowlist, validator, timeout, format_result
- `t/20-integration.t` – MCP lifecycle (initialize, tools/list, tools/call)
- `t/compress.t` – Compression Tests
- `t/30-no-warnings.t` – Regression: Compress.pm warnings (transform returning undef, undef inputs)
- `t/40-compress-bin.t` – `bin/mcp-run-compress`: `--hook` (native + docker rewrite, bypasses, malformed), `--install-claude` (settings patching, idempotent, docker mode), `--filter-files`, end-to-end MCP compression mit echtem command context (`--b64`, incl. ls-Filter)

Die früher hier gelisteten „Fehlenden Tests" (`--hook`, `--install-claude`, Docker Rewrite, `--filter-files`, end-to-end MCP Compression) werden allesamt von `t/40-compress-bin.t` abgedeckt.

## Troubleshooting

**Hook wird nicht aufgerufen:**
1. `~/.claude/settings.json` prüfen – PreToolUse Hook für Bash muss existieren
2. `docker ps` zeigt Container? (bei docker mode)
3. Logs: `docker run --rm -i raudssus/mcp-run-compress --hook` manuell testen

**Compression funktioniert nicht im MCP-Modus:**
- `compress: true` im Tool-Call setzen
- `MCP_RUN_COMPRESS=1` als Env-Var
- Prüfe: `format_result` wird mit `$command` aufgerufen (lib/MCP/Run.pm)

## Release

```bash
dzil release
```

`[@Author::GETTY]` macht das Release: `GitHub::CreateRelease` legt das GitHub-Release
an (CPAN-Tarball als Asset, ChangeLog-Notes) und `[@Author::GETTY::Docker / compress]`
baut+pusht das Docker-Image (`raudssus/mcp-run-compress`, `MCP_RUN_VERSION` build-arg,
`compress` stage — nur der Compress-Hook, nicht die mcp-run-bash Runtime). Braucht
`~/.github-identity` und `docker login`. `dzil build`/`dzil test` bauen das Image
mit (Dev-Loop `prove -lr t/` unberührt).

## Links

- README.md – User-Dokumentation
- lib/MCP/Run/Compress/Filters.pm – Alle Filter mit POD
- dist.ini – [@Author::GETTY] config

## Sharp Edges (für Entwickler)

- `allowed_commands` prüft nur das erste Wort der raw command (lib/MCP/Run.pm) — kein Sandbox
- `working_directory` wird durch `cd '$dir' && ...` implementiert (lib/MCP/Run/Bash.pm), nicht chdir/open3
- `mcp-run-compress --b64` hat hardcoded 1800s Timeout (bin/mcp-run-compress)
- Hook schreibt nur die Bash command um, trifft keine Permission-Entscheidungen
- `transform_command` (Co-Authored-By) und `compress()` (Output-Filtering) sind verwandt aber unterschiedlich
- `mcp-run-bash` compression default ist AN (bin/mcp-run-bash), Modul-Attribut ist AUS (lib/MCP/Run.pm)
- `format_result($tool, $result, $compress, $command)` — bei Override in Subclasses muss der `$command` für command-spezifische Filter durchgereicht werden

## Weitere Runner-Ideen

`MCP::Run::Bash` ist heute die einzige `execute()`-Implementierung. Die
Architektur erlaubt es, weitere Runner als `MCP::Run`-Subklassen
hinzuzufügen — jede implementiert `execute($command, $wd, $timeout)`
und liefert denselben Hashref (`exit_code`, `stdout`, `stderr`,
optional `error`).

| Idee | Zweck | Aufwand |
|---|---|---|
| `MCP::Run::Shell` | Beliebige Shell (zsh, fish, dash) statt bash wählbar | klein — fast 1:1 von Bash.pm kopieren, nur das Binary wechselt |
| `MCP::Run::Python` | `python -c $command` als Alternative, mit gleichem Compression-Setup | klein — Subklasse, die statt `bash -c` Python aufruft |
| `MCP::Run::REPL` | Hält einen länger laufenden Interpreter-Process (bash / python / node), Antworten auf einzelne Snippets — kein Neustart pro Tool-Call | mittel — bidirektionale Pipes, Historie, Restart-Strategie |
| `MCP::Run::SSH` | `ssh user@host $command` mit key-basierter Auth | mittel — Auth-Setup, `known_hosts`-Handling, hop-by-hop-Timeout |
| `MCP::Run::Docker` | `docker exec <container> $command` — bereits ähnlich zum Docker-Rewrite im Compress-Hook, aber als eigener MCP-Tool | mittel — Container-Lifecycle, Image-Pinning, no-nework-Flag |
| `MCP::Run::kubectl` | `kubectl exec <pod> -- $command` für Cluster-Debugging | mittel — Pod-Auswahl, Container-Spec, Token-Refresh |
| `MCP::Run::Local` | Sandboxed Variante (kein bash -c, sondern allowlist von Binaries + Argumenten) | gross — echte Sandbox, nicht first-word-match |

Jede Subklasse bekommt gratis: Compression-Pipeline, Co-Authored-By-Override
(bei git commands), `allowed_commands`/`validator`, `format_result`.
Kompression muss nur aktiv sein, wenn der Runner selbst Output produziert;
für SSH/kubectl bleibt der Filter gleich, weil `command` weitergegeben wird.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/mcp-run-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `mcp-run-worker` |

The agent carries its skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.
The karr board (`refs/karr/*`) is the internal coordination channel.
