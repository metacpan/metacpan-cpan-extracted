# CLAUDE.md — Locale::Simple

This repository is a single codebase that publishes three packages from one
source: a Perl CPAN distribution (`Locale-Simple`), a Python package
(`locale-simple`), and a JavaScript npm package (`locale-simple`). All three
implement the same gettext-based API.

## Layout

| Path | Purpose |
|---|---|
| `lib/Locale/Simple.pm` | Perl implementation + exported `l` / `ln` / … |
| `lib/Locale/Simple/Scraper*.pm` | `Parser::MGC`-based source scraper |
| `bin/locale_simple_scraper` | CLI wrapper around the scraper |
| `bin/po2json` | PO → JSON converter for JavaScript consumers |
| `python/locale_simple.py` | Python implementation (single-file module) |
| `python/test.py` | Python test (runs against `t/data/locale`) |
| `python/pyproject.toml` | PEP 517 build config |
| `js/src/index.js` | JavaScript implementation (ESM) |
| `js/test/*.test.js` | Node.js `node:test` suite |
| `js/rollup.config.js` | Produces ESM + CJS + UMD bundles |
| `t/` | Perl test suite (`dzil test`) |
| `dist.ini` / `cpanfile` / `Changes` | `[@Author::GETTY]` release config |

## Build / Test Commands

```bash
dzil test                        # Perl tests (Dist::Zilla)
python python/test.py            # Python tests
cd js && npm install && npm test # JavaScript tests
cd js && npm run build           # JS bundles into dist/
```

## Release

Release is driven by `dzil release`. The `[@Author::GETTY]` bundle runs:

1. `run_before_release` — Python tests + JS tests + Python build + JS build smoke
2. Git tag + `cpan upload` (Perl)
3. `run_after_release` — bumps `python/locale_simple.py`, builds, `twine upload`
4. `git push --tags` — triggers `.github/workflows/publish-js.yml`, which
   bumps `js/package.json` from the tag, builds, and publishes to npm via
   **Trusted Publishing (OIDC)** — no npm token, no OTP, fully automated.

Why JS is split off: npm requires OTP for publish from a personal account
(classic Automation tokens were removed Dec 2025, and the granular-token
"Bypass 2FA" checkbox is broken for personal accounts — see npm/cli#8869).
Keeping `npm publish` inside `dzil release` meant a missed OTP would leave
CPAN/PyPI uploaded but no git tag — corrupt half-state. Now JS publish is
async via CI and can never poison the dzil release.

Before releasing, ensure:
- `~/.pypirc` has a valid PyPI token (`__token__` + `pypi-*`)
- `Changes` has notes under `{{$NEXT}}`
- npm Trusted Publisher is configured for `locale-simple` →
  https://www.npmjs.com/package/locale-simple/access (Trusted Publisher:
  GitHub Actions, repo `Getty/locale-simple`, workflow `publish-js.yml`)

## Skills in this repo (source of truth)

Three usage-oriented skills live under `.claude/skills/` and are the canonical
copies — other projects hardlink them via `manage-skills`:

| Skill | Purpose |
|---|---|
| `perl-localization-with-locale-simple` | How to use `Locale::Simple` in a Perl app |
| `python-localization-with-locale-simple` | How to use `locale_simple` in Python |
| `js-localization-with-locale-simple` | How to use `locale-simple` in JS/TS |

These are **usage** skills (for projects that *consume* locale-simple), not
build/author skills for this repo itself.

Other hardlinked skills in `.claude/skills/` (e.g. `perl-moo`,
`perl-release-author-getty`, `perl-release-dist-ini`) come from
`~/dev/perl/shared-skills/` and apply because this is a Moo-based
`[@Author::GETTY]` dist.

## House rules (Perl)

- Use `use Module;` — `require` only for runtime plugin loading.
- `->instance` for singletons, `->new` otherwise.
- Never copy `$VERSION` from a Getty-authored repo into a `cpanfile` — pin to
  the latest released CPAN version (`cpanm --info ModuleName`).
- `[@Author::GETTY]` bundle default release branch is `main` — do not set it
  explicitly in `dist.ini`.

## Known quirks

- `t/50-scrape.t` uses `Test::Regression`. When the scraper's output is
  intentionally changed, regenerate references with `TEST_REGRESSION_GEN=1
  prove -l t/50-scrape.t`.
- The scraper must ignore `python`, `js`, `node_modules`, and
  `author-pod-syntax.t` (ExtraTests artefact). See the `@default` list in
  `t/50-scrape.t`.
- `Locale::Simple::Scraper::ParserShortcuts::with_ws` must set BOTH
  `$patterns{ws}` and `$patterns{_skip}` — newer `Parser::MGC` uses `_skip`
  (ws ∪ comment), so only touching `ws` is a no-op and strings lose leading
  whitespace.
