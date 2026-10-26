---
name: dzil-docker-core
description: "Use when working on the Dist-Zilla-Plugin-Docker-API distribution — the plugin's dist.ini attribute surface, the before_build/after_build/release phase hooks, tag template expansion, the API::Docker client adapter, or the Recorder-fake harness under t/lib."
---

# Dist::Zilla::Plugin::Docker::API — architecture and invariants

A Dist::Zilla plugin that builds a Docker image from the built distribution and
pushes it on release. Everything goes through `API::Docker`, which speaks the
Engine HTTP API over a socket — **no `docker` binary is involved anywhere**, so
Podman's rootless socket is a first-class target.

## The four files

```
API.pm          the plugin: Moose, the dist.ini attribute surface, the three
                phase hooks, template variables, git info
  API/Client.pm     the only thing that touches API::Docker (Moo)
  API/TagTemplate.pm  %-expansion (Moo)
  API/Result.pm       value object: image_id, tags, pushed, digest, warnings (Moo)
```

**`API.pm` is Moose, the other three are Moo.** That is forced, not a slip:
`Dist::Zilla::Role::Plugin` is Moose, and the helper classes carry no
Dist::Zilla dependency. `getty-perl-core`'s "one object system per
distribution" yields to the framework here — keep the split on that line and
do not migrate a class across it without a reason.

## The three phases

| Hook | Role | What it does |
|---|---|---|
| `before_build` | `BeforeBuild` | asks the engine for its version and dies there if nothing answers |
| `after_build`  | `AfterBuild`  | builds the image, applies every `tag` locally |
| `release`      | `Releaser`    | re-tags the **already built** image, pushes |

The precheck exists because `after_build` builds unconditionally: without it,
Dist::Zilla gathers, munges and writes a whole distribution and only then dies
on a socket that was never there.

Two environment escapes, and they are not the same:

- `DZIL_DOCKER_API_SKIP_PRECHECK=1` — skip only the version probe. The build
  still runs and still needs an engine.
- `DZIL_DOCKER_API_SKIP=1` — skip the image build entirely for one run.
  `release` **refuses to run** with it set: no build means nothing to push.

## The attribute surface

`tag` is the one canonical tag list, defaults to `['latest', '%V', '%v']`, and
is applied identically in both phases. Setting it in dist.ini **replaces** the
default list, never appends.

Two traps live in the `init_arg`s:

- **`_target` and `_network_mode`** are underscore-prefixed so the
  `@Author::GETTY::Docker` bundle can inject them without exposing them in
  user-facing dist.ini. `fail_if_tag_exists` and `skip_latest_on_trial`
  deliberately are **not** hidden. Do not add an underscore prefix unless the
  bundle is the sole writer.
- **`mvp_multivalue_args`** lists every repeatable key
  (`tag build_tag release_tag build_arg label platform`). A new repeatable
  attribute that is not in that list silently keeps only its last value.

**Every deprecated spelling is resolved in `BUILDARGS`, nowhere else.**
`build_tag`/`release_tag` merge into `tag`; the `%DEPRECATED_KEY` table maps
`file → dockerfile`, `load → build_load`, `push → release_push`,
`repository → image`; `phase` is warned about and discarded. The canonical key
wins on collision and the collision is reported. The deprecated readers
(`->repository`, `->load`, `->push`, `->file`) carry `init_arg => undef` so the
old keys cannot reach an attribute directly and bypass the table — keep it that
way when adding one. `t/35-deprecated-aliases.t` pins all of it down.

## Release re-tags from `tag->[0]`

`release` does not rebuild. It takes `image . ':' . expand($self->tag->[0])` as
the **source** and re-tags every entry of the list onto it. Consequences:

- Reordering the `tag` list changes which image the release re-tags from.
- The source is computed from the *unfiltered* list, so with
  `skip_latest_on_trial` a trial release still re-tags from `image:latest` —
  which exists, because `after_build` does not filter. Correct, but not
  obvious.
- A missing source image surfaces as the engine's own 404 through
  `tag_image`. That is deliberate: no home-grown pre-check was added.

Push failures are collected per tag and reported together in one `log_fatal`;
a tag failure during build only warns and drops that tag.

## Template expansion

`TagTemplate::expand` maps `%n %v %V %t %g %G %b %d %o %a %p` (plus `%vmaj`,
`%vmin`) onto the variables `_template_vars` assembles. Two things to know:

- **An unknown variable expands to the empty string, not an error.** `%q` in a
  tag yields a silently truncated tag. (`_extract_vars` knows the valid set but
  is called from nowhere — dead code, not a safety net.)
- **`%d` (build_root) differs between the phases**: the temporary build
  directory during `after_build`, `$zilla->root` during `release`. Anything
  templated from it will not match across the two.

`%V`/`%vmaj`/`%vmin` are not read from the variable hash at all; they are
derived from `version` inside `_expand_var`.

## The client seam

`client_class` (default `…::API::Client`) is loaded with a runtime
`eval "require"` and constructed with two coderefs, `logger` and
`logger_fatal`, that funnel into the plugin's `log`/`log_fatal`. **This seam is
the entire test strategy** — everything below it is fake-able and nothing in
`API.pm` may reach `API::Docker` directly.

Inside `Client.pm`:

- **`_split_image_ref` exists because the engine's tag endpoint takes repo and
  tag separately** (`POST /images/{name}/tag?repo=&tag=`). Passing a full
  reference as `repo` leaves `tag` empty, the engine appends its own default,
  and podman rejects `example/app:1.0:latest` with a 500 — every version tag
  quietly lost. A colon before the last slash is a registry port, not a tag.
- **A failed build's output rides on the exception, not the event loop.**
  API::Docker croaks on the `errorDetail` event before the caller iterates, so
  the preceding stream is drained from `$err->events` — otherwise a failed
  build logs only its last line.
- **Concise mode is the default.** `_is_build_step_header` recognises the
  legacy builder (`Step N/M :`), Podman's classic builder (`STEP N/M:`) and
  BuildKit (`#N [N/M]`, `#N [name N/M]`). A fourth builder format needs a
  fourth pattern here, plus a case in `t/60-build-progress.t`.
- Registry auth is read from `~/.docker/config.json` (or `$DOCKER_CONFIG`),
  handling `identitytoken`, base64 `auth` and plain user/password, with the
  Docker Hub key aliases spelled out.

## Cross-repo: `../p5-api-docker` owns the wire

`API::Docker` is a Getty distribution in the same workspace and `cpanfile` pins
it (`0.003`). A question about what the daemon accepts or answers — endpoint
shape, event stream, auth header, version gating — is **that** repo's, and gets
a ticket on its board rather than a workaround here. `_split_image_ref` living
here rather than there is a deliberate choice: `API::Docker` mirrors the
endpoint and should keep doing so.

The consumer in the other direction is `@Author::GETTY::Docker` in
`../p5-dist-zilla-pluginbundle-author-getty`, which constructs this plugin
programmatically. Any attribute rename or `init_arg` change is a cross-repo
change — check that bundle still builds.

## Tests — the Recorder fake, never a daemon

`prove -lr t/` must pass on a machine with no engine at all, and does.

Tests drive the real plugin through `Dist::Zilla::Tester->from_config` with an
inline `dist.ini`, and swap the client via `client_class = …::Client::Recorder`
(`t/lib`, reached with `use lib "$Bin/lib"`). The Recorder records every call
into `->calls` and hands back canned results; `…::Client::Unreachable` extends
it and croaks from `engine_info` for the precheck tests.

Consequences worth stating before writing a test:

- **A test that calls `->build` without `client_class` set will reach for a
  real engine.** `t/15-plugin-defaults.t` only inspects attributes, which is
  why it gets away without the fake.
- Assert on what the plugin *sent* (`calls_of('build_image')`, the `tags`,
  `labels` and `buildargs` it passed), not only on what the fake returned — the
  latter proves the fixture.
- `Client.pm`'s own internals (`_split_image_ref`, `_extract_build_lines`,
  `_registry_for_image_ref`, `auth_for_image_ref`) are below the seam and are
  tested by calling them directly, not through the Recorder.
- `t/30-tag-attribute.t` uses `Test::Warnings` to assert the deprecation
  warnings; other files silence them with `local $SIG{__WARN__} = sub {}`.

## The registry check behind `fail_if_tag_exists`

`remote_tag_exists` asks the *registry* — `GET /distribution/{name}/json` through
`API::Docker`'s `distribution->exists` — not the local daemon, and it is real
since `API::Docker` 0.004. Before that it was a stub that always answered "no".
An engine without a `/distribution` route (rootless Podman) croaks there and the
release stops. The background is in `dzil-docker-hazards`.
