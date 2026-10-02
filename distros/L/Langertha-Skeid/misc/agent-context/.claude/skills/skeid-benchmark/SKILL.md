---
name: skeid-benchmark
description: Use when measuring Skeid — the bench/ harness, TTFT and throughput methodology, comparing against other proxies, and the resource discipline a shared box needs.
user-invocable: false
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

`bench/` answers one question: what does putting Skeid in the path cost, and where does it stop
scaling? It answers with measurements. Reasoning about the code is not an answer here.

Reference: `bench/README.md` for flags,
`docs/adr/0007-benchmarks-use-a-deterministic-fake-model.md` for why the harness looks like
this, `docs/bench/` for results.

## The harness

| | |
|---|---|
| `bench/fakellm.c` | OpenAI-compatible server simulating a model with a chosen timing envelope |
| `bench/llmbench.c` | measuring client — TTFT and totals as p50/p95/p99, req/s, tok/s |
| `bench/run-bench.sh` | baseline + proxy, json + stream, one concurrency |
| `bench/skeid.bench.yaml` | one node at fakellm, jsonlog usage, no key broker |

```bash
cd bench && make
./run-bench.sh --requests 320 --concurrency 16
```

Neither program is shipped to CPAN (`gather_exclude_match` in `dist.ini`).

## Method — in this order, every time

1. **Verify the instrument.** Baseline streaming TTFT must come out at `--ttft-ms`, and
   non-streaming total at `ttft + (tokens-1)/rate`. If the fake model does not agree with its
   own settings, nothing downstream means anything.
2. **Baseline first.** Same client, same flags, straight at `fakellm`. Report the delta.
3. **One variable per comparison.** Server flags, client flags, git rev — one.
4. **Distributions, not means.** p50/p95/p99 and the sample count. A mean TTFT hides the tail
   where one blocked request stalled twenty others, which is the failure mode worth finding.
5. **Quote the invocation.** Every figure carries its command and git rev, or it must not be
   repeated later.
6. **Name the gaps.** Real models, GPU contention, TLS, network, cold start, KeyBroker,
   database usage stores. Say what was not measured rather than letting a reader assume.

## Reading a result

- **Overhead at c=1** is Skeid's serial cost per request: routing, admission, header
  forwarding, the upstream transaction, the usage write.
- **Throughput ceiling at high concurrency** is one event loop per CPU — one process unless
  `serve --workers N` (see `docs/bench/2026-08-09-prefork-workers.md`); `run-bench.sh` starts
  a single worker. A ceiling is not the same finding as a stall: a *blocked* event loop shows
  up as p99 far above p50 and requests serialised behind whole upstream responses. A CPU
  ceiling raises everything together.
- **Streaming vs JSON** differ because the relay spreads work across the response while the
  JSON path decodes and re-encodes one lump at the end.
- **A number without a baseline is an anecdote.** Do not quote one.

## Comparing against other systems

`llmbench` targets any OpenAI-compatible endpoint, so a comparison is the same command with a
different port. Point the other gateway at `fakellm` too — then every system serves an identical
model and the gateway is the only difference.

```bash
./run-bench.sh --no-start --proxy-port 4000 --label "LiteLLM 1.x"
```

Be fair and say what differs: a gateway that meters every request, resolves a key per request
and translates protocols is doing more work than one that forwards bytes. Report which work,
not just which number.

## Resource discipline — not optional

Small shared machine, other people's services on it.

1. **One benchmark run at a time.** Never in the background, never fanned out across agents.
2. Bind `fakellm` to `127.0.0.1`. It has no authentication.
3. Raise `--concurrency` deliberately, and write the number into the report.
4. `nice -n 19 ionice -c3` for anything long-running.
5. Kill what you started. `run-bench.sh` traps EXIT; a manual run is your responsibility.

## When you find something

A regression goes back as a `karr` ticket with the reproduction command and both numbers, for
`skeid-worker` or `skeid-protocol-worker` to fix. A proposed optimisation that measures as
nothing gets said just as loudly — a negative result that stops a refactor is the most valuable
output this harness has.

The first run (`docs/bench/2026-08-08-baseline.md`) found that SSE streaming was broken end to
end, which the test suite had not caught because no test drove a real streamed response over a
real socket. That is the shape of bug this harness exists for: correct headers, correct status,
empty body.
