# locale-simple

[![npm version](https://img.shields.io/npm/v/locale-simple.svg)](https://www.npmjs.com/package/locale-simple)
[![npm downloads](https://img.shields.io/npm/dm/locale-simple.svg)](https://www.npmjs.com/package/locale-simple)
[![License: MIT](https://img.shields.io/npm/l/locale-simple.svg)](https://github.com/Getty/locale-simple/blob/main/js/LICENSE)
[![CPAN sibling](https://img.shields.io/cpan/v/Locale-Simple.svg?label=CPAN%20sibling)](https://metacpan.org/dist/Locale-Simple)
[![PyPI sibling](https://img.shields.io/pypi/v/locale-simple.svg?label=PyPI%20sibling)](https://pypi.org/project/locale-simple/)

A tiny, sharp gettext wrapper with `sprintf`-style formatting and short,
friendly helpers (`l`, `ln`, `lp`, `ld`, …). UTF‑8 only, by design. Ships
ESM, CJS and TypeScript types out of the box.

The same API ships in three runtimes — **Perl, Python and JavaScript** — so
**one set of `.po` files feeds your whole stack**. Translate once, use
everywhere.

---

## Why locale-simple?

- **Same API across languages.** A function called `lnp` in JavaScript
  behaves identically in Perl and Python. No mental context switch when
  jumping between server, CLI tool and frontend.
- **One `.po` file for everything.** Scrape strings from Perl/Python/JS
  sources with the same scraper, ship one translation bundle.
- **`sprintf` baked in.** Both classic (`%s`) and positional (`%1$s`)
  placeholders — exactly like Perl's `sprintf` and gettext's `xgettext`
  format strings expect.
- **Tiny.** A single ESM module, no runtime dependencies, fully
  tree-shakeable.

## Install

```bash
npm install locale-simple
```

## Quick start

For browser / bundler use, convert your `.mo` (or `.po`) files to JSON
once with the `po2json` tool that ships in the sibling Perl distribution,
then load the resulting bundle:

```js
import { l, ln, lp, ld, loadTranslations, l_lang, ltd } from 'locale-simple';
import bundle from './locale/de_DE/myapp.json' assert { type: 'json' };

loadTranslations('myapp', 'de_DE', bundle);
ltd('myapp');
l_lang('de_DE');

console.log(l("Hello"));
// → Hallo

console.log(ln("You have %d message", "You have %d messages", 1));
// → Du hast 1 Nachricht

console.log(ln("You have %d message", "You have %d messages", 5));
// → Du hast 5 Nachrichten

console.log(lp("button", "Open"));            // context-disambiguated
console.log(ld("emails", "Welcome, %s", name)); // explicit domain
```

## API at a glance

| Function | gettext equivalent | What it does |
|---|---|---|
| `l(msgid, ...args)` | `gettext` | Translate, then `sprintf` |
| `ln(msgid, msgidPlural, n, ...args)` | `ngettext` | Plural form for `n` |
| `lp(ctxt, msgid, ...args)` | `pgettext` | With disambiguating context |
| `lnp(ctxt, msgid, msgidPlural, n, ...args)` | `npgettext` | Plural + context |
| `ld(domain, msgid, ...args)` | `dgettext` | Specific text domain |
| `ldn(domain, msgid, msgidPlural, n, ...args)` | `dngettext` | Domain + plural |
| `ldp(domain, ctxt, msgid, ...args)` | `dpgettext` | Domain + context |
| `ldnp(domain, ctxt, msgid, msgidPlural, n, ...args)` | `dnpgettext` | The full thing |

### Configuration

| Call | Purpose |
|---|---|
| `loadTranslations(domain, lang, data)` | Register a translation bundle (plain `{msgid: msgstr}` map; arrays for plurals) |
| `loadLocaleData(domain, data)` | Register a bundle in `po2json` / `Gettext.js` format |
| `l_lang(code)` | Set primary language (`de_DE`, `pt_BR`, …) |
| `ltd(domain)` | Default text domain |
| `l_dir(path)` | Locale directory (used in dry/scrape mode) |
| `l_dry(on, noWrite?)` | Dry-run mode for scraping translatable strings |

## Module formats

| Format | Path |
|---|---|
| ESM | `dist/index.js` |
| CommonJS | `dist/index.cjs` |
| TypeScript types | `dist/index.d.ts` |

Pick whichever your bundler / runtime prefers — modern setups will get the
ESM build automatically via `package.json#exports`.

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
