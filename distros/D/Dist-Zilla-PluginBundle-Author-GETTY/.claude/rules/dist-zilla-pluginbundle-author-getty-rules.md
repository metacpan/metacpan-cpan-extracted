# Dist-Zilla-PluginBundle-Author-GETTY House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — state assumptions; when uncertain, ask rather than guess.
   Push back when a simpler approach exists.
2. **Simplicity first** — minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — touch only what you must. Match existing style.
4. **Goal-driven execution** — define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — pick one (more recent / more tested), flag
   the other for cleanup. Don't blend.
6. **Read before you write** — `configure()` in the bundle class is the single seam every
   option flows through; a change to plugin order or a default reaches every consuming
   dist at once. Read the whole method before adding a branch.
7. **Tests verify intent, not just behavior** — a test that can't fail when the logic
   changes is wrong. Reproduce a bug before fixing it; leave the regression behind.
8. **Checkpoint after every significant step** — summarize: done / verified / left.
9. **Match conventions** — conformance > taste. Surface a harmful convention; don't fork
   silently.
10. **Fail loud** — "Done" is wrong if anything was skipped. "Tests pass" is wrong if any
    were skipped.
11. **A red test is a claim before it is a failure** — before changing code to turn a
    test green, say what the test asserts and whether your fix keeps that claim or
    replaces it. If the claim is wrong, fix the claim and say so.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run
  tests, manage git, edit non-behavioral docs. When in doubt, delegate. Why: only the
  `dist-zilla-pluginbundle-author-getty-*` agents get their skills force-loaded via
  `briefing.skills`; you get no briefing and would touch internals with too little
  context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug the bundle, subsection, GiteaMeta, the CI action | `dist-zilla-pluginbundle-author-getty-worker` (default) |
  | Write/extend tests | `dist-zilla-pluginbundle-author-getty-test-writer` |
  | Pre-release audit | `dist-zilla-pluginbundle-author-getty-release-checker` |

- **You cannot spawn subagents** (you ARE a `dist-zilla-pluginbundle-author-getty-*`
  agent): the delegation lock does not apply to you — implement, refactor, debug and test
  per these rules.

Behavior-relevant = `configure()` and the bundle's attribute surface, the
`@Author::GETTY::Docker` subsection, the `GiteaMeta` plugin, the POD transformer/weaver,
`.github/actions/dzil-test/action.yml`, `cpanfile`, and tests. Pure prose docs and
`Changes` notes are not.

## Commit messages — no bundle/plugin namespace prefix

**Never prefix a commit subject with `[@Author::*]` or a similar bundle/plugin tag.**
Describe the change directly: `add [GitHub::CreateRelease] when GitHub integration is
active`, NOT `[@Author::GETTY] add ...`. A plugin/module name *inside* the message body
(e.g. `[GitHub::CreateRelease]`) is fine — only the leading `[@Author::*]` namespace
prefix is forbidden. This repo has ~117 commits and exactly one carried such a prefix (a
mistake); keep it at one.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the `kanban-issues-karr-cli` skill first, just use it. Git-native kanban;
state lives in `refs/karr/*`; one board, this repo. Day-to-day: `karr list --compact` /
`karr board` for open work; `karr show ID` for detail; `karr create/edit/move/handoff`
for the usual flow; mutating commands auto-sync. Full surface: skill
`kanban-issues-karr-cli`.

Cross-repo work is a ticket on the *other* repo's board (`cd ../p5-dist-zilla-plugin-docker-api
&& karr create …`), never a direct edit there.

**Serialize board mutations when fanning out.** Keep implementation parallel if you like,
but collect results and loop `karr move`/`handoff`/`sync` sequentially — N landing at
once is a resource event, not a cheap command.

## Release — never without permission

`dzil build`, `dzil test` and `prove -lr t/` are fine anytime. `dzil release` and any
CPAN upload are STRICTLY forbidden without the maintainer's explicit go-ahead — even if
`Changes` or a plan names "release" as the next step. Because this bundle is inherited
estate-wide, a release here reaches every consuming dist's next build — treat it as a
coordinated event, and stop and ask.

## Public issues — never act without instruction

Two trackers, two universes. **karr** is the internal agent work board, churned freely.
**GitHub issues on `Getty/p5-dist-zilla-pluginbundle-author-getty`** carry real humans'
reports under the maintainer's name. **Never act on a public issue on your own initiative
— not even to read it.** No listing, viewing, commenting, editing, closing or creating
unless the user names a specific item to handle.

## Repo-specific hazards

- **This bundle dogfoods itself.** `dist.ini` is `[Bootstrap::lib]` + `[@Author::GETTY]`,
  so `dzil` here runs this repo's *in-development* bundle code on the bundle's own
  distribution. A broken `configure()` breaks this repo's own `dzil build` immediately —
  that is a feature, but it means a green build here is also a smoke test of your change.
- **`.github/actions/dzil-test` is the estate's shared CI.** Consumers pin `@main`, so
  every change lands in their CI on the next run. `dzil listdeps --author` (not plain
  `listdeps`) is load-bearing: it pulls develop-phase author-test deps like `Test::Pod`
  that `[PodSyntaxTests]` registers. Never paper over a missing author-test dep by faking
  it into a dist's `cpanfile` `on test` block — that hack is what this action removes.
- **A cwd-dependent lazy attribute read after `chdir` measures the wrong directory.**
  `_has_github_remote`/`_remote_host` read `.git/config` relative to cwd; tests must
  force them while still inside the fabricated tempdir.

## Perl specifics — reference, don't restate

The bundle class is Moose (`Dist::Zilla::Role::PluginBundle::Easy`): module loading,
`$VERSION`, house style live in skill `getty-perl-moose`. `[@Author::GETTY]` conventions,
POD weaving, `{{$NEXT}}`: skill `getty-perl-release-author-getty`. dist.ini mechanics:
`perl-release-dist-ini`. Architecture, `configure()` assembly, remote detection, the
shared CI action: skill `dist-zilla-pluginbundle-author-getty-core`. Don't duplicate any
of it here.
