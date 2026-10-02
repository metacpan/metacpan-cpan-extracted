---
name: langertha-testing
description: Use when writing, reviewing or debugging a test in Langertha's t/ — request-building, response-fixture, mocked-async, local-HTTP-daemon or live-gated tests.
---

# Langertha tests

`Test2::Bundle::More`. A test encodes **why** a behavior matters; one that cannot fail when
that behavior changes is wrong. Never weaken an assertion to go green.

## Pick the layer that proves the claim

| Claim | Layer | How |
|---|---|---|
| What goes on the wire | request building | `$engine->chat(...)` etc. build an `HTTP::Request` without sending. Decode the body with a canonical `JSON::MaybeXS` and `is_deeply` the payload (`t/20_chat_requests.t`). |
| How a server answer is read | response parsing | Feed an `HTTP::Response` into `chat_response`. Use **verbatim captures** from `t/data/` (`<engine>_<case>.json` + `<engine>_<case>.headers.json`), read with `Path::Tiny` `slurp_raw`, never decoded and re-encoded (`t/28_aki_fixtures.t`). |
| `_f` orchestration, tool loops, `chat_f` rewrites | mocked async | `Test::MockAsyncHTTP` (`t/lib/Test/`) injected via the `_async_http => $mock` constructor arg; script its responses, assert on its recorded requests. |
| HTTP backends, streaming, error / abort / truncation | transport boundary | Real LWP / `Net::Async::HTTP` against `Test::LocalHTTPDaemon` (`t/lib/Test/LocalHTTPDaemon.pm`, `->start(sub { $http_response })`, `->url`; a CODE-ref content is sent chunked). Reference: `t/45_sync_http_real_lwp.t`. |
| What a provider accepts today | live | Only when asked. See below. |

Hard-won rules behind the table:

- **Hand-written payloads drift** toward what the code expects, not what the server sends.
  That is how karr #92 hid for months. New response-parsing coverage replays a capture.
- **Never simulate a library's callback behavior.** A mock that fired LWP's content callback
  on a non-2xx response made k188's streaming bugs pass green. Anything at the HTTP boundary
  gets a real round-trip against the local daemon; a mock is for orchestration only, and its
  behavior must be checked against the real library's source.
- **`ok(defined $response)`, not `ok($response)`.** A tool-call-only `Langertha::Response`
  has empty content and stringifies false.
- **Sync/async parity** (ADR 0027): the same `_f` call must give the same result and error
  text with `Net::Async::HTTP`, an injected client and the sync LWP shim. Cover the error and
  truncation paths, not only the happy path.

## Live tests

Live files are the ones gated on an env var, not a number range:

- API-key gated (`TEST_LANGERTHA_<ENGINE>_API_KEY`): `80_live_tool_calling`, `81_live_aki`,
  `82_live_embedding`, `83_live_chat`, `83_live_minimax`, `84_live_imagegen`,
  `85_live_perplexity`, `85_live_responses`, `86_live_prompt_cache`,
  `86_live_reasoning_effort`, `88_live_hetzner`.
- Server-URL gated (self-hosted, `TEST_LANGERTHA_*_URL`): `87_live_vllm_hook`,
  `88_live_vllm_reasoning`, `89_runtime_metrics_live`.
- `89_langertha_sugar.t` is **not** live.

Refresh the list with `grep -l 'TEST_LANGERTHA_' t/*.t` and read the `BEGIN` block (a comment
mention is not a gate). Gate in `BEGIN` and `plan skip_all` cleanly without the variable
(model: `t/83_live_chat.t`). Live calls spend the maintainer's money: none without explicit
approval, AKI.IO is the standing exception. TSystems has no key at all — its behavior is
documentation-derived and has no live test.

## House shape

- Header: `#!/usr/bin/env perl`, `# ABSTRACT: …`, `use strict; use warnings;`,
  `use Test2::Bundle::More;`. Helpers via `use lib 't/lib';` (the common form).
- Right under the `use` lines, a comment saying **why** the behavior matters, naming the
  karr ticket or ADR. That comment is the intent a later reader needs.
- Numbered by area; take the number of the closest existing test: `0x` load / hierarchy,
  `1x` auth / rate limit, `2x` request building, `3x` Ollama, `4x` streaming / async /
  transport, `5x` models / metrics, `6x` tool calling, `7x` response / capabilities /
  POD catalogue, `8x` live, `9x` value objects / plugins / chat API.
- Helpers live in `t/lib/Test/`; captures in `t/data/`; third-party test deps go under
  `on 'test'` in the cpanfile.
- A regression or TDD red test must **fail for the stated reason** before the fix; quote
  the failure line in the report.

## Running

`prove -lv t/NN_name.t` for one file, then `prove -lr t/` or `dzil test` for the suite —
`prove -l t/` is not recursive and skips any subdirectory. Report skipped live tests as
skipped, never as passed.

**Never arm the live suite by accident.** The `t/8x` files gate on `TEST_LANGERTHA_*` in the
environment, so any command that sources `.env` (or sets a `TEST_LANGERTHA_*`) *and* then runs
`prove` / `dzil test` fires the whole live suite against every keyed provider — real spend, no
approval. Keep key/fixture checks that need `.env` in their own command; before a suite run
assert a clean environment with `[ "$(env | grep -c TEST_LANGERTHA)" = 0 ]`, or isolate the run
as `env -i PATH="$PATH" HOME="$HOME" prove -lr t/`. Never print the process environment
(`env` / `printenv`) — it carries the keys; count, don't list.
