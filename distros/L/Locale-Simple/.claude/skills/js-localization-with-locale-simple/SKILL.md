---
name: js-localization-with-locale-simple
description: "Add i18n to a JavaScript / TypeScript app with the locale-simple npm package — same gettext-style API as the Perl and Python siblings. Load when editing a JS project that imports locale-simple, ships translated bundles, or shares .po files with Perl/Python code."
user-invocable: false
---

# Localizing JS / TS apps with locale-simple

`locale-simple` (npm) is the JavaScript sibling of the Perl `Locale::Simple`
and Python `locale_simple` modules. Same function names, same msgids, same
`.po` files — no native dependencies, pure JS.

## Install

```
npm install locale-simple
```

Ships three builds from one source:

| Build | File | Used by |
|---|---|---|
| ESM | `dist/index.js` | bundlers, modern Node |
| CJS | `dist/index.cjs` | legacy Node, `require()` |
| UMD | `dist/locale-simple.umd.js` | drop-in `<script>` (global `LocaleSimple`) |

TypeScript types: `dist/index.d.ts`.

## Minimal setup

Unlike Perl/Python, the JS build has **no filesystem `gettext` reader** —
there are no `.mo` files at runtime. You feed it JSON-shaped data:

```js
import { ltd, l_lang, loadTranslations, l, ln } from 'locale-simple';

loadTranslations('myapp', 'de_DE', {
  'Hello':                     'Hallo',
  'You have %d message':       ['Du hast %d Nachricht',
                                'Du hast %d Nachrichten'],
  'open\x04File':              'Datei öffnen',   // context: "open" + \x04 + msgid
});

ltd('myapp');
l_lang('de_DE');

console.log(l('Hello'));                                        // "Hallo"
console.log(ln('You have %d message',
               'You have %d messages', 4));                     // "Du hast 4 Nachrichten"
```

### `loadLocaleData` — po2json format

If your toolchain emits `po2json` output (or you run `bin/po2json` from the
Perl distribution), pass it straight in:

```js
import { loadLocaleData } from 'locale-simple';
import de from './locale/de_DE.json' assert { type: 'json' };

loadLocaleData('myapp', de);
```

## Translation calls

| Call | Signature |
|---|---|
| `l(msgid, ...args)` | plain |
| `ln(msgid, msgid_plural, n, ...args)` | plural |
| `lp(ctxt, msgid, ...args)` | context |
| `lnp(ctxt, msgid, msgid_plural, n, ...args)` | plural + context |
| `ld(domain, msgid, ...args)` | other domain |
| `ldn`, `ldp`, `ldnp` | domain variants |

The bundled `sprintf` supports positional args (`%1$s`, `%2$d`) so format
strings stay compatible with the Perl/Python sides.

## Workflow with the Perl scraper

Even in a pure-JS project, the easiest way to extract msgids is still the
Perl scraper — it parses `.js`, `.ts`, `.tx`, `.pl`, `.py` uniformly:

```bash
cpanm Locale::Simple                  # one-time
locale_simple_scraper \
    --ignore node_modules --ignore dist --ignore build \
    > po/myapp.pot

# Translate → de_DE.po, then:
po2json de_DE.po de_DE.json           # ships with Locale::Simple
```

Then in the app:

```js
import de from './locale/de_DE.json';
loadLocaleData('myapp', de);
```

No runtime Perl needed — scraping is build-time only.

## Build setup for bundlers

ESM import resolves automatically under Vite, webpack 5, esbuild, Rollup.
Nothing special required — `package.json`'s `exports` field points the right
build at the right consumer.

For UMD / browser `<script>`:

```html
<script src="https://unpkg.com/locale-simple/dist/locale-simple.umd.js"></script>
<script>
  const { ltd, l_lang, loadTranslations, l } = LocaleSimple;
  // …
</script>
```

## Switching language at runtime

`l_lang(newLang)` is cheap — it just flips a pointer to the per-domain data
you already loaded. For SPAs:

```js
async function setLanguage(lang) {
  if (!hasLoaded(lang)) {
    const data = await fetch(`/locale/${lang}.json`).then(r => r.json());
    loadLocaleData('myapp', data);
  }
  l_lang(lang);
  rerender();
}
```

## Common mistakes

- **Calling `l()` before `loadTranslations` / `loadLocaleData`** — returns
  the raw msgid. If that's fine in dev (English = msgid), document it; in
  strict builds, assert that a translation exists for the active language
  before rendering.
- **Dynamic msgids** — `l("Hello, " + name)` is a runtime string and
  extraction can't see it. Always use sprintf: `l("Hello, %s", name)`.
- **Mixing `loadTranslations` and `loadLocaleData` for the same domain/lang**
  — the later call wins. Pick one source of truth.
- **Tree-shaking** — `locale-simple` is tiny (~3 KB min). Don't wrap it in a
  custom facade just to "shake unused helpers"; you'll pay more in your
  facade than you'd save.
- **`l_dir` on JS** — it exists but is a no-op placeholder kept for API
  symmetry with Perl/Python. The JS build doesn't read the filesystem.
