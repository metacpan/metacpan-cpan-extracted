---
name: raider-core
description: "Use when working inside the Langertha-Raider distribution — the one kernel with the assistant and project profiles, the three sources of truth (CONTEXT.md, docs/adr/, the karr board), the one-way dependency to langertha core, the public/internal API rule, the reserved App::Raider stubs, the test layout and the release wiring. Raiders own context, tools, permissions, hooks, subagents, worktrees, Hall and ACP."
---

# Raider core — the map and the invariants

Raider is the Perl-native agent runtime: one kernel, two profiles (ADR 0002) — the
**assistant** (lives in the home, reachable everywhere, remembers the user) and the
**project agent** (works inside a project, respects that project's context). It ships as
`Langertha-Raider`: the `Langertha::Raider` engine plus the former `App::Raider` CLI/Hall/ACP app.

## Three sources of truth, in this order

1. **`CONTEXT.md`** — vision and vocabulary. Read before any non-trivial change.
2. **`docs/adr/`** — every decision, 0001 to 0032. **Anything not recorded there is not
   decided.** Don't invent architecture beyond it; flag gaps as karr tickets or questions.
3. **The karr board** — the work itself. Work in the small vertical slices the tickets
   describe; no big-bang rewrite.

`docs/RAIDER-REDESIGN-HANDOFF.md` is frozen research input the ADRs cite — a proposal, not a spec.

## The repo map

| Area | Modules |
|---|---|
| The engine | `Langertha::Raider` (`main_module`), `::Result`, `Langertha::Raid*`, `::EngineResolver`, `::Provider::*` |
| The kernel | `::Application` — context, permissions, tools, hooks, subagents |
| Context | `::Context`, `::Context::{Layout,Memory,Settings,Plugins,Skills,Agents,Frontmatter}` |
| Surfaces | `::CLI` + `::CLI::*`, `::Hall` + `::Hall::*`, `::ACP::Client`, `::ACP::CLI` |
| Tools | `::FileTools`, `::WebTools`, `::PerlTools`, `::BashTools`, `::SearchTools`, `::TodoTools`, `::AskTools`, `::PlanTools`, `::SkillTools`, `::AgentTools`, `::CronTools`, `::HallTools`, `::WorktreeTools` |
| MCP | `::MCP`, `::MCP::{Config,HTTP,Server,Stdio,Resources,View}` |
| Permissions | `::Permissions`, `::Permissions::{Rule,ReadOnlyBash}`, `::PermissionChannel`, `::Approval`, `::Loadguard`, `::PathConfine` |
| Sessions | `::Session`, `::Session::Journal`, `::SessionStore`, `::Tasks`, `::Subagent`, `::Briefing` |
| Config & home | `::Config`, `::Config::Migrate`, `::Home`, `::Instructions`, `::Detect`, `::Packs*`, `::Skill`, `::SkillResolver*` |
| Plugins | `::Plugin::{Situation,Trace,Events,ClaudeHooks,NestedMemory}` |

`bin/raider` and `bin/raider-hall` are the executables; `share/packs` carries the shipped
packs.

## The dependency direction is one-way

Raider → Langertha core, never back. Core keeps exactly two soft references to Raider,
both documented exceptions: a lazy `use_module` sugar path in `Langertha.pm` and a runtime
`->isa()` string check in `Plugin.pm`. Do not turn them into a hard dependency.

From core this dist uses the public hooks only: `Langertha::RunContext`, `Langertha::Usage`,
`Langertha::Plugin` and the roles `PluginHost` / `Runnable`; the engine hooks
`async_request_f`, `async_loop`, `langfuse_timestamp`, `Usage->from_raw`; the plugin hooks
`plugin_instances`, `plugin_args`, `plugin_pipeline_tool_call_f`. No core privates are left.

**Do not move the generic tool-calling foundation into this repo.** `Role::Tools`,
`Role::PluginHost`, `Role::SystemPrompt`, `Role::Runnable`, `Plugin.pm`, `Plugin::Langfuse`,
`Role::Langfuse`, `Chat.pm` and `Result.pm` stay in core — shared, not Raider-specific.

## Naming is settled (ADR 0001)

- `Langertha::Raider` is the engine **and** the `main_module`. `Langertha::Raider::CLI`
  is the CLI; the executables keep the names `raider` and `raider-hall`.
- The six old `App::Raider*` names (`App::Raider`, `::FileTools`, `::WebTools`, `::Skill`,
  `::Plugin::Situation`, `::Plugin::Trace`) ship as **reserved CPAN stubs**. They have no
  API, and **no code goes back under these names** — an indexed package that is renamed
  leaves a stub behind. Renaming a public package again starts another round of stubs.
- `Langertha::Raider::ACP` is reserved for the stdio ACP server (ADR 0010).
- `Langertha::Raid*` sits in `Langertha::` but ships here and was indexed from core —
  renaming it now would mean stubs, so it stays.

## Public vs. internal — the marker rule (ADR 0017)

1. A package is **public** when it is on ADR 0017's public list. A package whose
   `# ABSTRACT` starts with `Internal` and whose DESCRIPTION opens with
   `B<Internal module.>` is **internal**. A reserved stub is neither — it has no API.
2. Inside a public package a name is public when it is not `_`-prefixed **and** the
   package's POD documents it; Moose predicates, clearers and writers count only where the POD names them.
3. Inherited contracts stay with their owner (core's `Role::PluginHost`, `Role::Runnable`).
4. Everything else is internal and may change in any slice without deprecation.
5. Changing a public name is deliberate: `Changes` says so.
6. **New packages start internal** — they carry the marker until an ADR adds them.
7. **Wire and file formats are public no matter where they live**: the `raider` command
   line and exit status, the machine output (ADR 0013), the session journal (ADR 0015), the
   config files (`.raider.yml` / `.raider.md` legacy, `.raider/`, `.raider-hall.yml`, `pack.yml`),
   the tool names the model sees, and the environment variables raider reads.

The public list itself lives in ADR 0017 — read it before renaming anything.

## Moose only — with two hand-blessed exceptions

Unlike `langertha-knarr` (Moose/Moo split), everything here is Moose; the former
`App::Raider::*` code has no Moo. ADR 0017 blesses two exceptions: `ACP::Client` has its
own `new` and `DESTROY`, and `ACP::CLI` / `Hall::CLI` are plain function modules that `die`.

## The vocabulary has traps (CONTEXT.md)

Use these words in code, tests, tickets and ADRs:

| Word | Means |
|---|---|
| **Profile** | `assistant` or `project` — defaults (scope, memory, tools, policies), **not** a security boundary |
| **Principal** | the locally authenticated person raider acts for; a surface maps a Telegram sender to one, a prompt never sets it |
| **Workspace** | a registered working directory with a stable id and a trust decision — _not_ the project root as an identity |
| **Working root** | the directory a run's file, search and shell tools and its permission policy work in — the root, or a git worktree of it after `enter_worktree` (ADR 0032) |
| **Session** | a persistent conversation bound to one principal and one workspace, JSONL next to its scope (ADR 0003) — _not_ a process or a PID |
| **Run** | the processing of one accepted input inside a session: state, budgets, config/policy snapshot |
| **ContextPlan** | the itemised, explainable context of one model call (ADR 0004) — _not_ a mission |
| **Delegate** | an external agent with its own loop (Codex, Claude Code, a remote raider) — _not_ an engine |
| **Engine** | a Langertha model backend; answers requests, owns no loop |
| **Pack** | a named bundle of skills, persona defaults and *requested* capabilities ("persona" in Hall/README today) |
| **Permission mode** | how a session treats tool calls no rule decides; set locally, never by a prompt |
| **Permission rule** | an allow/ask/deny entry in Claude Code syntax; deny before ask before allow |
| **Layout mode** | which project files raider reads: `raider`, `claude`, `native`, `bare` (ADR 0019) — _not_ a profile |

**ACP** here is always the *Agent Client Protocol* (Zed, editors); Knarr's ACP is BeeAI's
*Agent Communication Protocol* — say **ACP-BeeAI** for that one.

## The test layout

`t/` is numbered by area, and the numbering is the map: `00`–`01` load and reserved
namespaces · `10`–`29` file/web/perl tools, packs, detection, config, profiles, home ·
`30`–`59` the CLI and its output, ACP, Hall tools, interrupts, sessions, the engine
resolver · `60`–`99` the application, the provider catalog, the agent loop, results,
plugins, compaction · `100`–`199` the Claude Code flow (tool gate, permissions, context,
hooks, agents, skills, bash, worktrees) · `200`–`299` scenarios, MCP, slash commands,
usage, packs, tasks · `300`–`399` cron, monitor, worktrees.

`t/lib/Test/Raider/` holds the helpers — `StubEngine`, `SeqEngine`, `MockAI`, `SlowAI`,
`FakeHTTPS`, `LocalHTTP`, `MCPHTTP`, `FakeProc`, `Git`, `Hall`, `HallScenario`, `Scenario`,
`Env`, `Live`. **Fake the engine and the transports with these** before inventing a new one.

**No test may require a live API key or a live MCP server.** `t/live/` and
`Test::Raider::Live` are the opt-in layer: `live_opt_in()` skips everything unless
`RAIDER_LIVE_TASKS=1` — merely having a key set is never enough, these tasks cost real
money. Once opted in, nothing skips any more: a missing key, an unusable provider or a
failed run is a **failure**, not a skip.

Verify against the dev Langertha (the installed one is usually stale):
`prove -I../langertha/lib -Ilib -It/lib -r t` — recursive, `t/` has subdirectories.

## Release wiring

`dist.ini` is `[@Author::GETTY]` plus what this repo adds:

- `gather_exclude_match` for `^\.claude/`, `^CLAUDE\.md$`, `^CONTEXT\.md$`, `^docs/`,
  `^\.github/`, `^scripts/`, `^maint/`, `^assets/` — development infrastructure has to be
  excluded explicitly, or `Git::GatherDir` silently ships it in the CPAN tarball.
- `docker_image = raudssus/raider` with `docker_tags = latest %V %v` — the bundle's
  Docker::API talks to the container engine at `DOCKER_HOST` over the Engine HTTP API (no
  docker binary; rootless Podman works) and builds the image from the built dist in
  **every** build — `dzil build`, `dzil test` and `dzil release` alike.
  `DZIL_DOCKER_API_SKIP=1 dzil build` skips the engine contact; `dzil release` refuses to run with it.
- `GitHub::CreateRelease` publishes the GitHub release once the tag is pushed: the Changes
  section as notes, the CPAN tarball attached, the token from `~/.github-identity`. **Never
  create the release from `run_after_release`** — that hook runs before the tag exists, so
  `gh` puts the tag on the old remote head and `Git::Push` then fails on it.
- No build arguments are passed: `RAIDER_DOCKER_BUILD_ARGS` is gone. The published image is
  the Dockerfile's **last** stage (`runtime-root`) — keep it last, the bundle builds no
  other. The GitHub release is what fires `.github/workflows/release-binaries.yml`.
- The standalone binary is a separate lane: `scripts/build-binary.sh` (PAR::Packer) plus
  `verify-binary.sh` and `check-binary-libs.sh`. That is skill `raider-single-binary` and
  `raider-binary-worker`'s lane — not this one's.

## Repo mechanics

- **`.claude/` is git-ignored except for a whitelist.** The root `.gitignore` ignores
  `.claude/*` and re-admits `settings.json`, `agents/`, `skills/`, `rules/` — a *new*
  directory under `.claude/` stays invisible to git until it is whitelisted there; check
  with `git status --short`. `/.claude/worktrees/` is ignored explicitly.
- **Two kinds of skill live under `.claude/skills/`.** The ones `skilletor` installs carry
  a `.gitignore` holding `*` in their own directory — build artifacts, overwritten by the
  next `skilletor sync`; change them in their source, never here. The repo-owned ones are
  tracked by git: `raider-core` and `raider-single-binary`.
- **An untracked file does not exist as far as dzil is concerned.** `Git::GatherDir`
  collects only what git knows: a file that was never `git add`-ed is skipped while
  gathering, so `prove` runs it and passes while the release tarball silently omits it.
- **Work in a worktree inside the repo, never in `/tmp`** — `/tmp` does not survive a
  reboot. `git worktree add .claude/worktrees/<name> -b feature/<name>`;
  `/.claude/worktrees/` is git-ignored.
- **Don't create new planning or status files in the repo root** — decisions become ADRs,
  open work becomes tickets.
