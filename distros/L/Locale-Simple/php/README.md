# locale-simple for PHP

A tiny wrapper around gettext `.mo` files with `sprintf`-style formatting and
short helpers (`l`, `ln`, `lp`, `ld`, …). The same API ships for Perl, Python,
JavaScript, Go and Rust, so one set of `.po` files feeds the whole stack.

No extensions and no dependencies: the package reads `.mo` files itself and
needs neither `ext-gettext` nor `ext-mbstring`. PHP 8.0 or newer.

## Install

```bash
composer require raudssus/locale-simple
```

## Quick start

```php
use function Locale\Simple\{l, ln, lp, ld, l_dir, l_lang, ltd};

l_dir('data/locale');   // <dir>/<lang>/LC_MESSAGES/<domain>.mo
ltd('myapp');           // default text domain
l_lang('de_DE');        // language, "de_AT:fr" style lists work too

echo l('Hello');                                        // Hallo
echo ln('You have %d message', 'You have %d messages', 5); // Du hast 5 Nachrichten
echo lp('button', 'Open');                              // context
echo ld('emails', 'Welcome, %s', $name);                // explicit domain
```

## API

All names are functions in the namespace `Locale\Simple`.

| Function | Purpose |
|---|---|
| `l_dir($dir)` | directory holding `<lang>/LC_MESSAGES/<domain>.mo` |
| `l_lang($lang)` | language; without it `LC_ALL`, `LC_MESSAGES`, `LANG`, `LANGUAGE` decide |
| `ltd($domain)` | default text domain |
| `l_dry($file, $nowrite = false)` | dry run: append the msgids of every call to `$file`, UTF-8 with LF line ends and backslash, newline, tab, carriage return and double quote escaped, the same bytes as the Perl, Python, Go and Rust packages; `l_dry(null)` leaves it |
| `l_nolocales($on)` | skip the "set `l_dir()` first" check |
| `l($id, ...$args)` | translate |
| `ln($id, $plural, $n, ...$args)` | plural; `$n` is prepended to the sprintf arguments |
| `lp($ctxt, $id, ...$args)` | with context |
| `lnp($ctxt, $id, $plural, $n, ...$args)` | context and plural |
| `ld`, `ldn`, `ldp`, `ldnp` | the same with the text domain as first argument |
| `N_`, `Nn_`, `Np_`, `Nnp_`, `Nd_`, `Ndn_`, `Ndp_`, `Ndnp_` | deferred markers for the scraper |

The deferred markers return their argument; the plural ones return an array
`[singular, plural]`. Spread it together with the count:
`ln(...Nn_('1 file', '%d files'), ...[$n])`, or destructure it:
`[$sg, $pl] = Nn_('1 file', '%d files'); ln($sg, $pl, $n)`.

## Behaviour worth knowing

- Plural forms come from the `Plural-Forms` header of each `.mo` file, evaluated
  by a small parser (never `eval`). A missing or broken header falls back to
  `n != 1` and raises one `E_USER_WARNING` per process.
- A language like `de_AT:fr` is tried as `de_AT`, `de`, `fr`; an empty
  translation falls through to the next candidate and finally to the msgid.
- `sprintf` is the package's own: `%s %d %u %c %b %o %x %X %e %f %F`, flags
  `+ - 0 space '<char>`, width, precision and `%1$s` positions, formatted as in
  the other runtimes. A placeholder without an argument stays unchanged; extra
  arguments are ignored.
- Without `l_dir()` (and without `l_nolocales(true)`) a call throws a
  `RuntimeException`.

## Tests

```bash
composer install
composer test
```

The suite uses the fixtures in `t/data/` shared with all other runtimes.
