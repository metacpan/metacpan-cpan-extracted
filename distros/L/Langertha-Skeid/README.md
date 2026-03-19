# Skeid — Langertha Routing Control Plane

`Langertha::Skeid` is the dynamic control-plane companion to Knarr.

- Live node inventory and weighted routing
- OpenAI/Anthropic/Ollama proxy frontends
- Engine IDs map 1:1 to Langertha engines
- Normalized usage + cost accounting
- Dynamic YAML reload on each task dispatch
- Built-in usage store: `jsonlog` (recommended), `sqlite`, or `postgresql`
- Pluggable usage backend: override via callback or subclass

## Install

```bash
cpanm --installdeps .
```

## Run Proxy

```bash
bin/skeid serve --listen 127.0.0.1:8090 --config skeid.yaml
```

Supported routes:

- OpenAI: `POST /v1/chat/completions`, `POST /v1/embeddings`, `GET /v1/models`
- Anthropic: `POST /v1/messages`
- Ollama: `POST /api/chat`, `GET /api/tags`, `GET /api/ps`

Admin routes:

- `GET /skeid/nodes`
- `POST /skeid/nodes`
- `POST /skeid/nodes/:id/health`
- `GET /skeid/metrics/nodes`
- `GET /skeid/usage`

Admin route protection:

- If no admin key is configured, `/skeid/*` returns `404` (effectively disabled).
- If configured, all `/skeid/*` routes require `Authorization: Bearer <admin-key>`.
- Admin key is dynamic config (`admin.api_key` or `admin_api_key`) and is reloaded on request dispatch.

## Cloud Provider Scenario (Multi-API + Billing)

Skeid can run as a provider gateway in front of many upstream APIs (cloud + local),
route requests by model, and persist normalized token/cost usage for billing.

Typical setup:

1. Register many upstream nodes (for example OpenAI-compatible cloud endpoints and local vLLM/SGLang).
2. Define model pricing in `pricing` to normalize cost per request.
3. Send a tenant key id in `x-skeid-key-id` (or `x-api-key-id`) on each request.
4. Read tenant/model totals via `GET /skeid/usage` or `bin/skeid usage --json`.

This gives you one unified API edge and one usage ledger for invoice/export workflows.

## YAML Config

`nodes[].engine` uses the same engine naming as Langertha engine classes:
lowercased class short name.

Examples:

- `Langertha::Engine::OpenAIBase` -> `openaibase`
- `Langertha::Engine::Anthropic` -> `anthropic`
- `Langertha::Engine::vLLM` -> `vllm`

Use the concrete engine when known (`openai`, `groq`, `anthropic`, ...).
Use `openaibase` for generic OpenAI-compatible backends.

Legacy aliases like `openai-compatible` are intentionally not supported.

### Engine Matrix (Langertha -> Skeid ID)

| Langertha Engine Class | Skeid `engine` |
| --- | --- |
| `AKI` | `aki` |
| `AKIOpenAI` | `akiopenai` |
| `Anthropic` | `anthropic` |
| `AnthropicBase` | `anthropicbase` |
| `Cerebras` | `cerebras` |
| `DeepSeek` | `deepseek` |
| `Gemini` | `gemini` |
| `Groq` | `groq` |
| `HuggingFace` | `huggingface` |
| `LMStudio` | `lmstudio` |
| `LMStudioAnthropic` | `lmstudioanthropic` |
| `LMStudioOpenAI` | `lmstudioopenai` |
| `LlamaCpp` | `llamacpp` |
| `MiniMax` | `minimax` |
| `Mistral` | `mistral` |
| `NousResearch` | `nousresearch` |
| `Ollama` | `ollama` |
| `OllamaOpenAI` | `ollamaopenai` |
| `OpenAI` | `openai` |
| `OpenAIBase` | `openaibase` |
| `OpenRouter` | `openrouter` |
| `Perplexity` | `perplexity` |
| `Remote` | `remote` |
| `Replicate` | `replicate` |
| `SGLang` | `sglang` |
| `vLLM` | `vllm` |
| `Whisper` | `whisper` |

```yaml
pricing:
  "*":
    input_per_million: 0.10
    output_per_million: 0.40

nodes:
  - id: vllm-a
    url: http://127.0.0.1:21001/v1
    model: qwen2.5-7b-instruct
    engine: vllm
    weight: 1
    max_conns: 128

usage_store:
  backend: sqlite
  sqlite_path: /data/skeid/usage.sqlite

admin:
  api_key: change-me

routing:
  wait_timeout_ms: 2000
  wait_poll_ms: 25
```

Equivalent env/CLI options:

- `SKEID_ADMIN_API_KEY=...`
- `bin/skeid serve --admin-api-key ...`

Cloud-mix example:

```yaml
nodes:
  - id: cloud-openai
    url: https://api.openai.com/v1
    model: gpt-4o-mini
    engine: openai
    max_conns: 64
  - id: cloud-groq
    url: https://api.groq.com/openai/v1
    model: llama-3.3-70b-versatile
    engine: groq
    max_conns: 64
  - id: local-vllm-a
    url: http://vllm-a:8000/v1
    model: qwen2.5-7b-instruct
    engine: vllm
    max_conns: 128
```

`sqlite_path` is required for `backend: sqlite`. Skeid creates the SQLite file and applies schema automatically.

DBI and DBD::SQLite are optional (`recommends`). When no backend is configured and no override is provided, usage tracking is gracefully disabled.

### jsonlog Backend (recommended)

No DBI needed. Two modes:

**Directory mode** (one file per event — recommended, no collision risk):

```yaml
usage_store:
  backend: jsonlog
  path: /var/log/skeid/events/
```

Each event is written as a separate `.json` file. Directory mode is auto-detected when the path is an existing directory or ends with `/`.

**File mode** (JSON-lines in a single file):

```yaml
usage_store:
  backend: jsonlog
  path: /var/log/skeid/usage.jsonl
  mode: file
```

Events are appended as one JSON line each, with file locking.

### Custom Usage Backend

You can replace the storage layer without subclassing — pass callbacks as constructor parameters:

```perl
my $skeid = Langertha::Skeid->new(
  store_usage_event => sub {
    my ($self, $event) = @_;
    # $event has all 22 normalized columns (created_at, api_key_id,
    # model, input_tokens, output_tokens, cost_total_usd, ...)
    publish_to_nats($event);
    return { ok => 1 };
  },
  query_usage_report => sub {
    my ($self, $filters) = @_;
    # $filters: since, api_key_id, model, limit
    return { ok => 1, enabled => 1, totals => { ... } };
  },
);
```

Or subclass and override `_store_usage_event` / `_query_usage_report`:

```perl
package MyApp::Skeid;
use Moo;
extends 'Langertha::Skeid';

sub _store_usage_event {
  my ($self, $event) = @_;
  # custom storage logic
  return { ok => 1 };
}
```

When a callback or override is active, no DBI connection is created.

PostgreSQL option:

```yaml
usage_store:
  backend: postgresql
  dsn: dbi:Pg:dbname=skeid;host=postgres;port=5432
  user: skeid
  password_env: SKEID_USAGE_DB_PASSWORD
```

Schema SQL files (simple and explicit):

- `share/sql/usage_events.sqlite.sql`
- `share/sql/usage_events.postgresql.sql`

## Docker Build (Temporary CPAN Indexer Bypass)

Default build flow:

```bash
docker build -t raudssus/langertha-skeid .
```

If CPAN indexers lag behind current `Langertha`/`Knarr` releases, pass direct CPAN dist paths:

```bash
docker build -t raudssus/langertha-skeid \
  --build-arg LANGERTHA_SRC='GETTY/Langertha-0.307.tar.gz' \
  --build-arg KNARR_SRC='GETTY/Langertha-Knarr-0.007.tar.gz' \
  .
```

Both args are forwarded to `cpanm` (for example `AUTHOR/Dist-x.yyy.tar.gz` or a tarball URL).

## Docker Quickstart (SQLite)

1. Config + Data-Verzeichnis anlegen:

```bash
mkdir -p ./skeid-config ./skeid-data
cat > ./skeid-config/skeid.yaml <<'YAML'
pricing:
  "*":
    input_per_million: 0.10
    output_per_million: 0.40

nodes:
  - id: vllm-a
    url: http://host.docker.internal:21001/v1
    model: qwen2.5-7b-instruct
    engine: vllm

usage_store:
  backend: sqlite
  sqlite_path: /data/skeid/usage.sqlite
YAML
```

2. Container starten:

```bash
docker run -d --name skeid \
  -p 8090:8090 \
  -v "$PWD/skeid-config:/etc/skeid:ro" \
  -v "$PWD/skeid-data:/data/skeid" \
  raudssus/langertha-skeid \
  bin/skeid serve --listen 0.0.0.0:8090 --config /etc/skeid/skeid.yaml
```

3. Schnell prüfen:

```bash
curl -s http://127.0.0.1:8090/health
docker exec -it skeid bin/skeid usage --config /etc/skeid/skeid.yaml
```

Hinweis: `sqlite_path` muss auf ein beschreibbares Volume zeigen, damit Usage-Daten persistent bleiben.

## Beispiel: Avatar Setup (2x vLLM + 2x SGLang)

Fertige Config:

- `examples/avatar-skeid.yaml`

Schnellstart:

```bash
mkdir -p ./skeid-config ./skeid-data
cp ./examples/avatar-skeid.yaml ./skeid-config/skeid.yaml

docker run -d --name skeid \
  -p 8090:8090 \
  -v "$PWD/skeid-config:/etc/skeid:ro" \
  -v "$PWD/skeid-data:/data/skeid" \
  raudssus/langertha-skeid \
  bin/skeid serve --listen 0.0.0.0:8090 --config /etc/skeid/skeid.yaml
```

Wenn deine Ports anders sind, nur die `url`-Felder in der YAML anpassen.

## Avatar 2-Node Smoke (vLLM + SGLang)

Empfohlener Ablauf:

1. vLLM vs SGLang direkt vergleichen (gleiche Last, gleiche Prompt).
2. Gewinner als Single-Engine in Skeid fahren.
3. Erst danach optional Multi-Node/Mix testen.

Direkter Vergleich (ohne Skeid) mit dem gleichen Smoke-Tool:

```bash
# vLLM direkt
perl ./examples/skeid-parallel-smoke.pl \
  --base-url http://5.9.97.19:32080/v1 \
  --model Qwen/Qwen2.5-0.5B-Instruct \
  --requests 100 \
  --concurrency 20 \
  --json

# SGLang direkt
perl ./examples/skeid-parallel-smoke.pl \
  --base-url http://5.9.97.19:32081/v1 \
  --model Qwen/Qwen2.5-0.5B-Instruct \
  --requests 100 \
  --concurrency 20 \
  --json
```

Dann Single-Engine-Konfig verwenden:

- `examples/avatar-skeid-single.yaml`

Optionaler Mix/Verteilungstest mit zwei Targets:

- `examples/avatar-skeid-2nodes.yaml`
- `examples/skeid-parallel-smoke.pl`

1. Config kopieren und zwei URL-Felder setzen:

```bash
cp ./examples/avatar-skeid-2nodes.yaml ./skeid.avatar.yaml
# edit ./skeid.avatar.yaml
```

2. Skeid lokal starten:

```bash
bin/skeid serve --listen 127.0.0.1:8090 --config ./skeid.avatar.yaml
```

3. Smoke mit 10 parallelen Requests:

```bash
perl ./examples/skeid-parallel-smoke.pl \
  --base-url http://127.0.0.1:8090 \
  --model Qwen/Qwen2.5-0.5B-Instruct \
  --requests 10 \
  --concurrency 10 \
  --show-errors
```

4. Danach Last hochdrehen:

```bash
perl ./examples/skeid-parallel-smoke.pl \
  --base-url http://127.0.0.1:8090 \
  --model Qwen/Qwen2.5-0.5B-Instruct \
  --requests 200 \
  --concurrency 40
```

## One-Box Flush (prepare + run + cleanup)

Wenn du alles in einem Schritt auf einer einzelnen Kiste testen willst:

```bash
# Default: vLLM backend on 5.9.97.19:32080
./examples/skeid-onebox-flush.sh
```

Mit explizitem Backend/Engine:

```bash
# vLLM
BACKEND_URL=http://5.9.97.19:32080/v1 \
ENGINE=vllm \
MODEL=Qwen/Qwen2.5-0.5B-Instruct \
./examples/skeid-onebox-flush.sh

# SGLang
BACKEND_URL=http://5.9.97.19:32081/v1 \
ENGINE=sglang \
MODEL=Qwen/Qwen2.5-0.5B-Instruct \
./examples/skeid-onebox-flush.sh
```

Das Script macht:

1. temp YAML + SQLite usage DB vorbereiten
2. `bin/skeid serve` starten und `/health` abwarten
3. `examples/skeid-parallel-smoke.pl` mit Parallel-Requests fahren
4. Skeid beenden und temp Daten behalten

Nützliche Env-Parameter:

- `REQUESTS` (default `10`)
- `CONCURRENCY` (default `10`)
- `MAX_CONNS` (default `4`)
- `LISTEN` (default `127.0.0.1:8090`)
- `KEEP_RUNNING=1` (lässt Skeid nach dem Smoke laufen)

Vast.ai one-box Beispiel (Skeid + Backend auf derselben Maschine):

```bash
BACKEND_URL=http://127.0.0.1:8000/v1 \
ENGINE=vllm \
MODEL=Qwen/Qwen2.5-0.5B-Instruct \
LISTEN=0.0.0.0:8090 \
REQUESTS=100 \
CONCURRENCY=20 \
./examples/skeid-onebox-flush.sh
```

Vast.ai “dickeres Modell” Beispiel (wenn das Modell auf dem Host geladen ist):

```bash
BACKEND_URL=http://127.0.0.1:8000/v1 \
ENGINE=sglang \
MODEL=Qwen/Qwen2.5-32B-Instruct \
LISTEN=0.0.0.0:8090 \
REQUESTS=60 \
CONCURRENCY=8 \
MAX_CONNS=8 \
MAX_TOKENS=64 \
./examples/skeid-onebox-flush.sh
```

Vast.ai mit API-Key (CLI oder optional Override) + optionalem Docker-Backend-Start:

```bash
# Vast CLI installieren (einmalig)
python3 -m pip install --user vastai

# vLLM backend + Skeid smoke in einem Ablauf
./examples/skeid-vast-onebox.sh \
  --start-backend \
  --backend vllm \
  --model Qwen/Qwen2.5-32B-Instruct \
  --hf-token "$HF_TOKEN" \
  --requests 60 \
  --concurrency 8 \
  --max-conns 8
```

Der Vast-Runner macht standardmäßig 3 Phasen:

1. Direct backend baseline auf safe concurrency (ohne Proxy-Overload)
2. Skeid proxy run auf derselben safe concurrency
3. Skeid proxy overload run (Queue sichtbar), danach Delta-Ausgabe

Wichtige Tuning-Flags:

- `--overload-factor 2`
- `--baseline-min-req 20`
- `--probe-max-conc 32` (optional, default `0` = aus)
- `--no-queue-test` (nur Single-Pass)

Vast Offer/Instance Übersicht (inkl. VRAM):

```bash
# Unterstützte GPU-Typen für --gpu-type
./examples/skeid-vast-onebox.sh --list-gpu-types

# Markt-Angebote (id, GPU, VRAM, Preis)
./examples/skeid-vast-onebox.sh --list-offers

# Nur ein GPU-Typ (z. B. H100-SXM), plus günstigste Offer-Hinweiszeile
./examples/skeid-vast-onebox.sh --list-offers --gpu-type h100-sxm

# Eigene Instanzen (id, GPU, VRAM, Status)
./examples/skeid-vast-onebox.sh --list-instances

# Rohes vastai JSON (falls du selbst parsen willst)
./examples/skeid-vast-onebox.sh --list-offers --list-raw
```

Provision mit automatischer günstigster Offer pro GPU-Typ:

```bash
./examples/skeid-vast-onebox.sh \
  --provision \
  --gpu-type h100-sxm \
  --num-gpus 1 \
  --rent-limit 50 \
  --rent-disk-gb 120 \
  --rent-label skeid-h100
```

Hinweise:

- `--backend vllm` ist Default.
- `--start-backend` ist standardmäßig **aus** (nur aktiv, wenn explizit gesetzt).
- `--num-gpus` ist standardmäßig `1`.

Wenn du Backend bereits selbst startest, `--start-backend` weglassen und nur URL setzen:

```bash
./examples/skeid-vast-onebox.sh \
  --backend-url http://127.0.0.1:8000/v1 \
  --engine sglang \
  --model Qwen/Qwen2.5-32B-Instruct

# Optional (nur wenn du CLI-Key nicht gesetzt hast):
# --vast-api-key "$VAST_API_KEY"
```

## Docker: Usage aus SQLite abrufen

Skeid intern:

```bash
docker exec -it skeid bin/skeid usage --config /etc/skeid/skeid.yaml
docker exec -it skeid bin/skeid usage --config /etc/skeid/skeid.yaml --json
```

Direkt per SQL (separater sqlite3-Container):

```bash
docker run --rm -v "$PWD/data:/data" keinos/sqlite3 \
  sqlite3 /data/skeid/usage.sqlite \
  "SELECT created_at, api_key_id, model, status_code, total_tokens, cost_total_usd FROM usage_events ORDER BY id DESC LIMIT 50;"
```

## Docker: PostgreSQL Report

```bash
docker exec -it skeid bin/skeid usage \
  --backend postgresql \
  --dsn 'dbi:Pg:dbname=skeid;host=postgres;port=5432' \
  --db-user skeid \
  --db-pass-env SKEID_USAGE_DB_PASSWORD \
  --json
```

## Usage CLI

```bash
skeid usage [--config skeid.yaml] [--since 2026-03-10T00:00:00Z] [--limit 100] [--json]
```

Optional filters:

- `--api-key-id k_...`
- `--model qwen2.5-7b-instruct`

## Saturation Behavior

Wenn alle passenden Nodes auf `max_conns` stehen, wartet Skeid kurz auf einen freien Slot:

- `routing.wait_timeout_ms` (Default: `2000`)
- `routing.wait_poll_ms` (Default: `25`)

Das Waiting ist non-blocking (Mojo IOLoop Timer), sodass der Proxy parallel weitere Requests bedienen kann.

Bei Erfolg wird die Anfrage normal weitergeleitet. Wenn bis Timeout kein Slot frei wird, gibt Skeid `429 rate_limit_error` zurueck.
