---
name: dist-zilla-pluginbundle-author-getty-core
description: "Use when working on the Dist-Zilla-PluginBundle-Author-GETTY distribution — the [@Author::GETTY] bundle class and its configure() plugin assembly, the dist.ini attribute surface, GitHub/Gitea/Forgejo remote auto-detection, the @Author::GETTY::Docker subsection, or the shared .github/actions/dzil-test composite CI action that every GETTY dist consumes."
---

# Dist::Zilla::PluginBundle::Author::GETTY — architecture and invariants

This distribution is the `[@Author::GETTY]` plugin bundle **itself**: the release
and CI mechanics that every other GETTY distribution inherits. That makes it a
special case in two directions — it *defines* the machinery the other repos only
*consume*, and it *dogfoods* that machinery on its own source. When a convention
here changes, it changes for the whole estate, not just this repo.

For consuming `[@Author::GETTY]` from a downstream dist.ini (options, POD
commands, next-version semantics), that is the `getty-perl-release-author-getty`
skill's job. This skill is the bundle's own internals.

## The bundle dogfoods itself

`dist.ini` is two lines of plugins:

```ini
[Bootstrap::lib]
[@Author::GETTY]
```

`[Bootstrap::lib]` puts this repo's own `lib/` on `@INC` *before* the bundle
loads, so `dzil build`/`dzil test`/`dzil release` here run the **in-development**
bundle code on the bundle's own distribution. A change to `configure()` takes
effect on this very repo's next build — there is no released-version indirection
to hide behind. A syntax error or a broken plugin assembly breaks this repo's own
`dzil` before it ever reaches CPAN.

## The bundle is one Moose class assembling plugins

`lib/Dist/Zilla/PluginBundle/Author/GETTY.pm` is a single Moose class
(`with 'Dist::Zilla::Role::PluginBundle::Easy'`). Every dist.ini key a downstream
sets arrives in `$self->payload`; each is surfaced as a lazy attribute with its
default, and `configure()` reads those attributes to `add_plugins`/`add_bundle`
in order. The shape to keep:

- **A new user-facing option is: a `has` with a `payload->{...}` default, its POD
  `=head2`, and a branch in `configure()`.** Miss the POD and `PodSyntaxTests`
  (always active) will not catch it, but downstream users have no documentation;
  miss the attribute and the payload key is silently ignored.
- **Repeatable keys must be listed in `mvp_multivalue_args`.** A repeatable option
  (the `run_*`, `gather_*`, `alien_*` arrays, `commit_files_after_release`,
  `version_finder`) that is not in that method keeps only its last value with no
  error. This is the same trap the `@Author::GETTY::Docker` subsection carries.
- **`log_fatal` is the validation channel.** Mutually-exclusive options
  (`weaver_config`+`task`, `author`+`no_cpan`, `no_install`+`no_makemaker`) die
  through `log_fatal` in `configure()`, not via type constraints.

## Remote auto-detection drives repository metadata

The bundle reads `.git/config` in the dist root (dzil's cwd) itself — it does not
ask Dist::Zilla. `_has_github_remote` scans for a `github.com` url; `_remote_host`
parses the first remote's host. From these, repository metadata is **three-way and
additive**, decided in `configure()`:

- GitHub remote present → `[GithubMeta]`, and `GitHub::CreateRelease` on release.
- No GitHub but a Gitea/Forgejo host (a known host in `@KNOWN_GITEA_HOSTS`, or
  `gitea = 1`) → `[Author::GETTY::GiteaMeta]` built for that host.
- Anything else → the generic `[Repository]`.

`no_github` and `no_github_release` both **default to auto**: unset, they become 1
when no GitHub remote is detected. A downstream dist on Codeberg needs no flags;
one that must force GitHub plugins on without a detected remote sets
`no_github = 0` explicitly. When editing this, remember the tests fabricate a
`.git/config` in a tempdir (`t/github_autodetect.t`, `t/gitea_autodetect.t`) —
detection is filesystem I/O, so it is testable without a real remote.

## Subsections read defaults through a package global

`[@Author::GETTY::Docker / name]` subsections
(`lib/.../Author/GETTY/Docker.pm`) inherit `image`/`tags`/`local` from the parent
bundle via the package global `%Dist::Zilla::PluginBundle::Author::GETTY::DOCKER_DEFAULTS`,
which `bundle_config` populates before `configure` runs. Each subsection builds one
`Docker::API` plugin. `docker_image` on the parent auto-adds a single default
subsection unless `docker_default = 0`. The `_target`/`_network_mode` keys are
underscore-prefixed because the bundle injects them into `Docker::API` and they are
not user-facing there — mirror that when adding a bundle-injected key.

## Shared CI: the `dzil-test` composite action is the single source of truth

`.github/actions/dzil-test/action.yml` is a composite GitHub Action that **every**
`[@Author::GETTY]` dist consumes:

```yaml
- uses: Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@v1
```

Its four steps are the canonical dzil CI mechanics. Dists that pin `@v1` (the
recommended ref) pick up a change here once the `v1` tag is moved onto it; dists
still pinning `@main` get it on their next CI run:

1. `cpanm -nq Dist::Zilla`
2. `dzil authordeps --missing | cpanm -nq` — installs the bundle and every
   dist.ini plugin (`authordeps` reads dist.ini statically, needs only Dist::Zilla).
3. `dzil listdeps --author --missing | cpanm -nq` — runtime/test/build **and**
   develop-phase prereqs.
4. `dzil <command>` (default `test`).

**The `--author` flag on `listdeps` is load-bearing, not decoration.** It pulls
develop-phase author-test deps — notably `Test::Pod`, which `[PodSyntaxTests]`
(always active in this bundle) registers as a `develop requires`. Plain
`dzil listdeps` omits them and the author tests die on a missing module.

**Never fake `Test::Pod` (or any author-test dep) into a dist's cpanfile
`on test` block.** That hack is exactly what this action removes: the deps belong
in the develop phase, and `--author` is how CI installs them. This repo's own
`cpanfile` proves the rule — its `on test` block carries only `Test::More`, no
`Test::Pod`, and CI still passes.

The bundle's own `.github/workflows/ci.yml` dogfoods the action through the local
path `./.github/actions/dzil-test` (not the cross-repo URL), so a change to the
action is exercised by this repo's own CI before consumers see it. Inputs
(`command`, `install-type` for `ALIEN_INSTALL_TYPE`, `cpanm-opts`) and the
Forgejo/self-hosted-Gitea usage are documented in
`.github/actions/dzil-test/README.md` and the module's `CONTINUOUS INTEGRATION`
POD section — keep those two in sync with `action.yml`.

## Cross-repo consumer: p5-dist-zilla-plugin-docker-api

`@Author::GETTY::Docker` constructs `Dist::Zilla::Plugin::Docker::API`
programmatically (it is pinned in `cpanfile`). The plugin lives in
`../p5-dist-zilla-plugin-docker-api`; questions about what that plugin's
attributes or `init_arg`s accept are **its** repo's, and a needed change there is
a ticket on its board, not a workaround in the subsection. If the subsection here
starts passing a key the plugin no longer accepts, that is a coordinated change
across the two repos.

## Tests

`prove -lr t/` — recursive, so a future subdirectory under `t/` is not silently
skipped. `dzil test` is the release-time equivalent and runs the woven `xt/`
author/release tests too. The suite fabricates `.git/config` files in tempdirs
to exercise remote detection; it needs no real remote and no network. `dzil build`
in this repo builds the bundle's own distribution through its own in-development
code (see dogfooding above). Never run `dzil release`.
