---
name: skeid-usage
description: Use when working on Skeid's billing side — the usage event as the billing unit, its fields and units, pricing and cache rates, the usage store backends (jsonlog, sqlite, postgresql) and the write-behind queue.
user-invocable: false
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

The **usage event** is the billing unit (ADR 0004). One event per forwarded request — or per
realtime session (ADR 0029: the session's length, its transcriptions' usage summed) — written
after `request.finish`, failures included (`ok = 0`). `record_usage` normalizes the metrics,
prices them from `model_pricing` at record time and hands the event to the store. The dispatch
names are `usage.record`, `usage.report`, `usage.configure`.

Reference: `docs/adr/0004-usage-events-are-the-billing-unit.md`,
`docs/adr/0013-cached-tokens-are-recorded-pricing-is-deferred.md`.

## What the event carries

- **Requested vs served model**: the event carries `model` (served — what costs money) *and*
  `requested_model` (what the customer bought). Dropping either breaks cost attribution silently.
- **Cache rates** price the provider-verbatim usage block through `Langertha::Usage`/`Pricing`
  into `cost_cache_read_usd` / `cost_cache_write_usd` (part of `cost_total_usd`; ADR 0013 update).
- **A stream** keeps the upstream usage block verbatim (frames merged key by key, later wins —
  counts are running totals, never summed) and prices it through the same `metrics.normalize` as
  a non-streamed answer, on every face (skeid #41).
- **Optional fields say "not measured" by being absent, never `0`** (ADR 0021): `content_bytes`
  (streams only), `audio_seconds` (audio, only when the node reports a duration), `documents`
  (rerank and documents, counted off the request, only when the node answered), `pages`
  (documents, read off `document.json_content.pages` of a JSON answer up to 8 MiB); the last three
  are recorded, not priced.
- `UsageStore::DBI` adds a missing column to a pre-existing table on `prepare` — that is the
  whole migration story; it never drops or rewrites a column.
- `node_metrics` is different: volatile in-memory ops counters, never billed.

## A new usage unit

Four places, always all four: the `record_usage` argument, a nullable column via
`@ADDED_COLUMNS` in `UsageStore::DBI`, a key `jsonlog` writes as is, and a sum in the report's
`totals` / `by_key` / `by_model` that `skeid usage` prints only when non-zero.

## Backends

Backend selection (`UsageStore->normalize_config`) is inference-first: explicit `backend` wins,
else `sqlite_path`/`path`/`db_path` → sqlite, `dbi:Pg:` dsn → postgresql, `log_path` →
jsonlog. `password_env` keeps the password out of the file. Schema from
`share/sql/usage_events.<backend>.sql` when `auto_migrate` (default on).

Override points, in order of preference: `usage_store` config → `store_usage_event` /
`query_usage_report` callbacks → subclass. `jsonlog` is the recommended default: it never blocks
the event loop on a database.

## Write-behind

`usage_store.flush_interval_ms` (sqlite/postgresql only; ADR 0005 update, skeid k78): `0`
(default) = synchronous write per event. `> 0` = write-behind: queued, written by a timer in one
transaction; also flushed on config reload (store swap), shutdown (`END` in `bin/skeid`), before a
usage report, and by `flush_usage`.

A kill without flush (`SIGKILL`, OOM) loses the queue and the billed requests in it. Under prefork
`SIGTERM`/`SIGINT` make the manager `SIGKILL` the workers (queue lost); `SIGQUIT` (the Docker
image's `STOPSIGNAL`) flushes. A lost event is reported on `on_usage_lost`, never silent.
`jsonlog` stays the recommendation; the deployment side of the queue is skill
`skeid-service-stack`.
