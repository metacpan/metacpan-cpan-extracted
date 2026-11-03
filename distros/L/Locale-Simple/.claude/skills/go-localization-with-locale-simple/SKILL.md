---
name: go-localization-with-locale-simple
description: "Add i18n to a Go app with the github.com/Getty/locale-simple module (L, Ln, Lp, ...). Load when a Go project imports it, ships .po/.mo files, or shares msgids with a sibling."
user-invocable: false
---

# Localizing Go apps with locale-simple

The module `github.com/Getty/locale-simple` mirrors the Perl/Python/JavaScript
`Locale::Simple` API — same msgids, same `.po` files — with an own `.mo` reader
and sprintf, standard library only.

## Install

```
go get github.com/Getty/locale-simple
```

The package lives in `go/` and is named `simple` (`go` is a keyword):

```go
import ls "github.com/Getty/locale-simple/go"
```

## Minimal setup

```go
ls.LDir("share/locale")   // <dir>/<lang>/LC_MESSAGES/<domain>.mo
ls.Ltd("myapp")           // default text domain
ls.LLang("de_DE")         // "de_AT:fr" style lists work
```

## Names

Go exports only capitalised names: `LDir`, `LLang`, `LDry`, `LNolocales`, `Ltd`,
`L`, `Ln`, `Lp`, `Lnp`, `Ld`, `Ldn`, `Ldp`, `Ldnp`. The deferred markers keep
their names (`N_`, `Nn_`, ... `Ndnp_`); the plural ones return `(singular, plural)`.

| Call | When |
|---|---|
| `L(msgid, args...)` | plain |
| `Ln(msgid, plural string, n int, args...)` | plural; `n` is prepended to the args |
| `Lp(ctxt, msgid, args...)` | context |
| `Ld(domain, msgid, args...)`, `Ldn`, `Ldp` | explicit domain |
| `Ldnp(domain, ctxt, msgid, plural string, n int, args...)` | full form; empty ctxt/plural = not set |

Formatting is the module's own (`fmt.Sprintf` cannot do `%1$s`): `%s %d %u %c %b
%o %x %X %e %f %F`, flags `+ - 0 space '<char>`, width, precision, positions. A
placeholder without an argument stays unchanged.

## Concurrency: use a Translator per request

The package functions share process-wide state (mutex-protected, but one
language for everybody). A web server with per-request languages uses the Go
extension instead:

```go
tr := ls.NewTranslator()
tr.LDir("share/locale"); tr.Ltd("myapp"); tr.LLang(lang)
tr.L("Hello")
```

Same methods, shared `.mo` cache, safe for concurrent use.

## Failure and plurals

Without `LDir` (and without `LNolocales(true)`) calls panic with "please set a
locale directory with l_dir() ..."; recover if needed. Plural forms come from
each `.mo` header; a broken header falls back to `n != 1` with one `log` warning.

## Compiling .po → .mo

`msgfmt myapp.po -o myapp.mo`. `locale-simple scrape` scans `.go` files
(strings in `"..."` and backticks) for the extraction step. `locale-simple`
comes from the [release binary](https://github.com/Getty/locale-simple#binary-no-perl-needed) (no Perl needed) or `cpanm Locale::Simple`.

## Common mistakes

- Importing the package without an alias and then calling it `go.L` — it is `simple`.
- A repo-root `go.mod` makes every `.go` file in the repo part of the module:
  extraction fixtures need `//go:build ignore`.
- Switching `LLang` per request on the global state — use a `Translator`.
