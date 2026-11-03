# locale-simple

[![PyPI version](https://img.shields.io/pypi/v/locale-simple.svg)](https://pypi.org/project/locale-simple/)
[![Python versions](https://img.shields.io/pypi/pyversions/locale-simple.svg)](https://pypi.org/project/locale-simple/)
[![License: MIT](https://img.shields.io/pypi/l/locale-simple.svg)](https://github.com/Getty/locale-simple/blob/main/LICENSE)
[![CPAN sibling](https://img.shields.io/cpan/v/Locale-Simple.svg?label=CPAN%20sibling)](https://metacpan.org/dist/Locale-Simple)
[![npm sibling](https://img.shields.io/npm/v/locale-simple.svg?label=npm%20sibling)](https://www.npmjs.com/package/locale-simple)

A tiny, sharp wrapper around `gettext` with `sprintf`-style formatting and
short, friendly helpers (`l`, `ln`, `lp`, `ld`, …). UTF‑8 only, by design.

The same API ships for **Perl, Python, JavaScript, PHP, Go and Rust** — so
**one set of `.po` files feeds your whole stack**. Translate once, use
everywhere.

---

## Why locale-simple?

- **Same API across languages.** A function called `lnp` in Python behaves
  identically in the other five runtimes. No mental context switch when
  jumping between server, CLI tool and frontend.
- **One `.po` file for everything.** One scraper (`locale-simple scrape`)
  reads the sources of all six languages, so one translation bundle covers
  the whole stack.
- **`sprintf` baked in.** Both classic (`%s`) and positional (`%1$s`)
  placeholders — exactly like Perl's `sprintf` and gettext's `xgettext`
  format strings expect, `%b` and the `'` pad flag (`%'*8s`) included.
  Argument values go in as they are, so a `%` in them stays, and a
  placeholder without an argument stays as it is.
- **Boring and small.** Single-file module, no surprises, no magic.

## Install

```bash
pip install locale-simple
```

## Quick start

```python
from locale_simple import l, ln, lp, ld, l_dir, l_lang, ltd

l_dir('data/locale')   # where your .mo files live
ltd('myapp')           # default text domain
l_lang('de_DE')        # primary language

print(l("Hello"))
# → Hallo

print(ln("You have %d message", "You have %d messages", 1))
# → Du hast 1 Nachricht

print(ln("You have %d message", "You have %d messages", 5))
# → Du hast 5 Nachrichten

print(lp("button", "Open"))           # context-disambiguated
print(ld("emails", "Welcome, %s", name))  # explicit domain
```

## Extracting msgids

`locale-simple scrape` walks your sources (`.py` next to the other five
languages) and writes the `.pot` template to STDOUT. Get `locale-simple` as a
standalone binary from the
[GitHub release](https://github.com/Getty/locale-simple#binary-no-perl-needed)
(no Perl needed) or with `cpanm Locale::Simple`:

```bash
locale-simple scrape --ignore venv > messages.pot
```

## API at a glance

| Function | gettext equivalent | What it does |
|---|---|---|
| `l(msgid, *args)` | `gettext` | Translate, then `sprintf` |
| `ln(msgid, msgid_plural, n, *args)` | `ngettext` | Plural form for `n` |
| `lp(ctxt, msgid, *args)` | `pgettext` | With disambiguating context |
| `lnp(ctxt, msgid, msgid_plural, n, *args)` | `npgettext` | Plural + context |
| `ld(domain, msgid, *args)` | `dgettext` | Specific text domain, bound to the `l_dir()` directory on first use |
| `ldn(domain, msgid, msgid_plural, n, *args)` | `dngettext` | Domain + plural |
| `ldp(domain, ctxt, msgid, *args)` | `dpgettext` | Domain + context |
| `ldnp(domain, ctxt, msgid, msgid_plural, n, *args)` | `dnpgettext` | The full thing |

### Configuration helpers

| Call | Purpose |
|---|---|
| `l_dir(path)` | Locale directory containing `<lang>/LC_MESSAGES/<domain>.mo`; a later call moves every bound domain to the new directory |
| `l_lang(code)` | Set primary language (`de_DE`, `pt_BR`, …) |
| `ltd(domain)` | Default text domain |
| `l_dry(path)` | Dry run: append each call's msgid block (`# domain:`, `msgctxt`, `msgid`, `msgid_plural`) to `path` in UTF-8 with LF line ends, the same bytes the Perl module writes, and return the formatted msgid; `l_dry(path, True)` skips the file, `l_dry(None)` leaves dry mode |
| `l_nolocales(bool)` | Lift the "set `l_dir()` first" check that `ltd()` and every helper make; without a directory the formatted msgid comes back (handy in tests) |

## Sibling packages

| Runtime | Package | Repo path |
|---|---|---|
| Perl | [`Locale::Simple`](https://metacpan.org/dist/Locale-Simple) on CPAN | `lib/Locale/Simple.pm` |
| Python | [`locale-simple`](https://pypi.org/project/locale-simple/) on PyPI | `python/locale_simple.py` |
| JavaScript | [`locale-simple`](https://www.npmjs.com/package/locale-simple) on npm | `js/src/index.js` |
| PHP | [`raudssus/locale-simple`](https://packagist.org/packages/raudssus/locale-simple) on Packagist | `php/src/Simple.php` |
| Go | [`github.com/Getty/locale-simple/go`](https://pkg.go.dev/github.com/Getty/locale-simple/go) | `go/` |
| Rust | [`locale-simple`](https://crates.io/crates/locale-simple) on crates.io | `rust/` |

All six share the same source tree:
<https://github.com/Getty/locale-simple>

## License

MIT © Torsten Raudssus
