# locale-simple for Rust

A tiny wrapper around gettext `.mo` files with `sprintf`-style formatting and
short helpers (`l!`, `ln!`, `lp!`, `ld!`, …). The same API ships for Perl,
Python, JavaScript, PHP and Go, so one set of `.po` files feeds the whole stack.

No dependencies and no `unsafe`: the crate reads `.mo` files itself.

## If you come from Perl, Python or JavaScript: read this first

Two things differ because Rust asks for it:

- **The helpers are macros**, not functions: Rust has no variadic functions and
  no runtime `%` formats. `l!("Hello %s", name)` collects the arguments and calls
  the function `l(msgid, &[&dyn Display])`.
- **The deferred markers are lower-case:** `n_!`, `nn_!`, `np_!`, `nnp_!`,
  `nd_!`, `ndn_!`, `ndp_!`, `ndnp_!` (snake_case is the Rust convention for
  macros). Everywhere else they are `N_`, `Nn_`, … — search for the lower-case
  names here. The `l*` family keeps its names: `l!`, `ln!`, `lp!`, `lnp!`, `ld!`,
  `ldn!`, `ldp!`, `ldnp!`.

## Install

```bash
cargo add locale-simple
```

## Quick start

```rust
use locale_simple::{l, ln, lp, ld, l_dir, l_lang, ltd};

l_dir("data/locale");   // <dir>/<lang>/LC_MESSAGES/<domain>.mo
ltd("myapp");           // default text domain
l_lang("de_DE");        // language, "de_AT:fr" style lists work too

println!("{}", l!("Hello"));                                         // Hallo
println!("{}", ln!("You have %d message", "You have %d messages", 5)); // Du hast 5 Nachrichten
println!("{}", lp!("button", "Open"));                               // context
println!("{}", ld!("emails", "Welcome, %s", name));                  // explicit domain
```

## API

| Item | Purpose |
|---|---|
| `l_dir(dir)` | directory holding `<lang>/LC_MESSAGES/<domain>.mo` |
| `l_lang(lang)` | language; without it `LC_ALL`, `LC_MESSAGES`, `LANG`, `LANGUAGE` decide |
| `ltd(domain)` | default text domain |
| `l_dry(Some(path), nowrite)` | dry run: append the msgids of every call to the file (`path` is a `PathBuf`: `l_dry(Some("seen.po".into()), false)`), UTF-8 with LF line ends and backslash, newline, tab, carriage return and double quote escaped, the same bytes as the Perl, Python, PHP and Go packages; `l_dry(None, false)` leaves it |
| `l_nolocales(on)` | skip the "set `l_dir()` first" check |
| `l!(id, args…)` | translate |
| `ln!(id, plural, n, args…)` | plural; `n` is prepended to the sprintf arguments |
| `lp!(ctxt, id, args…)`, `lnp!(ctxt, id, plural, n, args…)` | with context |
| `ld!`, `ldn!`, `ldp!`, `ldnp!` | the same with the text domain first |
| `n_!` … `ndnp_!` | deferred markers for the scraper |

Arguments are anything that implements `Display`; the result is a `String`.
The plural markers evaluate to a tuple: `let (sg, pl) = nn_!("1 file", "%d files");
ln!(sg, pl, n)`.

### Translator (Rust extension)

The package functions work on process-wide state. For code that translates per
request in several languages at once there is a value with the same operations:

```rust
let t = locale_simple::Translator::new();
t.l_dir("data/locale"); t.ltd("myapp"); t.l_lang("fr");
t.l("Hello", &[]);
t.ln("%d file", "%d files", 3, &[]);   // n is prepended, as with ln!
```

All translators and the package functions share one catalog cache, so each
`.mo` file is read once per process. Everything is `Send + Sync`.

## Behaviour worth knowing

- Plural forms come from each `.mo` header and are evaluated by a small parser.
  A missing or broken header falls back to `n != 1` and prints one warning to
  stderr per process.
- A language like `de_AT:fr` is tried as `de_AT`, `de`, `fr`; an empty
  translation falls through to the next candidate and finally to the msgid.
- `sprintf` is the crate's own: `%s %d %u %c %b %o %x %X %e %f %F`, flags
  `+ - 0 space '<char>`, width, precision and `%1$s` positions. A placeholder
  without an argument stays unchanged; extra arguments are ignored. Numbers are
  read from the `Display` text of the argument.
- Without `l_dir` (and without `l_nolocales(true)`) a call panics with
  "please set a locale directory with l_dir() before using other translate
  functions".
- Minimum Rust version: 1.67 (from there on `{:.0}` rounds a tie to the even digit,
  which the sprintf relies on).

## Tests

```bash
cargo test --manifest-path rust/Cargo.toml
```

The suite uses the fixtures in `t/data/` shared with all other runtimes.
