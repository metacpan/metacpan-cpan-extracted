# CLAUDE.md — locale-simple

**One codebase, six packages.** This repository publishes the same gettext
wrapper as a Perl CPAN distribution (`Locale-Simple`), a Python package
(`locale-simple`), a JavaScript npm package (`locale-simple`), a PHP Composer
package (`raudssus/locale-simple`), a Go module
(`github.com/Getty/locale-simple`) and a Rust crate (`locale-simple`). All six
implement the same helper API (`l`, `ln`, `lp`, `ld`, the `ld*` family, the
`l_dir` / `l_lang` configuration, the `N_` markers) — a change to one runtime is
usually a change to all six. The accepted exceptions are listed in
`.claude/rules/language-parity.md`.

**`dist.ini` is the truth for the build and the release.** The `[@Author::GETTY]`
bundle drives the CPAN release, the Python bump and the Python upload; the npm
and crates.io publishes happen asynchronously in CI after the tag push, Packagist
and the Go module proxy pick the tag up themselves.

Project knowledge — layout, build and test commands, the release path, the
scraper quirks, the house rules — lives in skill `locale-simple-core`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it
yourself — the principle is a shared house rule (skilletor bundle
`getty-cpan-dist@getty`); lanes and deviations are in `.claude/rules/locale-simple-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug the Perl, Python or JavaScript runtime, the scraper, the Perl code of the commands (`Locale::Simple::CLI`, `bin/*`) | `locale-simple-worker` (default) |
| The PHP port (`php/`, `composer.json`) | `locale-simple-php-worker` |
| The Go port (`go/`, `go.mod`) | `locale-simple-go-worker` |
| The Rust port (`rust/`) | `locale-simple-rust-worker` |
| The standalone binary (packing `bin/locale-simple` with PAR, shipping it, `scripts/*binary*`, `release-binaries.yml`) | `locale-simple-binary-worker` |
| Write/extend the tests of the six suites | `locale-simple-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `locale-simple-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the
main agent delegates rather than loading them. Skill sources live under
`.claude/skills/`.

## Tests

```bash
prove -lr t/                                 # Perl suite
python python/test.py                        # Python suite
cd js && npm install && npm test             # JavaScript suite
composer install && composer test            # PHP suite
go test ./go/...                             # Go suite
cargo test --manifest-path rust/Cargo.toml   # Rust suite
```

`prove -l` is mandatory: without it the installed CPAN release is loaded instead
of `lib/`. `dzil test` runs the PHP, Go and Rust suites through
`xbin/run-sibling-tests.pl`, which skips a missing or too old toolchain with a
message; CI runs all six.

## Skills

| Skill | Source | Purpose |
|---|---|---|
| `locale-simple-core` | this repository | project knowledge — architecture, release path, known drift |
| `getty-perl-core`, `getty-perl-moo`, `getty-git-commit-style`, `getty-git-usage`, `perl-release-dist-ini` | installed by `skilletor` | shared library conventions |
| `kanban-issues-karr-coordination`, `kanban-issues-karr-ticket` | installed by `skilletor` | the karr board |
| `perl-…`, `python-…`, `js-…`, `php-…`, `go-…`, `rust-localization-with-locale-simple` | tracked in this repository | **usage** skills for consumers of locale-simple — not build skills |

The installed skills are build artefacts of `skilletor sync` — never edit them
here; change the source.
