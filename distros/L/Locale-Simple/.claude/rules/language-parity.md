---
paths:
  - "lib/**"
  - "python/**"
  - "js/**"
  - "php/**"
  - "go/**"
  - "rust/**"
  - "composer.json"
  - "go.mod"
  - "t/**"
---

# Language Parity

Six runtimes implement one API: Perl (`lib/Locale/Simple.pm`), Python
(`python/locale_simple.py`), JavaScript (`js/src/index.js`), PHP
(`php/src/Simple.php`), Go (`go/`) and Rust (`rust/`). A behavior change to one is a
change to all six, or a deliberate entry under "Accepted asymmetries" below. The shared
`.mo` reader specification is
`.claude/skills/locale-simple-core/references/mo-reader.md` (here: mo-reader.md).

## 1. What must stay in sync

| | Perl / Python / JS / PHP | Go | Rust |
|---|---|---|---|
| Translation helpers | `l ln lp lnp ld ldn ldp ldnp` | `L Ln Lp Lnp Ld Ldn Ldp Ldnp` | `l! ln! lp! lnp! ld! ldn! ldp! ldnp!` |
| Setup | `l_dir l_lang l_dry l_nolocales ltd` | `LDir LLang LDry LNolocales Ltd` | `l_dir l_lang l_dry l_nolocales ltd` (functions) |
| Deferred markers | `N_ Nn_ Np_ Nnp_ Nd_ Ndn_ Ndp_ Ndnp_` | identical | `n_! nn_! np_! nnp_! nd_! ndn_! ndp_! ndnp_!` |
| Argument order | `ldnp(domain, msgctxt, msgid, msgid_plural, n, ...args)`, every other helper delegates | same | same |

What stays the same everywhere, whatever the spelling:

- `n` is prepended to the sprintf arguments when a plural is given.
- `l('')` returns `''` without a lookup.
- The `N*` markers return their arguments unchanged; they exist for the scraper.
- Missing sprintf argument: the placeholder stays unchanged (mo-reader.md §5).
- Dry-run output format: `# domain:`, `msgctxt`, `msgid`, `msgid_plural`, blank line.
- Locale chain and plural selection: mo-reader.md §2 and §3 (own-reader runtimes), libc
  for Perl and Python.
- The shared fixtures: `t/data/locale/de_DE/LC_MESSAGES/*.mo` and
  `t/data/plural-forms.json`. Every suite ports the cases of `python/test.py`.

## 2. The scraper is the seventh consumer

`Locale::Simple::Scraper` reads sources in nine file types:
`.pl .pm .t .py .js .tx .php .go .rs`. A helper that is renamed, added or removed in any
runtime changes what the scraper must recognise: update the parser, `t/data/n-fixtures/`
and the references of `t/50-scrape.t` together. New fixtures under `t/data/` that are
`.go` files need `//go:build ignore` as first line (the root `go.mod` would otherwise
compile them).

## 3. Accepted asymmetries

Not drift; the parity check must not report these. Each is deliberate and has a reason.

- **Go capitalises** (`L`, `Ln`, ...): Go exports only capitalised names. The `N*`
  markers are already capitalised and keep their names. Optional `msgctxt` and
  `msgid_plural` use the empty string as "not set".
- **Rust uses macros** (`l!`) instead of functions: no variadic functions, no runtime
  `%` formats. The macros call functions of the same name that take `&[&dyn Display]`.
- **Rust's deferred markers are lower-case** (`n_!`, `nn_!`, ...): snake_case is the
  macro convention. The `l*` family is spelled alike in all six runtimes, the `N` family
  in five of six.
- **`N*` plural markers return different shapes:** Perl a list in list context, Python
  a tuple, JavaScript and PHP an array, Go two return values, Rust a tuple.
- **`Translator`** is a Go and Rust extension: an independent value with the same
  operations for per-request languages in a concurrent server. Both share one catalog
  cache with the package functions. The other runtimes have no such value.
- **Own `.mo` reader in PHP, Go and Rust.** Perl and Python use libc gettext. JavaScript
  reads JSON produced by `locale-simple po2json` and never touches `.mo` bytes, but shares the
  plural evaluator and the locale chain of mo-reader.md.
- **JavaScript ends the locale chain with `''`:** a bundle loaded without a language
  answers last, before the msgid. The `.mo` runtimes have no language-less catalog.
- **`loadTranslations` / `loadLocaleData` are JavaScript-only:** a browser has no
  directory. PHP, Go and Rust read `.mo` files directly and implement `l_dir` for real.
- **`l_nolocales` is a no-op only in JavaScript;** the other five have a directory, and
  the flag lifts the "set l_dir first" check.
- **Missing directory:** Perl `die`, Python `sys.exit(1)`, PHP `RuntimeException`, Go and
  Rust `panic` with the same message text.
- **`l_dry` target:** Perl, Python, PHP, Go and Rust append to a file, JavaScript writes
  to `console.debug`.

## 4. Verification

The six suite commands are in skill `locale-simple-core` ("Build and test"). `dzil test`
runs all six, PHP, Go and Rust through `xbin/run-sibling-tests.pl`, which **skips
visibly** when a toolchain is missing or too old. A skipped suite is not a passed suite:
say which ran and which did not. CI (`.github/workflows/test.yml`) runs all six.
