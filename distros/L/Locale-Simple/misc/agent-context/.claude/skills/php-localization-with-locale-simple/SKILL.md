---
name: php-localization-with-locale-simple
description: "Add i18n to a PHP app with the raudssus/locale-simple Composer package. Load when a PHP project uses the Locale\Simple functions, ships .po/.mo files, or shares msgids with a sibling."
user-invocable: false
---

# Localizing PHP apps with locale-simple

`raudssus/locale-simple` mirrors the Perl/Python/JavaScript `Locale::Simple` API —
same names, same msgids, same `.po` files. It reads `.mo` files with its own
reader: no `ext-gettext`, no `ext-mbstring`, no dependencies. PHP 8.0+.

## Install

```
composer require raudssus/locale-simple
```

The package autoloads `php/src/Simple.php` through Composer's `files` autoload
(functions need `files`, PSR-4 only loads classes).

## Minimal setup

```php
use function Locale\Simple\{l, ln, lp, ld, l_dir, ltd, l_lang};

l_dir(__DIR__ . '/locale');   // <dir>/<lang>/LC_MESSAGES/<domain>.mo
ltd('myapp');                 // default text domain
l_lang('de_DE');              // "de_AT:fr" style lists work
```

State is process-wide (static). Under PHP-FPM that is one request; under
Swoole/RoadRunner/ReactPHP do not switch `l_lang` per request on a shared worker.

## Translation calls

| Call | When |
|---|---|
| `l($msgid, ...$args)` | plain |
| `ln($msgid, $plural, $n, ...$args)` | plural; `$n` is prepended to the sprintf args |
| `lp($ctxt, $msgid, ...$args)` | context |
| `lnp($ctxt, $msgid, $plural, $n, ...$args)` | context + plural |
| `ld($domain, $msgid, ...$args)`, `ldn`, `ldp`, `ldnp` | explicit domain |

Formatting is the package's own sprintf: `%s %d %u %c %b %o %x %X %e %f %F`,
flags `+ - 0 space '<char>` (`%'*8s`), width, precision and `%1$s` positions,
formatted as in the other runtimes. A placeholder without an argument stays
unchanged; extra arguments are ignored.

## Deferred markers

`N_`, `Nn_`, `Np_`, `Nnp_`, `Nd_`, `Ndn_`, `Ndp_`, `Ndnp_` return their msgid
unchanged (the scraper finds them); the plural ones return `[singular, plural]`
— spread it together with the count, `ln(...Nn_('1 file', '%d files'), ...[$n])`,
or destructure it, `[$sg, $pl] = Nn_('1 file', '%d files'); ln($sg, $pl, $n)`.

## Dry run and no-locales

`l_dry('seen.po')` appends every call's msgid block to the file and still
returns text; `l_dry(null)` leaves it. The file is UTF-8 with LF line ends, with
backslash, newline, tab, carriage return and double quote escaped, byte for
byte what the Perl, Python, Go and Rust packages write. `l_nolocales(true)` lifts the
"set l_dir() first" check (a `RuntimeException` otherwise).

## Plural forms

Each `.mo` header's `Plural-Forms` is evaluated (never guessed from the language
name). A missing or broken header falls back to `n != 1` with one
`E_USER_WARNING` per process — a test run with `failOnWarning` will show it.

## Compiling .po → .mo

The package only reads `.mo`: `msgfmt myapp.po -o myapp.mo`. `locale-simple scrape`
scans `.php` files (heredoc/nowdoc and namespace-qualified calls included) for
the extraction step. `locale-simple` comes from the
[release binary](https://github.com/Getty/locale-simple#binary-no-perl-needed) (no Perl needed) or `cpanm Locale::Simple`.

## Common mistakes

- Shadowing `l` with a local function or `use function` clash — import explicitly.
- Calling before `ltd` — the domain falls back to `messages`.
- Forgetting to compile `.po` — only `.mo` is read.
