---
name: rust-localization-with-locale-simple
description: "Add i18n to a Rust app with the locale-simple crate (l!, ln!, n_!, ...). Load when a Rust project uses its macros, ships .po/.mo files, or shares msgids with a sibling."
user-invocable: false
---

# Localizing Rust apps with locale-simple

The crate `locale-simple` mirrors the Perl/Python/JavaScript `Locale::Simple` API
— same msgids, same `.po` files — with an own `.mo` reader, sprintf and
Plural-Forms evaluator. No dependencies, no `unsafe`. Minimum Rust 1.67.

## Install

```
cargo add locale-simple
```

## Minimal setup

```rust
use locale_simple::{l, ln, l_dir, ltd, l_lang};

l_dir("share/locale");   // <dir>/<lang>/LC_MESSAGES/<domain>.mo
ltd("myapp");            // default text domain
l_lang("de_DE");         // "de_AT:fr" style lists work
```

## Macros, not functions

Rust has no variadic functions and no runtime `%` formats, so the helpers are
macros collecting `Display` arguments:

| Call | When |
|---|---|
| `l!(msgid, args…)` | plain |
| `ln!(msgid, plural, n, args…)` | plural; `n` is prepended to the args |
| `lp!(ctxt, msgid, args…)`, `lnp!(ctxt, msgid, plural, n, args…)` | context |
| `ld!`, `ldn!`, `ldp!`, `ldnp!` | explicit domain first |

The setup calls stay functions: `l_dir`, `l_lang`, `l_dry(Some(path), nowrite)`
(`path` is a `PathBuf`: `l_dry(Some("seen.po".into()), false)`), `l_nolocales`,
`ltd`. The result is always a `String`.

**Deferred markers are lower-case**, unlike every other runtime: `n_!`, `nn_!`,
`np_!`, `nnp_!`, `nd_!`, `ndn_!`, `ndp_!`, `ndnp_!` (snake_case macros). Plural
ones give a tuple: `let (sg, pl) = nn_!("1 file", "%d files"); ln!(sg, pl, n)`.

## Concurrency: Translator

The macros use process-wide state (`RwLock`). For per-request languages use the
Rust extension:

```rust
let t = locale_simple::Translator::new();
t.l_dir("share/locale"); t.ltd("myapp"); t.l_lang("fr");
t.l("Hello", &[]);
```

Same operations as methods (arguments as `&[&dyn Display]`), shared `.mo`
cache, `Send + Sync`.

## Failure and plurals

Without `l_dir` (and without `l_nolocales(true)`) calls panic with "please set a
locale directory with l_dir() ...". Plural forms come from each `.mo` header; a
broken header falls back to `n != 1` with one warning on stderr per process.
Missing sprintf arguments leave the placeholder unchanged.

## Compiling .po → .mo

`msgfmt myapp.po -o myapp.mo`. `locale-simple scrape` scans `.rs`
files (the macros with round brackets, `"..."` and raw strings) for extraction.
`locale-simple` comes from the [release binary](https://github.com/Getty/locale-simple#binary-no-perl-needed) (no Perl needed) or
`cpanm Locale::Simple`.

## Common mistakes

- Searching for `N_!` — it is `n_!` here.
- Passing a non-`Display` value as a format argument.
- Switching `l_lang` per request on the global state — use a `Translator`.
