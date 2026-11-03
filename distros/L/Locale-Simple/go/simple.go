// Package simple is locale-simple for Go: gettext-style translation helpers
// with sprintf formatting and the same API as the Perl, Python, JavaScript,
// PHP and Rust siblings. It reads .mo files itself and has no dependencies.
//
// The module path is github.com/Getty/locale-simple and the package lives in
// the go/ directory, so it is imported as
//
//	import ls "github.com/Getty/locale-simple/go"
//
// Exported names must be capitalised in Go, hence L, Ln, Lp, ... instead of
// l, ln, lp, ...; the N_ family keeps its names. The package functions work on
// process-wide state; Translator is the same set of operations as a value.
package simple

// LDir sets the directory holding <lang>/LC_MESSAGES/<domain>.mo.
func LDir(dir string) { global.LDir(dir) }

// LLang sets the language, e.g. "de_DE" or "de_AT:fr".
func LLang(lang string) { global.LLang(lang) }

// LDry appends the msgids of every call to file instead of translating; an
// empty file leaves dry-run mode.
func LDry(file string, nowrite bool) { global.LDry(file, nowrite) }

// LNolocales turns the "set LDir first" check off (true) or on (false).
func LNolocales(on bool) { global.LNolocales(on) }

// Ltd sets the default text domain.
func Ltd(domain string) { global.Ltd(domain) }

func L(msgid string, args ...any) string { return global.L(msgid, args...) }

func Ln(msgid, msgidPlural string, n int, args ...any) string {
	return global.Ln(msgid, msgidPlural, n, args...)
}

func Lp(msgctxt, msgid string, args ...any) string { return global.Lp(msgctxt, msgid, args...) }

func Lnp(msgctxt, msgid, msgidPlural string, n int, args ...any) string {
	return global.Lnp(msgctxt, msgid, msgidPlural, n, args...)
}

func Ld(domain, msgid string, args ...any) string { return global.Ld(domain, msgid, args...) }

func Ldn(domain, msgid, msgidPlural string, n int, args ...any) string {
	return global.Ldn(domain, msgid, msgidPlural, n, args...)
}

func Ldp(domain, msgctxt, msgid string, args ...any) string {
	return global.Ldp(domain, msgctxt, msgid, args...)
}

// Ldnp is the full form; an empty msgctxt or msgidPlural means "not set".
func Ldnp(domain, msgctxt, msgid, msgidPlural string, n int, args ...any) string {
	return global.Ldnp(domain, msgctxt, msgid, msgidPlural, n, args...)
}

// Deferred-translation markers: they return their msgid(s) unchanged so the
// scraper sees them while the lookup happens later. The plural variants
// return the pair (singular, plural).

func N_(msgid string) string { return msgid }

func Nn_(singular, plural string) (string, string) { return singular, plural }

func Np_(msgctxt, msgid string) string { return msgid }

func Nnp_(msgctxt, singular, plural string) (string, string) { return singular, plural }

func Nd_(domain, msgid string) string { return msgid }

func Ndn_(domain, singular, plural string) (string, string) { return singular, plural }

func Ndp_(domain, msgctxt, msgid string) string { return msgid }

func Ndnp_(domain, msgctxt, singular, plural string) (string, string) { return singular, plural }
