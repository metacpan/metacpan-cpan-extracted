---
name: perl-localization-with-locale-simple
description: "Add i18n to a Perl app with Locale::Simple — gettext-backed translations with the `l`, `ln`, `lp`, `ld`, … helpers. Load when editing a Perl project that needs localized strings, has a `use Locale::Simple` line, or ships .po files."
user-invocable: false
---

# Localizing Perl apps with Locale::Simple

`Locale::Simple` is a thin wrapper over `Locale::TextDomain` / `gettext`. It
exports short function names (`l`, `ln`, …) that are identical across Perl,
Python and JavaScript — so the same msgids and the same `.po` files work for
all three.

## Install

```
cpanm Locale::Simple
```

Add to `cpanfile`:

```perl
requires 'Locale::Simple';
```

## Minimal setup

Exactly three setup calls, in any order:

```perl
use Locale::Simple;

l_dir('share/locale');   # where the .mo files live (dir/<lang>/LC_MESSAGES/<domain>.mo)
ltd('myapp');            # text domain (matches the .mo filename)
l_lang('de_DE');         # active language
```

From that point on, every `l("…")` returns the translated string — or the
original msgid when no translation exists.

## Translation calls

| Call | When |
|---|---|
| `l($msgid, @args)` | plain translation |
| `ln($msgid, $msgid_plural, $n, @args)` | plural forms (e.g. 1 message vs. N messages) |
| `lp($ctxt, $msgid, @args)` | same msgid, different contexts (`"open"` as verb vs. adjective) |
| `lnp($ctxt, $msgid, $msgid_plural, $n, @args)` | plural + context |
| `ld($domain, $msgid, @args)` | translation in a different domain without switching `ltd` |
| `ldn`, `ldp`, `ldnp` | domain + the above variants |

`@args` is fed through `sprintf`, so Perl positional formats work:

```perl
l('Hello %s, you have %d messages', $name, $count);
ln('%2$s brought %1$d message', '%2$s brought %1$d messages', $n, 'harry');
```

## Directory layout convention

```
share/
  locale/
    de_DE/LC_MESSAGES/myapp.mo
    pt_BR/LC_MESSAGES/myapp.mo
    …
```

Pair this with `File::ShareDir` so installed apps still find their `.mo`
files:

```perl
use File::ShareDir qw(dist_dir);
l_dir(dist_dir('MyApp') . '/locale');
```

## Extracting msgids from source

Run the scraper shipped with the distribution:

```bash
locale_simple_scraper \
    --ignore node_modules --ignore .build --ignore local \
    > po/myapp.pot
```

It statically scans `.pl`, `.pm`, `.py`, `.js`, `.tx` files and emits a
standard `.pot` — feed that to `msgmerge` / Poedit / Weblate like any other
gettext project.

**Scraper limits** — strings must be parseable statically:

```perl
l("Hello");                                 # ✓
l("Hello, " . $name);                       # ✗ interpolated value — use sprintf
l(sprintf("Hello, %s", $name));             # ✗ scraper doesn't cross sprintf
l("Hello, %s", $name);                      # ✓ let l() do the sprintf
l("a" . "b");                               # ✓ static concatenation is fine
```

Keep msgids constant; pass dynamic data through `@args`.

## Dry-run mode

`l_dry($filename)` makes every call *also* append its msgid to `$filename` in
`.po` format, while still returning translations — useful when you want the
live system to collect unseen msgids:

```perl
l_dry('seen_msgids.po') if $ENV{COLLECT_MSGIDS};
```

## Testing translations

Point `l_dir` at a test fixture and run assertions:

```perl
use Test::More;
use Locale::Simple;

l_dir('t/data/locale');
ltd('test');
l_lang('de_DE');

is l('Hello'), 'Hallo';
is ln('You have %d message', 'You have %d messages', 4),
   'Du hast 4 Nachrichten';

done_testing;
```

## Common mistakes

- **Forgetting `ltd`** — without a text domain, `gettext` returns the msgid
  unchanged. `l_dir` alone is not enough.
- **Reassigning `l_lang` per request** — fine in a script, but in a long-lived
  process (PSGI, Mojolicious) remember that `setlocale(LC_MESSAGES, …)` is
  process-global. Serialize or pin it per request.
- **UTF-8 double-encoding** — `Locale::Simple` already encodes msgids and
  decodes the gettext result. Don't `Encode::encode` around `l()` — you'll get
  mojibake.
- **`@EXPORT` collisions** — `l` is a short, common name. If another module
  also exports `l`, use `Locale::Simple qw(ltd l_lang)` and keep `l` qualified
  (`Locale::Simple::l(…)`).
