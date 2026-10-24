# CLAUDE.md

MCP-Run bietet zwei Produkte:

1. **mcp-run-bash** (primär) – Ein stdio MCP-Server mit einem `run`-Tool, der
   Shell-Commands via `bash -c` ausführt und mit 30+ command-spezifischen
   Filtern komprimierte Ausgabe liefert. Für Claude Desktop, `.mcp.json` und
   andere MCP-Clients. Das ist das Hauptprodukt.
2. **mcp-run-compress** (Bonus) – Ein Claude Code Hook, der dieselbe
   Compression-Pipeline auf das eingebaute Bash-Tool von Claude Code anwendet.
   Komprimiert in PostToolUse; PreToolUse macht nur Co-Authored-By und die
   `no-compress`-Markierung.
   Praktisch: durch das Docker-Image (`raudssus/mcp-run-compress`) ist der Hook
   auch ohne Perl-Toolchain auf dem Host installierbar.

## Projektstruktur

```
p5-mcp-run/
├── bin/
│   ├── mcp-run-bash       # MCP stdio Server (PRIMÄR)
│   └── mcp-run-compress   # PostToolUse-Compression + PreToolUse-Hook + Installer (BONUS)
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
| `MCP_RUN_TIMEOUT` | 30 | Timeout in Sekunden. Ganze Zahl 1..2147483647, sonst bricht der Start ab (kein stiller Default) |
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

Claude Code Hook für das eingebaute Bash-Tool. Wendet dieselbe
Compression-Pipeline auf Bash-Output von Claude Code an. Standalone via Docker
installierbar (`raudssus/mcp-run-compress`) — kein Perl auf dem Host nötig.

**Zwei Hooks, ein Kommando.** `--install-claude` registriert `mcp-run-compress
--hook` auf zwei Events; das Skript dispatcht über `hook_event_name`:
- **PostToolUse** komprimiert, via `hookSpecificOutput.updatedToolOutput`. Die
  Command wird nicht angefasst.
- **PreToolUse** macht nur, was *vor* der Ausführung passieren muss:
  Co-Authored-By und die `no-compress`-Markierung.

Der `--b64`-Rewrite und `--filter-files` sind **weg**, mit ihnen der
hardcodierte 1800s-Timeout und das Docker-Pipe-Snippet.

**Modi** (wählen nur die Kommandozeile in settings.json, der Code ist derselbe):
- `native` (default): `mcp-run-compress --hook`
- `docker`: `docker run --rm -i --network none ... --hook`

**Env-Vars:**
| Variable | Default | Beschreibung |
|----------|---------|-------------|
| `MCP_RUN_COMPRESS_INSTALL_MODE` | native | native oder docker |
| `MCP_RUN_COMPRESS_IMAGE` | raudssus/mcp-run-compress:latest | Docker Image (pinned in image) |
| `MCP_RUN_COMPRESS_MAX_BYTES` | 29000 | Obergrenze der ersetzten Ausgabe. Darüber persistiert der Harness sie und zeigt dem Modell 2 KB Preview — schlechter als gar nicht komprimieren. Greift nur, wenn es eine Rohdatei gibt, auf die verwiesen werden kann |
| `MCP_RUN_COMPRESS_NO_CO_AUTHORED` | - | Co-Authored-By deaktivieren |
| `CO_AUTHORED_BY` | - | Replacement für Co-Authored-By (validiert: Wörter + optional `<mail@host>`, sonst kein Trailer) |
| `ANTHROPIC_MODEL` | - | Fallback für CO_AUTHORED_BY |

**Bypass:**
- `no-compress <cmd>` – PreToolUse streift das Präfix und hängt
  `\n# mcp-run-compress: no-compress` an; PostToolUse liest die Markierung.
  Nötig, weil PostToolUse **nur die umgeschriebene Command sieht**
- Background Commands haben zur Hook-Laufzeit noch keine Ausgabe

**Drei Grenzen, alle bewusst:**
- Commands mit Exit ≠ 0 werden **gar nicht** komprimiert — dort feuert
  `PostToolUseFailure`, und das ignoriert `updatedToolOutput` (karr #24)
- Background Commands, siehe oben
- Zwei PostToolUse-Hooks verketten sich nicht: jeder sieht das Original, der
  zuletzt antwortende gewinnt — lautlos

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
- 11-Stage Filter-Pipeline: filter_stderr, strip_ansi, collapse_cr, match_output, transform, strip_lines, keep_lines, truncate, head/tail, max_lines, on_empty
- `collapse_cr` läuft unkonditional, nicht per Filter-Attribut: es reduziert je
  Zeile die `\r`-getrennten Segmente auf das letzte nicht-leere, bildet also ab,
  was im Terminal steht. Ohne die Stufe gingen Fortschrittsbalken (cargo, npm,
  docker, pip, wget) ungekürzt durch — sie sind für `split /\n/` **eine** Zeile,
  und 28 der 48 Filter setzen kein `truncate_lines_at`
- 30+ Command-spezifische Filter (ls, git, make, kubectl, cargo, cpanm, etc.)
- `_parse_command()` für git-style subcommands

## Testing Notes

**Vorhanden:**
- `t/00-load.t` – Load Tests
- `t/05-base.t` – Basis-Klasse
- `t/10-bash.t` – Bash Execution, allowlist, validator, timeout, format_result
- `t/20-integration.t` – MCP lifecycle (server/discover, tools/list, tools/call) plus protocol contract: Requests ohne `params._meta` bzw. mit nicht unterstützter Protocol-Revision werden abgewiesen
- `t/compress.t` – Compression Tests
- `t/30-no-warnings.t` – Regression: Compress.pm warnings (transform returning undef, undef inputs)
- `t/40-compress-bin.t` – `bin/mcp-run-compress`: `--hook` auf beiden Events (PostToolUse-Compression inkl. `persistedOutputPath`, Byte-Deckel mit Marker, Background-Durchreichung; PreToolUse Co-Authored-By und `no-compress`-Markierung), `--install-claude` inkl. Migration alter 0.106-Installationen, fail-open bei kaputtem `@INC`
- `t/50-bash-bin.t` – `bin/mcp-run-bash` als Subprozess über echtes stdio (Legacy-Handshake): Compression an/aus, `serverInfo`-Identität, `MCP_RUN_TIMEOUT`-Validierung. Deckt den Pfad ab, den echte Clients nehmen — genau dort, wo der Compress-Ladefehler durchrutschte
- `t/60-filters-doc.t` – Drift-Wächter: gleicht die `=item`-Einträge in `Filters.pm` gegen die registrierte Filtertabelle ab, in beide Richtungen. Existiert, weil `Filters.pm` reine Doku ist, von keinem Code geladen wird und deshalb jahrelang unbemerkt auseinanderlief

**Zwei Tests, die eine Regel festnageln statt eines Verhaltens:** der
Äquivalenztest in `t/compress.t` (107 Commands × 16 Ausgabeformen × 4
stderr-Varianten) besteht darauf, dass `compress()` und `process()` dieselbe
Pipeline sind — er ist die Absicherung dafür, dass die beiden nicht wieder
auseinanderlaufen. Und der Kollisionstest daneben besteht darauf, dass pro
Command höchstens ein ausgabeformender Filter je Art matcht; wer einen
kollidierenden Filter hinzufügt, bekommt einen Fehlschlag mit der Aufforderung,
eine explizite Vorrangregel zu setzen. Beide laufen über mehrere
`PERL_HASH_SEED`-Werte, sonst wären sie zufällig grün.

## Troubleshooting

**Hook wird nicht aufgerufen:**
1. `~/.claude/settings.json` prüfen – es müssen **zwei** Einträge für Bash
   existieren, PostToolUse (Compression) und PreToolUse (Co-Authored-By,
   `no-compress`). Fehlt der PostToolUse-Eintrag, ist es eine Installation von
   vor dem Umbau: `mcp-run-compress --install-claude` erneut laufen lassen
2. Claude Code liest Hook-Änderungen erst in einer neuen Session
3. `docker ps` zeigt Container? (bei docker mode)
4. Logs: `docker run --rm -i raudssus/mcp-run-compress --hook` manuell testen

**Ausgabe ist unkomprimiert, obwohl der Hook läuft:** drei erwartbare Gründe,
bevor man sucht – der Command ist mit Exit ≠ 0 gelaufen (dort feuert
`PostToolUseFailure`, siehe karr #24), es war ein Background-Command, oder ein
**anderer** PostToolUse-Hook auf Bash antwortet nach uns und gewinnt lautlos.

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

Die Entwickler-Invarianten und Fallen (kein-Sandbox `allowed_commands`,
`working_directory` als `chdir` im Kindprozess (fehlendes Verzeichnis = Fehler ohne Ausführung), der Byte-Deckel, PostToolUse-Compression und
die Permission-Grenze des Hooks, die zwei intentionalen Compression-Defaults,
`format_result`-Threading, MCP >= 0.15 und der `MCP::Server::Legacy`-Pfad, das
Compile-Zeit-`use` von `MCP::Run::Compress`, `serverInfo`-Identität) sind die einzige
Quelle der Wahrheit in skill `mcp-run-core` — in jeden `mcp-run-*` Agenten gebrieft.
Nicht hier duplizieren; für Details dorthin.

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
| Commits, `Changes`, card → done, pre-release audit | `mcp-run-release-manager` |

The agent carries its skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.
The karr board (`refs/karr/*`) is the internal coordination channel.
