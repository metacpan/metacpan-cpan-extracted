# Skeid examples and lab recipes

Scripts for trying Skeid against a real model server and for renting a GPU to do so. None of
this ships to CPAN users as an installed tool; run it from a checkout. The main
[`README.md`](../README.md) covers configuration and deployment. For measured, reproducible
numbers use `bench/` instead (fake model server in C, TTFT and throughput distributions); the
scripts here are smoke tests.

| File | What it is |
| --- | --- |
| `skeid-parallel-smoke.pl` | Parallel OpenAI chat-completion client with live progress and a summary |
| `skeid-onebox-flush.sh` | Writes a temporary config, starts Skeid, runs the smoke client, stops Skeid |
| `Dockerfile.vast` | Image with vLLM and Skeid for Vast.ai (`raudssus/langertha-skeid:vasttest`) |
| `build-vast-image.sh` | Builds (and optionally pushes) that image |
| `vast-start.sh` | On-start script inside that image: starts vLLM, then Skeid |
| `skeid-vast-onebox.sh` | Rents a Vast.ai GPU running that image, and manages the instance |
| `service/` | Docker compose stack: OpenBao + PostgreSQL + Skeid (see the main README) |

## skeid-parallel-smoke.pl

Sends `--requests` chat completions, at most `--concurrency` at a time, to one OpenAI-style
endpoint and prints a status line while it runs, then a summary (throughput, ok/fail, how many
answers had content, latency p50/p95/p99, status code counts) and a `RESULT` line. Exits 1 if
any request failed. Needs Mojolicious only.

```bash
perl examples/skeid-parallel-smoke.pl --base-url http://127.0.0.1:8090 \
  --model qwen2.5-7b-instruct --requests 100 --concurrency 20 --json
```

| Option | Default | Meaning |
| --- | --- | --- |
| `--base-url URL` | `http://127.0.0.1:8090` | Skeid or a model server; `/v1/chat/completions` is appended unless the URL already ends in it (`.../v1` gets `/chat/completions`) |
| `--model NAME` | `qwen2.5-7b-instruct` | model to request |
| `--requests`, `-n N` | `10` | total requests |
| `--concurrency`, `-c N` | `10` | requests in flight at once |
| `--timeout SEC` | `120` | request timeout (connect timeout is at most 20s) |
| `--max-tokens N` | `32` | `max_tokens` per request |
| `--prompt TEXT` | `Say hello in exactly three words.` | the user message |
| `--api-key KEY` | — | sent as `Authorization: Bearer KEY` |
| `--status-interval SEC` | `0.5` | how often the status line refreshes |
| `--show-errors` | off | print up to 20 failed requests at the end |
| `--json` | off | also print the summary as one JSON line |

Because the same client can talk to a model server directly, it is also the tool for a
before/after comparison: run it against the server, then against Skeid in front of it, with
the same model, prompt, request count and concurrency.

## skeid-onebox-flush.sh

Prepares, runs and cleans up a single-node test in one command:

1. writes `skeid.onebox.yaml` into a work directory: one node (`onebox-primary`) pointing at
   `BACKEND_URL`, a SQLite usage store in the same directory, `wait_timeout_ms: 6000`;
2. starts `bin/skeid serve` in the background (log: `skeid.log` in the work directory) and
   waits up to about 30 seconds for `/health`;
3. runs `skeid-parallel-smoke.pl` against Skeid with `--show-errors --json`;
4. stops Skeid, unless `KEEP_RUNNING=1`. The work directory is kept.

The usage store is SQLite, so `DBI` and `DBD::SQLite` must be installed.

| Variable | Default | Meaning |
| --- | --- | --- |
| `BACKEND_URL` | `http://5.9.97.19:32080/v1` | the model server (a lab host; set your own) |
| `ENGINE` | `vllm` | the node's engine id |
| `MODEL` | `Qwen/Qwen2.5-0.5B-Instruct` | the node's model and the model requested |
| `LISTEN` | `127.0.0.1:8090` | where Skeid listens; `0.0.0.0` is health-checked on 127.0.0.1 |
| `REQUESTS` | `10` | smoke `--requests` |
| `CONCURRENCY` | `10` | smoke `--concurrency` |
| `MAX_CONNS` | `4` | the node's `max_conns` |
| `MAX_TOKENS` | `32` | smoke `--max-tokens` |
| `PROMPT` | `Say hello in exactly three words.` | smoke `--prompt` |
| `TIMEOUT` | `120` | smoke `--timeout` |
| `KEEP_RUNNING` | `0` | `1` leaves Skeid running after the smoke |
| `WORK_DIR` | a new `/tmp/skeid-onebox.XXXXXX` | where config, log and usage database go |

With `CONCURRENCY` above `MAX_CONNS` the surplus requests wait in Skeid for a slot; any that
wait longer than 6 seconds get `429`, which shows up as failures in the summary.

```bash
# vLLM on this machine
BACKEND_URL=http://127.0.0.1:8000/v1 ENGINE=vllm MODEL=Qwen/Qwen2.5-0.5B-Instruct \
  ./examples/skeid-onebox-flush.sh

# SGLang, a larger model, more load
BACKEND_URL=http://127.0.0.1:30000/v1 ENGINE=sglang MODEL=Qwen/Qwen2.5-32B-Instruct \
  REQUESTS=60 CONCURRENCY=8 MAX_CONNS=8 MAX_TOKENS=64 ./examples/skeid-onebox-flush.sh

# the usage events of the run
bin/skeid usage --config /tmp/skeid-onebox.XXXXXX/skeid.onebox.yaml
```

## Recipe: comparing two engines on one host

To choose between two model servers for the same model (for example vLLM and SGLang side by
side on one GPU box):

1. Measure each directly with the same load:
   ```bash
   perl examples/skeid-parallel-smoke.pl --base-url http://HOST:PORT_VLLM/v1 \
     --model Qwen/Qwen2.5-0.5B-Instruct --requests 100 --concurrency 20 --json
   perl examples/skeid-parallel-smoke.pl --base-url http://HOST:PORT_SGLANG/v1 \
     --model Qwen/Qwen2.5-0.5B-Instruct --requests 100 --concurrency 20 --json
   ```
2. Put the faster one behind Skeid with `skeid-onebox-flush.sh` (`BACKEND_URL`, `ENGINE`) and
   repeat the load: the difference is what Skeid costs.
3. Only then try both behind one Skeid, as two nodes serving the same `model`, to see how
   weighted round-robin and `max_conns` spread the load. Write that config by hand; the
   one-box script has a single node.

## Vast.ai: vLLM and Skeid on a rented GPU

### The image

`Dockerfile.vast` builds Skeid's Perl dependencies (requires only, without recommends) in a
`perl:5.38-slim` stage and copies them, with the checkout, onto `vllm/vllm-openai:latest`. It
has no entrypoint: Vast.ai's SSH mode boots it and runs `/opt/skeid/vast-start.sh`. It accepts
the same `LANGERTHA_SRC` build argument as the main Dockerfile.

```bash
./examples/build-vast-image.sh          # builds raudssus/langertha-skeid:vasttest
./examples/build-vast-image.sh --push   # and pushes it
```

### vast-start.sh

Runs inside the instance. Starts `vllm serve $MODEL`, waits up to 600 seconds for its
`/v1/models`, then starts Skeid in front of it. Logs and pid files go to `/var/log/skeid/`
(`vllm.log`, `skeid.log`). Without `SKEID_CONFIG` it generates `/tmp/skeid.yaml`: one node
`local-vllm` at `http://127.0.0.1:$VLLM_PORT/v1`, engine `vllm`, a jsonlog usage store in
`/root/skeid-usage/`, `wait_timeout_ms: 6000`.

| Variable | Default |
| --- | --- |
| `MODEL` | `Qwen/Qwen2.5-0.5B-Instruct` |
| `VLLM_HOST` / `VLLM_PORT` | `0.0.0.0` / `8000` |
| `SKEID_LISTEN` | `0.0.0.0:8090` |
| `SKEID_CONFIG` | generated, see above |
| `MAX_CONNS` | `4` (the generated node's `max_conns`) |

### skeid-vast-onebox.sh

Needs the `vastai` CLI (`pip install vastai`) logged in (`vastai set api-key ...`), and Perl
for parsing its JSON.

```
skeid-vast-onebox.sh <action> [options]

  start               rent the cheapest matching datacenter offer in SSH mode and start
                      vLLM + Skeid through vast-start.sh; prints the Skeid, vLLM and SSH
                      addresses once the instance runs
  list-offers         cheapest verified, rentable datacenter offers (id, GPU, VRAM, $/h)
  list-instances      your instances
  status ID           one instance's state and addresses
  logs ID             last 200 lines of the instance log (vastai logs)
  ssh ID              ssh into the instance
  destroy [ID]        destroy that instance; WITHOUT an id, every instance running --image
```

| Option | Default | Meaning |
| --- | --- | --- |
| `--model NAME` | `Qwen/Qwen2.5-0.5B-Instruct` | passed to the instance as `MODEL` |
| `--gpu-type NAME` | any | case-insensitive match on the GPU name, e.g. `A40`, `H100`, `"RTX 4090"` |
| `--num-gpus N` | `1` | GPUs per offer |
| `--disk-gb N` | `80` | disk size |
| `--max-dph PRICE` | none | maximum price in $/hour |
| `--image IMAGE` | `raudssus/langertha-skeid:vasttest` (or `SKEID_VAST_IMAGE`) | image to run |
| `--hf-token TOKEN` | `HF_TOKEN` | passed to the instance for gated models |
| `--max-conns N` | `4` | passed to the instance as `MAX_CONNS` |
| `--limit N` | `20` | how many offers to search (the cheapest match is picked among them) |
| `--label NAME` | `skeid-onebox` | instance label |

```bash
./examples/skeid-vast-onebox.sh list-offers --gpu-type H100
./examples/skeid-vast-onebox.sh start --model Qwen/Qwen2.5-7B-Instruct --gpu-type A40 --max-dph 0.8
./examples/skeid-vast-onebox.sh ssh 12345678      # then: tail -f /var/log/skeid/*.log
./examples/skeid-vast-onebox.sh destroy 12345678
```

The instance exposes 8000 (vLLM) and 8090 (Skeid); `start` prints their mapped host ports.
From outside, run `skeid-parallel-smoke.pl` against both addresses to compare vLLM direct
with vLLM behind Skeid. Rented instances cost money until destroyed.

## service/

The OpenBao + PostgreSQL + Skeid compose stack. Setup, caveats and the KeyBroker are in the
main README, section "Service stack (OpenBao + PostgreSQL)". Files: `docker-compose.yml`,
`skeid.yaml` (with commented examples for aliases, policies and probes), `init-skeid.sh`
(one-shot AppRole, policy and provider-key setup, run in the OpenBao image), `.env.example`.
The usage table comes from `share/sql/` — Skeid applies it on start.
