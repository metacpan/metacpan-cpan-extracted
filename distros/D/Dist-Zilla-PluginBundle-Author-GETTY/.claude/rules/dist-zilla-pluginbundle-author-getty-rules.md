# Dist-Zilla-PluginBundle-Author-GETTY House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

BeLike::GETTY when you build your dists — the `[@Author::GETTY]` Dist::Zilla bundle, inherited
estate-wide. Read first: `configure()` in the bundle class is the single seam every option flows
through; a change to plugin order or a default reaches every consuming dist at once. Read the
whole method before adding a branch.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug the bundle, subsection, GiteaMeta, the CI action | `dist-zilla-pluginbundle-author-getty-worker` (default) |
| Write/extend tests | `dist-zilla-pluginbundle-author-getty-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `dist-zilla-pluginbundle-author-getty-release-manager` |
| Read-only research, audit, gap analysis | `dist-zilla-pluginbundle-author-getty-worker` ("read-only, change nothing") |

Behavior-relevant = `configure()` and the bundle's attribute surface, the
`@Author::GETTY::Docker` subsection, the `GiteaMeta` plugin, the POD transformer/weaver,
`.github/actions/dzil-test/action.yml`, `cpanfile`, and tests. Pure prose docs and `Changes`
notes are not.

Cross-repo work is a ticket on the other repo's board
(`cd ../p5-dist-zilla-plugin-docker-api && karr create …`).

## Release

Because this bundle is inherited estate-wide, a release here reaches every consuming dist's
next build — treat it as a coordinated event.

## Commit messages — no bundle/plugin namespace prefix

**Never prefix a commit subject with `[@Author::*]` or a similar bundle/plugin tag.** Describe
the change directly: `add [GitHub::CreateRelease] when GitHub integration is active`, NOT
`[@Author::GETTY] add ...`. A plugin/module name *inside* the message body is fine — only the
leading `[@Author::*]` namespace prefix is forbidden. This repo has ~117 commits and exactly one
carried such a prefix (a mistake); keep it at one.

## Hazards — the background is in skill `dist-zilla-pluginbundle-author-getty-core`

- **This bundle dogfoods itself.** `dist.ini` is `[Bootstrap::lib]` + `[@Author::GETTY]`, so
  `dzil` here runs this repo's *in-development* bundle code on the bundle's own distribution. A
  broken `configure()` breaks this repo's own `dzil build` immediately — a green build here is
  also a smoke test of your change.
- **`.github/actions/dzil-test` is the estate's shared CI.** Consumers pin `@main`, so every
  change lands in their CI on the next run. `dzil listdeps --author` (not plain `listdeps`) is
  load-bearing: it pulls develop-phase author-test deps like `Test::Pod` that
  `[PodSyntaxTests]` registers. Never paper over a missing author-test dep by faking it into a
  dist's `cpanfile` `on test` block — that hack is what this action removes.
- **A cwd-dependent lazy attribute read after `chdir` measures the wrong directory.**
  `_has_github_remote`/`_remote_host` read `.git/config` relative to cwd; tests must force them
  while still inside the fabricated tempdir.

## Perl specifics — reference, don't restate

The bundle class is Moose (`Dist::Zilla::Role::PluginBundle::Easy`): module loading, `$VERSION`,
house style live in skill `getty-perl-moose`. `[@Author::GETTY]` conventions, POD weaving,
`{{$NEXT}}`: skill `getty-perl-release-author-getty`. dist.ini mechanics:
`perl-release-dist-ini`. Architecture, `configure()` assembly, remote detection, the shared CI
action: skill `dist-zilla-pluginbundle-author-getty-core`.
