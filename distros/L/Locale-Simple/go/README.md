# locale-simple for Go

A tiny wrapper around gettext `.mo` files with `sprintf`-style formatting and
short helpers (`L`, `Ln`, `Lp`, `Ld`, …). The same API ships for Perl, Python,
JavaScript, PHP and Rust, so one set of `.po` files feeds the whole stack.

No dependencies: the package reads `.mo` files itself (standard library only).

## Install

```bash
go get github.com/Getty/locale-simple
```

The module lives in the repository root, the package in `go/`:

```go
import ls "github.com/Getty/locale-simple/go"
```

(The package is named `simple`; `go` is a keyword and cannot be a package name,
hence the alias.)

## Quick start

```go
ls.LDir("data/locale")   // <dir>/<lang>/LC_MESSAGES/<domain>.mo
ls.Ltd("myapp")          // default text domain
ls.LLang("de_DE")        // language, "de_AT:fr" style lists work too

fmt.Println(ls.L("Hello"))                                          // Hallo
fmt.Println(ls.Ln("You have %d message", "You have %d messages", 5)) // Du hast 5 Nachrichten
fmt.Println(ls.Lp("button", "Open"))                                // context
fmt.Println(ls.Ld("emails", "Welcome, %s", name))                   // explicit domain
```

## API

Go exports only capitalised names, so the lower-case names of the other
runtimes become `LDir`, `LLang`, `LDry`, `LNolocales`, `Ltd`, `L`, `Ln`, `Lp`,
`Lnp`, `Ld`, `Ldn`, `Ldp`, `Ldnp`. The deferred markers keep their names:
`N_`, `Nn_`, `Np_`, `Nnp_`, `Nd_`, `Ndn_`, `Ndp_`, `Ndnp_`.

`Ldnp(domain, msgctxt, msgid, msgidPlural string, n int, args ...any)` is the
full form and all other helpers delegate to it. An empty `msgctxt` or
`msgidPlural` means "not set". With a plural, `n` is prepended to `args`.

The plural markers return two values: `sg, pl := ls.Nn_("1 file", "%d files")`.

`LDry(file, nowrite)` appends the msgid blocks of every call to `file` instead
of translating; `LDry("", false)` leaves dry-run mode. The file is UTF-8 with LF
line ends, with backslash, newline, tab, carriage return and double quote
escaped, byte for byte what the Perl, Python, PHP and Rust packages write.

### Translator (Go extension)

The package functions work on process-wide state. A web server translating per
request wants one language per request, not a global switch, so there is also

```go
tr := ls.NewTranslator()
tr.LDir("data/locale"); tr.Ltd("myapp"); tr.LLang("fr")
tr.L("Hello")
```

with the same methods as the package functions. All Translators and the package
functions share one catalog cache, so each `.mo` file is read once per process.
Everything is safe for concurrent use.

## Behaviour worth knowing

- Plural forms come from each `.mo` header and are evaluated by a small parser.
  A missing or broken header falls back to `n != 1` and logs one warning.
- A language like `de_AT:fr` is tried as `de_AT`, `de`, `fr`; an empty
  translation falls through to the next candidate and finally to the msgid.
- `sprintf` is the package's own: `%s %d %u %c %b %o %x %X %e %f %F`, flags
  `+ - 0 space '<char>`, width, precision and `%1$s` positions. A placeholder
  without an argument stays unchanged; extra arguments are ignored.
- Without `LDir` (and without `LNolocales(true)`) a call panics with
  "please set a locale directory with l_dir() before using other translate
  functions"; recover from it if you need to.

## Tests

```bash
go test ./go/...
go test -race ./go/...
```

The suite uses the fixtures in `t/data/` shared with all other runtimes.
