# Langertha House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Langertha — a unified Perl interface for LLM APIs: ~25 engines via composable Moose roles
(chat, tool calling/MCP, streaming, embeddings, transcription, structured output). The
autonomous agent (Raider) lives in the sibling distribution langertha-raider. Single
distribution — one board, no cross-repo handoff. Read first: exports, immediate callers,
shared roles; "looks orthogonal" is dangerous, especially across the engine/role mesh.

## Agent team

The lane table and the natural agent chain live in `CLAUDE.md`. Read-only research, audit or
gap analysis goes to `langertha-worker` ("read-only, change nothing"); a read-only diff review
to `langertha-reviewer`. The orchestrator's lane here also covers writing and curating ADRs.

Behavior-relevant = runtime behavior, public API, engine request/response handling, the tool
wire-translation seam (`tool_wire_format` + the Tool/ToolCall/ToolResult/ToolChoice value
objects), the capability registry, the Raider loop, streaming, async, MCP integration, error
handling, tests, performance. Pure prose docs, ADRs, and `Changes` notes are not.

## Release

The `[@Author::GETTY]` bundle bumps `$VERSION` and tags on release.

## Deviations from the house rules

- **Public tracker (`github.com/Getty/langertha`) — not even reading on your own initiative.**
  No listing, viewing, commenting, editing, closing or creating unless the user explicitly
  tells you to handle a specific public item; every write is confirmed first because it
  publishes under the maintainer's name. Full `gh` usage + guardrails: skill
  `langertha-github-issues`.

## Live tests & real spend — never arm by accident

The env-gated live tests (`t/8x`) spend the maintainer's real money at every keyed provider.
`prove` / `dzil test` themselves are fine anytime — the danger is arming them by accident:

- **Never source `.env` (or set any `TEST_LANGERTHA_*`) in the same shell command as `prove`,
  `dzil test`, or anything recursive over `t/`.** One such command exports every key into the
  run and fires the *whole* live suite against *every* keyed provider — real spend, no
  approval. It has happened: a single `set -a && . ./.env && … && prove -lr t/` ran the whole
  suite across ~16 providers, image generation included (write-up: `langertha-core`).
- Key or fixture checks that need `.env` run in their **own** command — a subshell that ends
  before any `prove`. Before a suite run, assert the environment is clean:
  `[ "$(env | grep -c TEST_LANGERTHA)" = 0 ]`, or isolate it:
  `env -i PATH="$PATH" HOME="$HOME" prove -lr t/`.
- **Never print the process environment** (`env`, `printenv`, a fall-through `env -u …`): it
  carries the provider keys. Count, never list: `env | grep -c TEST_LANGERTHA`.
- Live calls otherwise need explicit approval (AKI.IO is the standing exception). When you
  dispatch a worker or subagent, pass this hard rule on — it inherits your keys, not your care.
- **"Tests pass" must name the skips** — the env-gated live tests `t/8x` skip without keys;
  say so.
