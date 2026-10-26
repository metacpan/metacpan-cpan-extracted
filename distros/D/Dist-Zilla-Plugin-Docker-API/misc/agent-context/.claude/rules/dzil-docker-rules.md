# Dist-Zilla-Plugin-Docker-API House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Build and publish Docker images as Dist::Zilla release artifacts. Read first: `Client.pm` — the
single seam between the plugin and `API::Docker`. A change to what
`build_image`/`tag_image`/`push_image` accept or return reaches the plugin, the Recorder fake
and every phase test at once.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug the plugin, the client adapter, cpanfile | `dzil-docker-worker` (default) |
| Write/extend tests | `dzil-docker-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `dzil-docker-release-manager` |
| POD and README | `dzil-docker-doc-writer` |
| Read-only research, audit, gap analysis | `dzil-docker-worker` ("read-only, change nothing") |

A question about what the Docker daemon itself accepts or answers is not this repo's — it
belongs to `../p5-api-docker` and its `api-docker-engine-worker`, as a ticket on that repo's
board (`cd ../p5-api-docker && karr create …`).

Behavior-relevant = the phase hooks, the dist.ini attribute surface and its `init_arg`s, tag
template expansion, `Client.pm` and everything it returns, `cpanfile`, and tests. Pure prose
docs and `Changes` notes are not.

## Release

**This dist depends on `API::Docker`, which is Getty's own and may be pinned to a version CPAN
does not have yet — it cannot ship before that one does.**

## Deviations from the house rules

- **CPAN RT counts as a public tracker** alongside GitHub issues on
  `Getty/p5-dist-zilla-plugin-docker-api`.

## Hazards — one prohibition each, the background is in skill `dzil-docker-hazards`

- **This plugin is not applied to its own distribution.** `dist.ini` here contains only
  `[@Author::GETTY]` — a green `dzil build` here builds no image and exercises no phase hook.
  Never take it as proof of anything about Docker.
- **There is no Docker on this machine — only rootless Podman** at
  `unix:///run/user/1000/podman/podman.sock`; `/var/run/docker.sock` does not exist and is the
  plugin's only fallback. Anything live needs `DOCKER_HOST` set explicitly.
- **`fail_if_tag_exists` asks the registry, not the local daemon.** The lookup goes through
  `API::Docker`'s `distribution->exists` — never answer the question from the local daemon.
- **An unknown dist.ini key is silently discarded, not rejected.** Read an attribute's
  `init_arg` before documenting or changing it — that is the key users write, and this
  distribution's whole user surface is dist.ini keys.
- **Deprecated spellings live in `BUILDARGS` only.** The `%DEPRECATED_KEY` table plus
  `init_arg => undef` on the deprecated readers is what makes them work at all; an alias
  declared as a lazy attribute reading *from* the canonical one silently does nothing.
- **`release` re-tags from `tag->[0]`, it does not rebuild.** Reordering the `tag` list
  silently changes which image a release ships — anything touching the tag list is a
  release-behavior change.
- **An unknown `%` variable in a tag template expands to the empty string, not an error.** A
  typo yields a truncated tag and a successful build; verify template changes against
  `t/10-tag-template.t`, not by eye.
- **`../p5-dist-zilla-pluginbundle-author-getty` constructs this plugin programmatically.** An
  attribute or `init_arg` rename is a coordinated change: verify that bundle, or file a ticket
  on its board before landing.

## Perl specifics — reference, don't restate

Module loading, `$VERSION`, cpanfile pinning and house style: skills `getty-perl-core`,
`getty-perl-moose`, `getty-perl-moo`. `[@Author::GETTY]`, POD weaving, `{{$NEXT}}`: skill
`getty-perl-release-author-getty`. dist.ini mechanics: `perl-release-dist-ini`. Commit style:
`getty-git-commit-style`. Architecture and the client seam: `dzil-docker-core`.
