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

6. **Load the `perl-core` skill before editing any Perl** in this
   workspace. It encodes Getty's house rules; the rules below are the
   TL;DR.

7. **`use Module;` to load modules.** Only use `require` when there's a
   real runtime reason (lazy plugin loading, optional deps), not just to
   defer cost.

8. **`->instance` for `MooX::Singleton` / `MooseX::Singleton` classes.**
   `->new` for everything else.

9. **Never copy `$VERSION` from a Getty-authored repo into a cpanfile.**
   The repo version is the *next* unreleased version. Check
   `cpanm --info` for the actual released version when pinning.

10. **Pin every Getty-authored dependency** to its latest released CPAN
    version in `cpanfile`.

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
lib/Dist/Zilla/Plugin/Docker/API.pm           # main plugin
lib/Dist/Zilla/Plugin/Docker/API/Client.pm    # API::Docker adapter
lib/Dist/Zilla/Plugin/Docker/API/Result.pm    # build/push result object
lib/Dist/Zilla/Plugin/Docker/API/TagTemplate.pm # %v / %g / %n expansion
t/                                            # tests (prove -l t/)
```

## Build and test

```bash
dzil build          # build the dist
dzil test           # full test suite
prove -lv t/30-tag-attribute.t   # single test
cpanm --installdeps .            # install deps from cpanfile
```

## API conventions

- **Canonical tag attribute is `tag`** — multi-value, template-enabled,
  defaults to `['latest', '%v']`. Same list is applied at build and at
  release.
- **`build_tag` and `release_tag` are deprecated.** They are funneled
  into `tag` by `BUILDARGS` with a deprecation warning. New code and
  new docs should never mention them outside the DEPRECATED section.
- **`image` is the canonical repo name.** `repository` is a deprecated
  alias kept for now.
- **`build_load` / `release_push` are the canonical switches.**
  `load` / `push` are deprecated aliases.
- Underscore-prefixed `init_arg`s (`_target`, `_network_mode`) exist so
  the `@Author::GETTY::Docker` bundle can inject them without exposing
  them in user-facing dist.ini. `fail_if_tag_exists` and
  `skip_latest_on_trial` are deliberately *not* hidden — users may set
  them directly. Don't add an underscore prefix unless the bundle is
  the sole writer.

## Testing notes

- Tests use `Dist::Zilla::Tester::from_config` with an inline `dist.ini`.
- `t/30-tag-attribute.t` uses `Test::Warnings` to assert deprecation
  warnings. Other test files use `local $SIG{__WARN__} = sub {}` to
  silence them.

## When changing behavior

- Add a `Changes` entry under `{{$NEXT}}`.
- Update the POD in `lib/Dist/Zilla/Plugin/Docker/API.pm`.
- Update `README.md` if user-facing config keys change.
- The `@Author::GETTY::Docker` bundle in
  `../p5-dist-zilla-pluginbundle-author-getty` constructs this plugin
  programmatically — check it still works after attribute renames.
