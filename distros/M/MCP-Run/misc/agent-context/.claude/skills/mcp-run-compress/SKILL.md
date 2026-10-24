---
name: mcp-run-compress
description: Load before changing the compression in p5-mcp-run — the 11-stage filter pipeline, the command filters, the PreToolUse/PostToolUse hook, the marker and the compression environment.
user-invocable: false
model: inherit
---

# mcp-run-compress — Pipeline, Hook, Filter

Die Compression-Hälfte von MCP-Run: die Filter-Pipeline in `MCP::Run::Compress`,
der Claude-Code-Hook in `bin/mcp-run-compress` und die Env-Vars, die beide steuern.
Der Server, die Ausführung und das MCP-Protokoll stehen in `mcp-run-core`.

## Die 11-Stage Pipeline

`MCP::Run::Compress` filtert in dieser Reihenfolge:

`filter_stderr → strip_ansi → collapse_cr → match_output → transform → strip_lines → keep_lines → truncate → head/tail → max_lines → on_empty`

`collapse_cr` ist unkonditional und kennt kein Filter-Attribut. Grund: ein
Fortschrittsbalken ist für `split /\n/` eine einzige Zeile, `max_lines` greift
dort nicht, und 28 der 48 Filter setzen kein `truncate_lines_at` — ohne die
Stufe liefe ein 224-KB-Balken bei `cargo build`, `make`, `npm install` und
`docker build` unverändert durch. Die Stufe ist identitätserhaltend, wenn kein
`\r` vorkommt (über 56 Command-Varianten byte-identisch nachgemessen).

`_parse_command()` erkennt git-style subcommands, damit die 30+ Command-Filter
(ls, git, make, kubectl, cargo, cpanm, …) matchen können. Die Filter selbst
stehen in `MCP::Run::Compress::Filters` (mit POD).

## Der Hook

Zwei Hooks für Claude Codes Bash-Tool:

- **PreToolUse** — hängt den `no-compress`-Marker an die Command und schreibt
  Co-Authored-By (`transform_command`).
- **PostToolUse** — komprimiert die Ausgabe. Die Command wird nicht mehr
  umgeschrieben; `--b64` und `--filter-files` gibt es nicht mehr, mit ihnen sind
  der hardcodierte 1800s-Timeout und das Docker-Pipe-Snippet verschwunden.

**Der Hook trifft keine Permission-Entscheidung.** Permission ist Claude Codes Job.
Deshalb wird der `no-compress`-Marker *angehängt* und nicht vorangestellt: das erste
Wort der Command ist das, wogegen Claude Code Permission-Regeln matcht.

**Drei Grenzen, alle bewusst:**

- Commands mit Exit ≠ 0 werden gar nicht komprimiert (dort feuert
  PostToolUseFailure und ignoriert `updatedToolOutput`, karr #24).
- Background-Commands haben zur Hook-Laufzeit noch keine Ausgabe.
- Zwei PostToolUse-Hooks verketten sich nicht — jeder sieht das Original, der
  letzte gewinnt, lautlos.

**Bypass-Mechanismen** (nicht entfernen, sind intentional):

- `no-compress <cmd>` — einzelne Command ohne Compression
- Background-Commands werden nicht umgeschrieben
- Commands die `mcp-run-compress` selbst enthalten werden nicht umgeschrieben

## Invarianten

- **`mcp-run-bash` Compression default = AN** (bin/mcp-run-bash), aber
  Modul-Attribut default = AUS (lib/MCP/Run.pm). Beide Defaults sind intentional
  und **nicht** angleichen.
- **`MCP::Run::Compress` wird compile-time geladen** (`use` in lib/MCP/Run.pm),
  obwohl `_get_compressor` lazy konstruiert. Absicht: ein fehlendes Compress-Modul
  soll den Server beim **Start** umbringen, nicht beim ersten `tools/call`. Genau
  das fehlte bis 0.105 und machte jeden `tools/call` in der Default-Konfiguration
  unbrauchbar. Nicht in ein `require` im Lazy-Loader zurückbauen.

## Env-Vars Hook

| Var | Default | Bedeutung |
|-----|---------|-----------|
| `MCP_RUN_COMPRESS_INSTALL_MODE` | native | native oder docker |
| `MCP_RUN_COMPRESS_IMAGE` | raudssus/mcp-run-compress:latest | Docker Image |
| `MCP_RUN_COMPRESS_MAX_BYTES` | 29000 | Deckel der ersetzten Ausgabe; darüber persistiert der Harness sie und zeigt 2 KB Preview |
| `MCP_RUN_COMPRESS_NO_CO_AUTHORED` | — | Co-Authored-By deaktivieren |
| `CO_AUTHORED_BY` | — | Replacement. Validiert: Wörter plus optional `<mail@host>`, sonst wird der Command unverändert gelassen |
| `ANTHROPIC_MODEL` | — | Fallback für CO_AUTHORED_BY, gleiche Einschränkung |

## Tests

```
t/compress.t          # Compression
t/30-no-warnings.t   # Regression: Compress.pm warnings (transform undef, undef inputs)
t/40-compress-bin.t  # bin/mcp-run-compress: --hook (PreToolUse + PostToolUse),
                     # --install-claude inkl. Migration alter Installationen,
                     # Byte-Deckel, Background-Bypass, fail-open
t/60-filters-doc.t   # Filters.pm gegen die registrierte Filtertabelle (Drift-Wächter)
```

**Filter-Tests immer paaren** — die Assertion-Falle steht in `mcp-run-core`.
