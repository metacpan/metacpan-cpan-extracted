# locale-simple

[![PyPI version](https://img.shields.io/pypi/v/locale-simple.svg)](https://pypi.org/project/locale-simple/)
[![Python versions](https://img.shields.io/pypi/pyversions/locale-simple.svg)](https://pypi.org/project/locale-simple/)
[![License: MIT](https://img.shields.io/pypi/l/locale-simple.svg)](https://github.com/Getty/locale-simple/blob/main/LICENSE)
[![CPAN sibling](https://img.shields.io/cpan/v/Locale-Simple.svg?label=CPAN%20sibling)](https://metacpan.org/dist/Locale-Simple)
[![npm sibling](https://img.shields.io/npm/v/locale-simple.svg?label=npm%20sibling)](https://www.npmjs.com/package/locale-simple)

A tiny, sharp wrapper around `gettext` with `sprintf`-style formatting and
short, friendly helpers (`l`, `ln`, `lp`, `ld`, …). UTF‑8 only, by design.

The same API ships in three runtimes — **Perl, Python and JavaScript** — so
**one set of `.po` files feeds your whole stack**. Translate once, use
everywhere.

---

## Why locale-simple?

- **Same API across languages.** A function called `lnp` in Python behaves
  identically in Perl and JavaScript. No mental context switch when jumping
  between server, CLI tool and frontend.
- **One `.po` file for everything.** Scrape strings from Perl/Python/JS
  sources with the same scraper, ship one translation bundle.
- **`sprintf` baked in.** Both classic (`%s`) and positional (`%1$s`)
  placeholders — exactly like Perl's `sprintf` and gettext's `xgettext`
  format strings expect.
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

## API at a glance

| Function | gettext equivalent | What it does |
|---|---|---|
| `l(msgid, *args)` | `gettext` | Translate, then `sprintf` |
| `ln(msgid, msgid_plural, n, *args)` | `ngettext` | Plural form for `n` |
| `lp(ctxt, msgid, *args)` | `pgettext` | With disambiguating context |
| `lnp(ctxt, msgid, msgid_plural, n, *args)` | `npgettext` | Plural + context |
| `ld(domain, msgid, *args)` | `dgettext` | Specific text domain |
| `ldn(domain, msgid, msgid_plural, n, *args)` | `dngettext` | Domain + plural |
| `ldp(domain, ctxt, msgid, *args)` | `dpgettext` | Domain + context |
| `ldnp(domain, ctxt, msgid, msgid_plural, n, *args)` | `dnpgettext` | The full thing |

### Configuration helpers

| Call | Purpose |
|---|---|
| `l_dir(path)` | Locale directory containing `<lang>/LC_MESSAGES/<domain>.mo` |
| `l_lang(code)` | Set primary language (`de_DE`, `pt_BR`, …) |
| `ltd(domain)` | Default text domain |
| `l_dry(path)` | Append every encountered string to a `.po`-ish file (scrape mode) |
| `l_nolocales(bool)` | Skip lookup, return the formatted msgid (handy in tests) |

## Sibling packages

| Runtime | Package | Repo path |
|---|---|---|
| Perl | [`Locale::Simple`](https://metacpan.org/dist/Locale-Simple) on CPAN | `lib/Locale/Simple.pm` |
| Python | [`locale-simple`](https://pypi.org/project/locale-simple/) on PyPI | `python/locale_simple.py` |
| JavaScript | [`locale-simple`](https://www.npmjs.com/package/locale-simple) on npm | `js/src/index.js` |

All three share the same source tree:
<https://github.com/Getty/locale-simple>

## License

MIT © Torsten Raudssus
