---
name: python-localization-with-locale-simple
description: "Add i18n to a Python app with the locale-simple package. Load when a Python project imports locale_simple, ships .po/.mo files, or shares msgids with a sibling."
user-invocable: false
---

# Localizing Python apps with locale-simple

`locale-simple` is a thin wrapper around the stdlib `gettext` module that
mirrors the API of its Perl, JavaScript, PHP, Go and Rust siblings exactly — same function
names, same msgids, same `.po` files.

## Install

```
pip install locale-simple
```

Single-file module — no C extensions, no runtime data files.

## Minimal setup

```python
from locale_simple import l_dir, ltd, l_lang, l, ln

l_dir('share/locale')   # directory containing <lang>/LC_MESSAGES/<domain>.mo
ltd('myapp')            # text domain
l_lang('de_DE')         # active language
```

The module keeps its state in module-level globals — `import` it once and the
settings stick for the whole process. For web apps this matters (see
"Concurrency" below).

## Translation calls

| Call | When |
|---|---|
| `l(msgid, *args)` | plain translation |
| `ln(msgid, msgid_plural, n, *args)` | plural forms |
| `lp(ctxt, msgid, *args)` | msgid with context |
| `lnp(ctxt, msgid, msgid_plural, n, *args)` | plural + context |
| `ld(domain, msgid, *args)` | translation in a different domain, bound to `l_dir` on first use |
| `ldn`, `ldp`, `ldnp` | domain variants |

`*args` go through the module's own `sprintf`, which formats like Perl's:
positional style (`%1$s`, `%2$d`), `%b`, and `'` plus a pad character
(`%'*8s`). Argument values go in as they are, so a `%` in them stays; `%%` in
the format gives one `%`; a placeholder without an argument stays as it is:

```python
print(l('Hello %s, you have %d messages', name, count))
print(ln('%2$s brought %1$d message',
         '%2$s brought %1$d messages', n, 'harry'))
```

## Directory layout

```
share/
  locale/
    de_DE/LC_MESSAGES/myapp.mo
    pt_BR/LC_MESSAGES/myapp.mo
```

In a packaged app, point `l_dir` at the installed share dir:

```python
import importlib.resources as resources
l_dir(str(resources.files('myapp') / 'locale'))
```

## Compiling .po → .mo

`locale-simple` only *reads* `.mo` files. To compile them:

```bash
msgfmt share/locale/de_DE/LC_MESSAGES/myapp.po \
       -o share/locale/de_DE/LC_MESSAGES/myapp.mo
```

`locale-simple scrape` scans `.py` files too, so the same extraction workflow
covers Python. `locale-simple` comes from the
[release binary](https://github.com/Getty/locale-simple#binary-no-perl-needed)
(no Perl needed) or `cpanm Locale::Simple`.

## Dry-run / msgid collection

```python
from locale_simple import l_dry
l_dry('seen_msgids.po')
```

With `l_dry` active, every call appends its msgid block (`# domain:`,
`msgctxt`, `msgid`, `msgid_plural`) to the file and returns the msgid formatted
by the same `sprintf` as a translation, `%1$s` included. The file is UTF-8 with
LF line ends, with backslash, newline, tab, carriage return and double quote
escaped, byte for byte what the Perl module writes.
`l_dry('seen_msgids.po', True)` skips the file, `l_dry(None)` leaves dry mode.

## Skipping locales entirely (tests / scripts)

If you want to call `l()` without setting up any locale dir (useful in tests
or in a dry-run pipeline), call `l_nolocales(True)` before anything else.
Without it, `ltd()` and every helper write `"please set a locale directory
with l_dir() before using other translate functions"` to stderr and exit with
status 1 when `l_dir()` was not called. Dry-run mode lifts that check too.

## Concurrency

`gettext` state is process-global. In threaded or async servers, do **not**
change `l_lang` per-request from one shared process — switching the locale
while another thread is mid-translation leads to cross-contamination.
Options:

- One-language-per-process: pin `l_lang` at startup, shard workers by
  language.
- Per-request `ld(...)` / `dgettext` with a request-scoped `Translations`
  object if you need many languages in one worker (you'll bypass the
  `locale_simple` helpers for that one case).

## Packaging a consumer

A `pyproject.toml` for an app that uses `locale-simple`:

```toml
[project]
name = "myapp"
dependencies = [
    "locale-simple>=0.021",
]

[tool.setuptools.package-data]
myapp = ["locale/*/LC_MESSAGES/*.mo"]
```

## Common mistakes

- **Importing `from locale_simple import *` and shadowing `l`** — `l` is a
  one-letter name; a local `l = ...` in the same scope silently replaces the
  translator. Prefer explicit imports.
- **Calling before `ltd`** — you'll get the raw msgid back. Always do `l_dir`
  + `ltd` + `l_lang` during app startup.
- **Forgetting to compile `.po`** — `gettext` reads `.mo` only.
- **Python version format** — `__version__` is set as a string like
  `"0.021"`; setuptools normalizes to `0.21` on PyPI (PEP 440). That's
  expected, not a bug.
