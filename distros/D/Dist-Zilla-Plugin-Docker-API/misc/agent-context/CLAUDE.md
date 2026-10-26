# CLAUDE.md

Repo-specific guidance for Claude Code working on
`Dist::Zilla::Plugin::Docker::API`.

## The 12 Rules

These are the operating rules for this repo. They inherit from the global
and workspace `CLAUDE.md` — what's listed here is the authoritative set
for this distribution.

1. **Use `mcp__serper__google_search` or `mcp__firecrawl__firecrawl_search`**
   over `WebSearch` for any web lookup.

2. **Use `mcp__firecrawl__firecrawl_scrape`** over `WebFetch` for fetching
   page content.

3. **Use `context7` for library docs** (CPAN, npm, etc.) — *except* this
   distribution itself. For `Dist::Zilla::Plugin::Docker::API` always read
   the local source under `lib/`, never context7.

4. **Untracked files that are not in `.gitignore` belong in the commit.**
   `.gitignore` is the source of truth. Only obvious secrets
   (`.env`, credentials) are excluded — and even then warn, don't silently
   drop them.

5. **Auto-Memory is for personal/user preferences only.** Project
   conventions belong in this `CLAUDE.md` or in a skill, never in
   auto-memory.

6. **Perl edits go to a `dzil-docker-*` agent**, which gets
   `getty-perl-core` and the object-system skills force-loaded via
   `briefing.skills`. If you are editing Perl without that briefing, load
   `getty-perl-core` first. See Delegation below.

7. **`use Module;` to load modules.** Only use `require` when there's a
   real runtime reason (lazy plugin loading, optional deps), not just to
   defer cost.

8. **`->instance` for `MooX::Singleton` / `MooseX::Singleton` classes.**
   `->new` for everything else.

9. **A Getty-authored dependency may be pinned to its next, unreleased
   version.** This workspace tests its distributions together from their
   working trees, so `cpanfile` is allowed to name a version that is not
   on CPAN yet — `requires 'API::Docker', '0.003';` while CPAN is still
   at 0.002 is deliberate, not a slip. Two things follow, and both are
   binding: nothing is released before everything it depends on has been
   released, and `cpanm --info Module::Name` is what tells you where CPAN
   actually stands before you assume a pin is satisfiable for anyone
   outside this machine.

10. **Pin every Getty-authored dependency** in `cpanfile` — to the
    released version, or to the coming one when the change spans both
    repos.

11. **The version in `lib/Dist/Zilla/Plugin/Docker/API.pm` is the NEXT
    release.** What's currently on CPAN is the previous tag. `dzil
    release` bumps the version automatically — never bump it by hand
    before a release.

12. **`{{$NEXT}}` in `Changes` is the placeholder for the upcoming
    release.** Add entries under it as you change behavior; `dzil
    release` replaces it with the version + timestamp.

## What this plugin is

A Dist::Zilla plugin that builds and (optionally) pushes Docker images
as part of the `dzil build` / `dzil release` cycle, using
[`API::Docker`](https://metacpan.org/pod/API::Docker) — no shell-outs
to the `docker` CLI.

## Layout

```
lib/Dist/Zilla/Plugin/Docker/API.pm           # main plugin (Moose)
lib/Dist/Zilla/Plugin/Docker/API/Client.pm    # API::Docker adapter (Moo)
lib/Dist/Zilla/Plugin/Docker/API/Result.pm    # build/push result object (Moo)
lib/Dist/Zilla/Plugin/Docker/API/TagTemplate.pm # %-expansion (Moo)
t/                                            # tests
t/lib/                                        # Recorder / Unreachable client fakes
```

`API.pm` is Moose because `Dist::Zilla::Role::Plugin` is; the three helper
classes carry no Dist::Zilla dependency and stay Moo. That split is forced by
the framework, not a slip — keep it on that line.

## Build and test

```bash
prove -lr t/        # full suite, recursive; green with no container engine
dzil build          # build the dist (no image — see below)
dzil test           # full test suite
prove -lv t/30-tag-attribute.t   # single test
cpanm --installdeps .            # install deps from cpanfile
```

This plugin is **not** applied to its own `dist.ini` (only `[@Author::GETTY]`),
so `dzil build` here builds no image and runs no phase hook. Real plugin
behavior is only ever verified through the test suite.

## API conventions

- **Canonical tag attribute is `tag`** — multi-value, template-enabled,
  defaults to `['latest', '%V', '%v']`. Same list is applied at build and
  at release, and setting it *replaces* the default rather than appending.
- **`release` re-tags from `tag->[0]`, it does not rebuild.** Reordering
  the list silently changes which image a release ships.
- **`build_tag` and `release_tag` are deprecated.** They are funneled
  into `tag` by `BUILDARGS` with a deprecation warning. New code and
  new docs should never mention them outside the DEPRECATED section.
- **`image` is the canonical repo name**, `dockerfile` the Dockerfile key,
  `build_load` / `release_push` the switches. Every deprecated spelling
  (`file`, `repository`, `load`, `push`, `build_tag`, `release_tag`) is
  resolved in `BUILDARGS` and warns; the canonical key wins on collision.
  `phase` has no counterpart and is discarded with a warning.
- **An alias is only real if `BUILDARGS` resolves it.** Declaring one as a
  lazy attribute reading *from* the canonical value does nothing at all —
  that bug shipped in `repository`, `load` and `push`. The deprecated
  readers carry `init_arg => undef` so the old keys cannot bypass the
  table.
- **The key a user writes is the `init_arg`, not the attribute name**, and
  an unknown dist.ini key is discarded without an error. `dockerfile`
  shipped documented-but-unaccepted for exactly that reason. Check
  `init_arg` before documenting an attribute.
- **`mvp_multivalue_args` is the authority on repeatable keys.** A new
  repeatable attribute missing from that list silently keeps only its
  last value.
- Underscore-prefixed `init_arg`s (`_target`, `_network_mode`) exist so
  the `@Author::GETTY::Docker` bundle can inject them without exposing
  them in user-facing dist.ini. `fail_if_tag_exists` and
  `skip_latest_on_trial` are deliberately *not* hidden — users may set
  them directly. Don't add an underscore prefix unless the bundle is
  the sole writer.

## Testing notes

- Tests drive the real plugin through `Dist::Zilla::Tester->from_config`
  with an inline `dist.ini`.
- **`client_class` is the seam.** Phase tests set
  `client_class = …::Client::Recorder` (in `t/lib`, reached via
  `use lib "$Bin/lib"`), which records every call into `->calls`.
  `…::Client::Unreachable` extends it and croaks from `engine_info` for the
  precheck tests. A test that calls `->build` without setting it will reach
  for a real engine.
- `Client.pm`'s own helpers are below the seam and are tested by calling
  them directly — a Recorder-driven test cannot see them.
- `t/30-tag-attribute.t` uses `Test::Warnings` to assert deprecation
  warnings. Other test files use `local $SIG{__WARN__} = sub {}` to
  silence them.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it
yourself — the principle is a shared house rule (skilletor bundle
`getty-cpan-dist@getty`); the lanes are in `.claude/rules/dzil-docker-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug the plugin, the client adapter, cpanfile | `dzil-docker-worker` (default) |
| Write/extend tests | `dzil-docker-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `dzil-docker-release-manager` |
| POD and README | `dzil-docker-doc-writer` |

What the Docker daemon itself accepts or answers is not this repo's question —
it belongs to `../p5-api-docker`, as a ticket on that repo's board.

The agents carry their skills via `briefing.skills` (see `.claude/agents/`);
the main agent delegates rather than loading them. Skill sources live under
`.claude/skills/`, architecture and invariants in `dzil-docker-core`.

Work is tracked on this repo's `karr` board (`karr board`).

## When changing behavior

- Add a `Changes` entry under `{{$NEXT}}`.
- Update the POD in `lib/Dist/Zilla/Plugin/Docker/API.pm`.
- Update `README.md` if user-facing config keys change.
- The `@Author::GETTY::Docker` bundle in
  `../p5-dist-zilla-pluginbundle-author-getty` constructs this plugin
  programmatically — check it still works after attribute renames.
