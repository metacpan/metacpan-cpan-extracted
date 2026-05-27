# `dzil-test` — shared CI step for `[@Author::GETTY]` dists

A composite GitHub Action that does the repetitive Dist::Zilla CI mechanics so
every distribution using `[@Author::GETTY]` shares one source of truth:

1. `cpanm -nq Dist::Zilla`
2. `dzil authordeps --missing | cpanm -nq` — installs the bundle and every
   `dist.ini` plugin (`dzil authordeps` reads `dist.ini` statically, so it works
   with only Dist::Zilla installed).
3. `dzil listdeps --author --missing | cpanm -nq` — installs runtime/test/build
   **and** develop-phase prereqs. The `--author` flag is the important bit: it
   pulls author-test deps like `Test::Pod` that `[PodSyntaxTests]` registers as
   `develop requires`. Without it you'd have to fake `Test::Pod` into the
   cpanfile's `on test` block — don't.
4. `dzil <command>` (default `test`).

## Use it (you already have a workflow)

Drop it into your own job, after checkout and any system-library install. You
keep your matrix and your `apt-get`/`brew` steps; only the dzil part is shared:

```yaml
steps:
  - uses: actions/checkout@v4
  - run: apt-get update && apt-get install -y libgit2-dev pkg-config   # per-dist
  - uses: Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main
```

Alien dist forcing a vendored build:

```yaml
  - uses: Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main
    with:
      install-type: share          # -> ALIEN_INSTALL_TYPE=share
```

## Inputs

| Input          | Default                                              | Purpose |
|----------------|------------------------------------------------------|---------|
| `command`      | `test`                                               | dzil command to run (`test`, `build`, …) |
| `install-type` | *(empty)*                                            | `ALIEN_INSTALL_TYPE` value; `share` forces vendored build |
| `cpanm-opts`   | `--mirror http://cpan.metacpan.org --mirror-only`    | extra `PERL_CPANM_OPT` |

## Using on Forgejo / self-hosted Gitea

The action is forge-neutral (plain shell + cpanm + dzil). Reference it with a
fully-qualified URL so Forgejo fetches it from GitHub regardless of the
instance's `DEFAULT_ACTIONS_URL` setting:

```yaml
- uses: https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main
```

Forgejo reads `.github/workflows/` as well as `.forgejo/workflows/`, so the
same YAML can trigger on both forges without duplication.

**Probe test** — push this to verify your Forgejo resolves the action:

```yaml
# .forgejo/workflows/probe.yml
name: probe
on: [push]
jobs:
  probe:
    runs-on: ubuntu-latest
    container:
      image: perl:5.40-bookworm
    steps:
      - uses: https://github.com/actions/checkout@v4
      - uses: https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main
```

If the action step fails to resolve (cross-repo composite actions via
subdirectory paths are not supported in all Forgejo/act_runner versions), the
fallback is to vendor a copy of `action.yml` into the dist itself and use a
local reference:

```yaml
- uses: ./.github/actions/dzil-test
```

## Notes

- The consumer's job still needs its own `actions/checkout` — the action only
  fetches itself, not your distribution source.
- `dzil install` is intentionally **not** run here; if an Alien dist needs the
  artifact installed before tests, add that step in the caller.
- `@main` gives every dist CI changes immediately. Once stable, pin to a tag
  (`@v1`) for reproducibility.
