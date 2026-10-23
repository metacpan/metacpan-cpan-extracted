---
name: langertha-core
description: "Use when working inside the Langertha distribution itself — the repo map (engines, roles, value objects, request layer), the one-way dependency to the sibling distributions langertha-raider, langertha-knarr and langertha-skeid, the engine/role mesh coupling, the live-suite spend gate, the [@Author::GETTY] release wiring and the repo mechanics. Calling Langertha is perl-ai-langertha, changing core is langertha-internals, testing it is langertha-testing."
---

# Langertha core — the map behind the code

`langertha` is the LLM framework itself: one engine class per provider, one canonical API on
top. Three other skills cover the *work*: `perl-ai-langertha` is the caller's guide,
`langertha-internals` holds the invariants for changing core, `langertha-testing` the test
layers. This skill is the **map** — what lives where, which way the dependencies point, what
the release actually does, and the two traps that cost real money and real time.

## The repo map

| Area | Path | What lives there |
|---|---|---|
| Engines | `lib/Langertha/Engine/` | one class per provider (~40 modules): `Anthropic`, `OpenAI`, `Gemini`, `Ollama`, `vLLM`, `SGLang`, `LlamaCpp`, `LMStudio`, `DeepSeek`, `Groq`, `Mistral`, `Perplexity`, `Replicate`, `Cerebras`, `Scaleway`, `TSystems`, `XAI`, `Hetzner`, `HuggingFace`, `MiniMax`, `Moonshot`, `NousResearch`, `AKI*`, `Mock`, `Virtual` and the OpenAI/Anthropic-compatible shims |
| Engine bases | `lib/Langertha/Engine/{OpenAIBase,AnthropicBase,TranscriptionBase,Remote}.pm` | the shared wire of a family; `Remote` = engines with a format of their own |
| Roles | `lib/Langertha/Role/` | the composable capabilities an engine consumes: `Chat`, `Tools`, `Streaming`, `Embedding`, `ImageGeneration`, `PromptCache`, `ReasoningEffort`, `Capabilities`, `PluginHost`, … |
| Value objects | `lib/Langertha/{Tool,ToolCall,ToolResult,ToolChoice,Reasoning,PromptCache,Moment}.pm` | what every wire format serializes |
| Core classes | `lib/Langertha/{Response,Stream,RunContext,Result}.pm` | what a call returns, plus the two dependency-free primitives |
| Request layer | `lib/Langertha/{Request,HTTP,Input,Output,Spec}/` | transport and the input/output value objects |
| Provider manifest | `lib/Langertha/Manifest.pm` | the provider capability manifest (ADR 0029) |
| Tests | `t/` | the layers `0x` … `8x`; the `8x` layer is live and costs money |
| Decisions | `docs/adr/` | ADRs 0001–0039; the format is skill `langertha-adr` |
| Vocabulary | `CONTEXT.md` | the resolved wire vocabulary — read it before changing the seam |

Two entries are stubs on purpose: `Langertha::Result` is a reserved-namespace stub (its
implementation moved to raider, the stub stays for CPAN index continuity), and the lazy
`use Langertha qw( Raider )` sugar in `Langertha.pm` lights up only once langertha-raider is
installed. Do not "fix" a stub by moving code back.

## The family — one-way, always

| Distribution | Owns | Depends on |
|---|---|---|
| **langertha** (this repo) | engines, roles, value objects, the canonical API | — |
| langertha-raider | the autonomous agent (`Langertha::Raider`, `Raider::Result`) and the Raid orchestration layer | `requires 'Langertha'` |
| langertha-knarr | the LLM proxy: OpenAI / Anthropic / Ollama / A2A / ACP / AG-UI in, any Langertha engine out, Langfuse tracing | `requires 'Langertha'` |
| langertha-skeid | the routing service: one Mojolicious process fronting many LLM nodes | `requires 'Langertha'` |

The dependency points one way: **core never requires a sibling.** A sibling may use core's
public surface; core may not reach into a sibling. When a core change breaks a sibling, the
change is not done until the sibling is checked. The siblings pin an exact `Langertha`
version in their `cpanfile` — when core's version moves, those pins move with it; the
release-manager owns that.

Each sibling has its own board, its own agents, its own rules file. Tickets are the only
legal channel between the repos.

## The mesh: why "looks orthogonal" is dangerous

An engine is not a class with methods — it is a base class plus a set of roles, and each role
carries a piece of the provider's wire format. Three couplings bite:

- **A role is part of the engine's wire contract.** Adding a role to an engine changes the
  request it puts on the wire and the response it accepts. "The role is orthogonal" is a
  guess until you have read the callers.
- **The capability registry has three layers.** `%ROLE_TO_CAPS` → `engine_capabilities` →
  `model_capability_corrections` and the exclusions. A new capability flag is only done when
  all three agree; a flag that exists in one layer only produces answers that disagree with
  the code.
- **The tool seam has one owner.** `tool_wire_format` dispatches the serializers of the
  Tool/ToolCall/ToolResult/ToolChoice value objects, and `chat_f` rewrites the request when
  the wire reality demands it (a provider that speaks `response_format` where the caller
  asked for a schema, a forced tool choice). Every case lands as a `Langertha::ToolCall` on
  `Response.tool_calls` — including the synthetic ones. A second translation path is a bug,
  not an optimization.

The invariants, the per-role details and the "adding an engine — done means all of these"
checklist live in skill `langertha-internals`; the public API in `perl-ai-langertha`.

## The live suite spends the maintainer's real money

`t/8x` is the live layer: `80_live_tool_calling`, `81_live_aki`, `82_live_embedding`,
`83_live_chat`, `83_live_minimax`, `84_live_imagegen`, `85_live_perplexity`,
`85_live_responses`, `86_live_prompt_cache`, `86_live_reasoning_effort`,
`87_live_vllm_hook`, `88_live_hetzner`, `88_live_vllm_reasoning`, `89_runtime_metrics_live`.
Without a key each of them skips; with a key every one of them talks to a real provider and
costs money. Image generation costs the most.

**The incident.** One shell command — `set -a && . ./.env && … && prove -lr t/` — sourced
every provider key into the run and fired the whole live suite at once: ~16 providers, image
generation included, no approval, real spend. The environment was the trigger; the suite was
only the effect. That is why the rule in the rules file is phrased on the *command*, not on
the test file.

**The gate.** Before any suite run assert a clean environment:
`[ "$(env | grep -c TEST_LANGERTHA)" = 0 ]`, or isolate it entirely:
`env -i PATH="$PATH" HOME="$HOME" prove -lr t/`. Checks that need a key run in their own
command, in a subshell that ends before any `prove`. Never print the environment — count,
never list. Layers, fixtures and the local HTTP daemon: skill `langertha-testing`.

## Release wiring — what this repo adds to `[@Author::GETTY]`

`dist.ini` is thin: the `[@Author::GETTY]` bundle plus four repo-specific lines.

- `gather_exclude_match = ^assets/` — the README and POD images stay out of the CPAN tarball.
- `docker_image = raudssus/langertha` with `docker_tags = latest %V %v` — the release builds and pushes the image. It talks to the container engine at `DOCKER_HOST` over the Engine HTTP API (no docker binary; rootless Podman works) and builds in *every* build — `dzil build`, `dzil test` and `dzil release` alike. `DZIL_DOCKER_API_SKIP=1 dzil build` skips the engine contact; `dzil release` refuses to run with that variable set.
- `GitHub::CreateRelease` publishes the GitHub release once the tag is pushed: the Changes section as notes, the CPAN tarball attached, the token from `~/.github-identity`. **Never create the release from `run_after_release`** — that hook runs before the tag exists, so `gh` puts the tag on the old remote head and `Git::Push` then fails on it.
- `Test::Perl::Critic` runs over the dist with `.perlcriticrc`, embedded in the tarball.

The bundle bumps `$VERSION` and tags on release. Versions are never written by hand into
plans, cards or code — the release run owns them. The general flow lives in
`getty-perl-release-author-getty` and `perl-release-dist-ini`; the release lock itself is in
`.claude/rules/langertha-rules.md`.

## The board and the public tracker

Langertha is a single distribution: **one board**, state in `refs/karr/*`, no cross-repo
handoff inside the repo. The public tracker (`github.com/Getty/langertha`) is a different
universe — real humans' bug reports and feature requests, written under the maintainer's
account. Never read, comment on or close an issue there on your own initiative; only on an
explicit instruction naming the item. Guardrails: skill `langertha-github-issues`.

## Repo mechanics

- **`.claude/` is git-ignored except for a whitelist.** The root `.gitignore` ignores
  `.claude/*` and re-admits `settings.json`, `agents/`, `skills/`, `rules/` — a *new*
  directory under `.claude/` stays invisible to git until it is whitelisted there. Verify
  with `git status --short` after creating one; `.claude/worktrees/` is ignored explicitly.
- **Two kinds of skill live under `.claude/skills/`.** The ones `skilletor` installs carry a
  `.gitignore` holding `*` in their own directory — build artifacts, overwritten by the next
  `skilletor sync`; change them in their source, never here. The repo-owned ones
  (`langertha-adr`, `langertha-core`, `langertha-github-issues`, `langertha-internals`,
  `langertha-testing`, `perl-ai-langertha`) are tracked by git and belong to this repository.
- **An untracked file does not exist as far as dzil is concerned.** `Git::GatherDir`
  collects only what git knows: a file that was never `git add`-ed is skipped while
  gathering, so `prove` runs it and passes while the release tarball silently omits it.
  `git add` new files as soon as they exist.
- **Work in a worktree inside the repo, never in `/tmp`** — `/tmp` does not survive a
  reboot. `git worktree add .claude/worktrees/<name> -b feature/<name>`; `/.claude/worktrees/`
  is git-ignored.
