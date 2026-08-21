---
name: getty-perl-distribution
description: Use when creating a Perl CPAN distribution or bringing an existing one in line with [@Author::GETTY] — dist.ini, cpanfile, Changes, lib/, t/, CI scaffolding.
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Perl Distribution

Create or polish a Perl distribution matching Getty's workspace conventions.

## Inputs the skill expects to resolve before writing

| What | Resolution order |
|---|---|
| `dist`      | dash-form (`WWW-Foo`) — from user arg or from dir name under `~/dev/perl/p5-*` |
| `module`    | colon-form (`WWW::Foo`) — derived from `dist` by `s/-/::/g` |
| `abstract`  | one-line `# ABSTRACT:` from the first non-empty existing `lib/**/*.pm`, else ask |
| `author`    | `Torsten Raudssus <getty@cpan.org>` |
| `copyright_holder` | `Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>` |
| `copyright_year`   | current year |
| `license`   | `Perl_5` |
| `irc`       | search sibling `~/dev/perl/p5-*/dist.ini` for an existing `irc =` line in the same topic cluster; if none found, ask the user (never make one up) |

## Sibling reference

Before writing, read **one** existing sibling dist that is closest in topic
(e.g. for `p5-www-openbao` look at `~/dev/perl/p5-www-firecrawl/` because both
are HTTP-client WWW-* packages). Match its layout exactly:

- `dist.ini`
- `cpanfile` (split `on test` / `on develop` if the sibling does)
- `Changes` (`{{$NEXT}}` marker + one `0.001` entry with a bullet list)
- `README.md` (Synopsis → Description → one example per public method → License)
- `.gitignore` (copy sibling's, substituting the dist name in the build-dir ignore line)
- `t/00-load.t` using `Test::LoadAllModules` OR `use_ok` — match what the sibling uses
- Any additional `t/NN-*.t` the author convention calls for (often `10-*`, `20-*` topical tests)
- `.github/workflows/ci.yml` — copy the sibling's if it has one, else the
  fallback template (see CI workflow below)

Do NOT diverge from the sibling's style even if it feels outdated. Workspace
consistency beats "modern best practice."

## CI workflow

Every dist gets a `.github/workflows/ci.yml`. The repetitive Dist::Zilla CI
mechanics live ONCE in a shared **composite action** in the bundle repo
(`Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test`), so
the per-dist workflow only carries its matrix and any system-library install:

```yaml
- uses: Getty/p5-dist-zilla-pluginbundle-author-getty/.github/actions/dzil-test@main
```

The action runs `dzil authordeps` + `dzil listdeps --author` + `dzil test`. The
`--author` flag installs develop-phase author-test deps (e.g. `Test::Pod`, which
`[PodSyntaxTests]` registers). **Never fake `Test::Pod` into the cpanfile's
`on test`** — that is exactly the bug this setup removes.

- Pure-Perl dist: use the fallback template `templates/github-ci.yml` as-is.
- Alien / XS dist: add the `apt-get`/`brew` system-library step(s) before the
  action, and a `share-build` job passing `install-type: share`. Copy the
  layout from `~/dev/perl/p5-alien-libgit2/.github/workflows/`.

## Templates

Fallback templates (used only when no suitable sibling exists) live in this
skill's `templates/` directory: `dist.ini`, `cpanfile`, `Changes`,
`README.md`, `CLAUDE.md`, `lib_Module.pm`, `t_00-load.t`, `t_01-basic.t`,
`github-ci.yml`. Placeholders use `{{$name}}` — substitute with `sed` or
equivalent. Rename `lib_Module.pm` → `lib/<Path>/<Name>.pm`,
`t_*.t` → `t/*.t`, and `github-ci.yml` → `.github/workflows/ci.yml`.

## Handcheck rules

- Author line must be `getty@cpan.org` — only the CPAN email, no name
  with valid email + website. Refuse to fabricate either.
- Copyright year in `dist.ini` and `Changes` must match.
- IRC channel is optional but, if included, must be a real channel. Ask rather
  than invent.
- Never write `our $VERSION = ...` into `lib/*.pm` — `[@Author::GETTY]` injects
  it from the Changes file.

## After writing

Run `dzil test` inside the dist directory and surface the output. Do NOT
`dzil release` unless the user explicitly asks.

## Related

- `getty-create-software` — parent orchestrator; loads this skill for Perl projects.
- `perl-release-dist-ini` — loaded when *editing* an existing `dist.ini`.
- `getty-perl-release-author-getty` — loaded when *releasing*.
- `getty-perl-core` — Getty's house Perl style rules.
