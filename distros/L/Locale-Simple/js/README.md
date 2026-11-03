# locale-simple

[![npm version](https://img.shields.io/npm/v/locale-simple.svg)](https://www.npmjs.com/package/locale-simple)
[![npm downloads](https://img.shields.io/npm/dm/locale-simple.svg)](https://www.npmjs.com/package/locale-simple)
[![License: MIT](https://img.shields.io/npm/l/locale-simple.svg)](https://github.com/Getty/locale-simple/blob/main/js/LICENSE)
[![CPAN sibling](https://img.shields.io/cpan/v/Locale-Simple.svg?label=CPAN%20sibling)](https://metacpan.org/dist/Locale-Simple)
[![PyPI sibling](https://img.shields.io/pypi/v/locale-simple.svg?label=PyPI%20sibling)](https://pypi.org/project/locale-simple/)

A tiny, sharp gettext wrapper with `sprintf`-style formatting and short,
friendly helpers (`l`, `ln`, `lp`, `ld`, …). UTF‑8 only, by design. Ships
ESM, CJS and TypeScript types out of the box.

The same API ships for **Perl, Python, JavaScript, PHP, Go and Rust** — so
**one set of `.po` files feeds your whole stack**. Translate once, use
everywhere.

---

## Why locale-simple?

- **Same API across languages.** A function called `lnp` in JavaScript
  behaves identically in the other five runtimes. No mental context switch
  when jumping between server, CLI tool and frontend.
- **One `.po` file for everything.** One scraper (`locale-simple scrape`) reads the sources of all six
  languages, so one translation bundle covers the whole stack.
- **`sprintf` baked in.** Both classic (`%s`) and positional (`%1$s`)
  placeholders — exactly like Perl's `sprintf` and gettext's `xgettext`
  format strings expect, with the conversions `b c d e E f F g G i o s u x X`,
  the flags `+ - 0` and space, `'` plus a pad character (`%'*8s`), width and
  precision. Argument values go in as they are, so a `%` in them stays, and a
  placeholder without an argument stays as it is.
- **Tiny.** A single ESM module, no runtime dependencies, fully
  tree-shakeable.

## Install

```bash
npm install locale-simple
```

## Quick start

For browser / bundler use, convert your `.po` files to JSON once with
`locale-simple po2json`. Get `locale-simple` as a standalone binary from the
[GitHub release](https://github.com/Getty/locale-simple#binary-no-perl-needed)
(no Perl needed) or with `cpanm Locale::Simple`:

```bash
locale-simple po2json locale/de_DE/LC_MESSAGES/myapp.po > locale/de_DE/myapp.json
```

The output is wrapped as `{ "myapp": ... }`, the domain being the file name
without `.po`. Then load the resulting bundle; the language and the plural
rule come from its header:

```js
import { l, ln, lp, ld, loadLocaleData, l_lang, ltd } from 'locale-simple';
import bundle from './locale/de_DE/myapp.json' with { type: 'json' };

loadLocaleData('myapp', bundle);
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

An empty msgid returns an empty string without a lookup.

### Configuration

| Call | Purpose |
|---|---|
| `loadTranslations(domain, lang, data, pluralForms?)` | Register a translation bundle (plain `{msgid: msgstr}` map; arrays for plurals). `pluralForms` is the `Plural-Forms` header value; omitted means `n != 1` |
| `loadLocaleData(domain, data)` | Register `locale-simple po2json` output (`{ [domain]: bundle }`, Gettext.js format); the `Language` and `Plural-Forms` headers of the bundle select the language and the plural form |
| `l_lang(code)` | Set the language (`de_DE`, `pt-BR`, …); a list like `de_AT:fr` tries `de_AT`, `de`, `fr`, then a bundle loaded without language |
| `ltd(domain)` | Default text domain |
| `l_dir(path)` | Accepted for API symmetry; the browser has no locale directory |
| `l_dry(on, noWrite?)` | Dry-run mode: write the msgid block of every call to `console.debug` (see below) |
| `l_nolocales(on)` | Accepted for API symmetry; a no-op in JavaScript |

## Dry-run mode

`l_dry(true)` makes every translation return its msgid (or the plural for
`n != 1`), formatted with its arguments, and write its block in one
`console.debug` call. The block holds the lines `# domain: ...`,
`msgctxt "..."`, `msgid "..."` and `msgid_plural "..."` that apply, with
backslash, newline, tab, carriage return and double quote escaped as in a
`.po` file. It ends with a newline, so the console shows it followed by a blank
line, the same bytes the Perl and Python packages write to their dry-run file:

```
# domain: myapp
msgctxt "menu"
msgid "%d file"
msgid_plural "%d files"

```

An empty msgid writes no block. `l_dry(true, true)` keeps dry-run mode without
the output.

## Plural forms

The `Plural-Forms:` header of a bundle is evaluated (no `eval`; a small parser
for the C subset gettext uses), so Polish, Russian, Arabic, Japanese and the
rest pick the right form:

```js
loadTranslations('myapp', 'pl_PL', bundle,
  'nplurals=3; plural=(n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);');
```

A bundle loaded through `loadLocaleData` carries the header itself. A missing or
unparsable header falls back to `n != 1` with a single `console.warn` per
process; `loadTranslations` without the fourth argument keeps `n != 1` silently.

## Module formats

| Format | Path |
|---|---|
| ESM | `dist/index.js` |
| CommonJS | `dist/index.cjs` |
| UMD (browser global `LocaleSimple`) | `dist/locale-simple.umd.js` |
| TypeScript types | `src/index.d.ts` |

Pick whichever your bundler / runtime prefers — modern setups will get the
ESM build automatically via `package.json#exports`.

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
