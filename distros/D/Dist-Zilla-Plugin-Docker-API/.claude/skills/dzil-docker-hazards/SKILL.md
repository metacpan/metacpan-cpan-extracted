---
name: dzil-docker-hazards
description: Load before editing p5-dist-zilla-plugin-docker-api behavior-relevant code — why each hazard exists: the plugin never runs on itself, Podman-only on this machine, the registry lookup behind fail_if_tag_exists, silently discarded dist.ini keys, BUILDARGS-only deprecated spellings, re-tagging from tag->[0], and empty-string template variables.
user-invocable: false
model: inherit
---

# dzil-docker-hazards

The prohibitions live in `.claude/rules/dzil-docker-rules.md`; here is the reason
behind each one. Read both: a prohibition without its reason gets optimized away,
a reason without its prohibition does not bind.

The architecture itself is in `dzil-docker-core` — this skill does not replace it.

## 1. The plugin is not applied to its own distribution

`dist.ini` in this repo contains only `[@Author::GETTY]`. The Docker plugin is not
listed, so `dzil build` here gathers, munges and writes a distribution and stops:
no image is built, no phase hook runs, no tag is expanded.

A green `dzil build` in this repo therefore proves nothing about the plugin. Every
check of real plugin behaviour goes through the test suite (`t/`, with the Recorder
fake) or a throwaway dist that actually lists the plugin.

## 2. No Docker on this machine — only rootless Podman

The engine socket is `unix:///run/user/1000/podman/podman.sock`. There is no
`/var/run/docker.sock` on this host, and that is the only fallback the plugin has
when `DOCKER_HOST` is unset. Anything live — a manual build, an image push, a
release rehearsal — needs `DOCKER_HOST` set explicitly.

The plugin never shells out to a `docker` binary, so Podman's rootless socket is a
supported target, not a workaround.

## 3. `fail_if_tag_exists` asks the registry

The check runs through `API::Docker`'s `distribution->exists`
(`GET /distribution/{name}/json`) — against the registry, not against the local
daemon's tag list. It is real since `API::Docker` 0.004; before that it was a stub
that always answered "no".

Rootless Podman has no `/distribution` route, so the lookup croaks there and the
release aborts with the engine's own error. That is deliberate: "this engine cannot
answer" is not the same as "the tag is free", and only the caller may decide what
to do about the difference. `fail_if_tag_exists = 0` releases without the check.
The POD and `README.md` describe this.

Answering the question from the local daemon is the wrong answer — the local
daemon knows nothing about what is already published.

## 4. An unknown dist.ini key is silently discarded

Dist::Zilla hands the plugin only the keys it declared. A key the plugin does not
know is dropped without an error, and the default of the attribute behind it wins.

That is how `dockerfile = ...` went unnoticed for so long: the attribute carried
`init_arg => 'file'`, so the documented key fell through to the default and no
build ever complained. The whole user surface of this distribution is dist.ini
keys — read an attribute's `init_arg` before documenting it or changing it, and
put the key a user writes into the `init_arg`, not only into the attribute name.

## 5. Deprecated spellings live in `BUILDARGS` only

`%DEPRECATED_KEY` plus `init_arg => undef` on the deprecated readers is the whole
mechanism. The canonical key wins on collision and the collision is reported.

An alias declared as a lazy attribute that reads *from* the canonical attribute does
not work: the alias resolves before the canonical value exists, so it silently does
nothing — that is exactly what `repository`, `push` and `load` used to do.
`mvp_multivalue_args` carries the same trap for repeatable keys: a repeatable
attribute missing from that list keeps only its last value.

## 6. `release` re-tags from `tag->[0]`

The release phase does not rebuild. It takes the image named by the first entry of
the tag list as the source and re-tags every entry of the list onto it. Reordering
the `tag` list therefore changes which image a release ships — silently, because
nothing errors.

With `skip_latest_on_trial` the source still comes from the unfiltered list, so a
trial release re-tags from `image:latest`; that image exists because `after_build`
does not filter. Correct, but not obvious.

## 7. An unknown `%` variable expands to the empty string

`TagTemplate::expand` maps a fixed set of variables. Anything else becomes `""` —
no error, no warning. A typo in a tag yields a truncated tag and a successful
build.

`_extract_vars` knows the valid set but is called from nowhere: dead code, not a
safety net. Verify template changes against `t/10-tag-template.t`, not by eye.

## 8. The bundle constructs this plugin programmatically

`@Author::GETTY::Docker` in `../p5-dist-zilla-pluginbundle-author-getty` builds
`Dist::Zilla::Plugin::Docker::API` itself and injects the underscore-prefixed
`_target` and `_network_mode` keys. An attribute rename or an `init_arg` change is
a coordinated change across the two repos: verify that bundle still builds, or
file a ticket on its board before landing.
