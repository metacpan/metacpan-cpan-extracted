package simple

import (
	"os"
	"strings"
	"sync"
)

const noDirMessage = "please set a locale directory with l_dir() before using other translate functions"

// Translator is an independent set of settings (directory, language, domain,
// dry run) with the operations of the package functions. A Go extension to the
// shared API: a web server that translates per request keeps one Translator
// per language instead of switching the process-wide state. All Translators
// and the package functions share one catalog cache.
type Translator struct {
	mu        sync.RWMutex
	dir       string
	lang      string
	langSet   bool
	domain    string
	dry       string
	nowrite   bool
	nolocales bool
}

// NewTranslator returns a Translator with nothing configured.
func NewTranslator() *Translator { return &Translator{} }

var global = NewTranslator()

// dryMu serializes appends to dry-run files across all Translators.
var dryMu sync.Mutex

// LDir sets the directory holding <lang>/LC_MESSAGES/<domain>.mo.
func (t *Translator) LDir(dir string) {
	t.mu.Lock()
	t.dir = dir
	t.mu.Unlock()
}

// LLang sets the language; "de_AT:fr" style lists are accepted. Without it the
// environment decides (LC_ALL, LC_MESSAGES, LANG, LANGUAGE).
func (t *Translator) LLang(lang string) {
	t.mu.Lock()
	t.lang, t.langSet = lang, true
	t.mu.Unlock()
}

// LDry switches to dry-run mode: every call appends its msgid block to file
// instead of translating. An empty file leaves dry-run mode.
func (t *Translator) LDry(file string, nowrite bool) {
	t.mu.Lock()
	t.dry, t.nowrite = file, nowrite
	t.nolocales = file != ""
	t.mu.Unlock()
}

// LNolocales turns the "set LDir first" check off (true) or on (false).
func (t *Translator) LNolocales(on bool) {
	t.mu.Lock()
	t.nolocales = on
	t.mu.Unlock()
}

// Ltd sets the default text domain.
func (t *Translator) Ltd(domain string) {
	t.mu.Lock()
	defer t.mu.Unlock()
	t.checkDirLocked()
	t.domain = domain
}

func (t *Translator) checkDirLocked() {
	if t.dir == "" && !t.nolocales {
		panic(noDirMessage)
	}
}

func (t *Translator) L(msgid string, args ...any) string {
	return t.Ldnp("", "", msgid, "", 0, args...)
}

func (t *Translator) Ln(msgid, msgidPlural string, n int, args ...any) string {
	return t.Ldnp("", "", msgid, msgidPlural, n, args...)
}

func (t *Translator) Lp(msgctxt, msgid string, args ...any) string {
	return t.Ldnp("", msgctxt, msgid, "", 0, args...)
}

func (t *Translator) Lnp(msgctxt, msgid, msgidPlural string, n int, args ...any) string {
	return t.Ldnp("", msgctxt, msgid, msgidPlural, n, args...)
}

func (t *Translator) Ld(domain, msgid string, args ...any) string {
	return t.Ldnp(domain, "", msgid, "", 0, args...)
}

func (t *Translator) Ldn(domain, msgid, msgidPlural string, n int, args ...any) string {
	return t.Ldnp(domain, "", msgid, msgidPlural, n, args...)
}

func (t *Translator) Ldp(domain, msgctxt, msgid string, args ...any) string {
	return t.Ldnp(domain, msgctxt, msgid, "", 0, args...)
}

// Ldnp is the full form. An empty msgctxt or msgidPlural means "not set"; n
// matters only with a plural and is prepended to args, as in the other runtimes.
func (t *Translator) Ldnp(domain, msgctxt, msgid, msgidPlural string, n int, args ...any) string {
	if msgid == "" {
		return msgid
	}
	t.mu.RLock()
	dir, lang, langSet, curDomain := t.dir, t.lang, t.langSet, t.domain
	dry, nowrite := t.dry, t.nowrite
	if t.dir == "" && !t.nolocales {
		t.mu.RUnlock()
		panic(noDirMessage)
	}
	t.mu.RUnlock()

	if msgidPlural != "" {
		args = append([]any{n}, args...)
	}
	if dry != "" {
		if !nowrite {
			writeDry(dry, domain, msgctxt, msgid, msgidPlural)
		}
		text := msgid
		if msgidPlural != "" && n != 1 {
			text = msgidPlural
		}
		return sprintf(text, args)
	}
	if dir == "" {
		return sprintf(fallback(msgid, msgidPlural, n), args)
	}
	if domain == "" {
		domain = curDomain
	}
	if domain == "" {
		domain = "messages"
	}
	var env func(string) string
	if !langSet {
		env = os.Getenv
	}
	return sprintf(lookup(dir, effectiveLang(env, lang), domain, msgctxt, msgid, msgidPlural, n), args)
}

func fallback(msgid, msgidPlural string, n int) string {
	if msgidPlural != "" && n != 1 {
		return msgidPlural
	}
	return msgid
}

// effectiveLang resolves the language string (spec §2). A nil env means
// l_lang was called and lang wins.
func effectiveLang(env func(string) string, lang string) string {
	if env == nil {
		return lang
	}
	locale := ""
	for _, v := range []string{"LC_ALL", "LC_MESSAGES", "LANG"} {
		if s := env(v); s != "" {
			locale = s
			break
		}
	}
	if locale == "" || locale == "C" || locale == "POSIX" {
		return ""
	}
	if s := env("LANGUAGE"); s != "" {
		return s
	}
	return locale
}

// candidates turns a language string into the ordered lookup chain (spec §2).
func candidates(effective string) []string {
	out := []string{}
	seen := map[string]bool{}
	add := func(s string) {
		if !seen[s] {
			seen[s] = true
			out = append(out, s)
		}
	}
	for _, e := range strings.Split(effective, ":") {
		e = strings.ReplaceAll(e, "-", "_")
		if at := strings.IndexByte(e, '@'); at >= 0 {
			e = e[:at]
		}
		if dot := strings.IndexByte(e, '.'); dot >= 0 {
			e = e[:dot]
		}
		if e == "" || e == "C" || e == "POSIX" {
			continue
		}
		add(e)
		if us := strings.IndexByte(e, '_'); us >= 0 {
			add(e[:us])
		}
	}
	return out
}

func lookup(dir, effective, domain, msgctxt, msgid, msgidPlural string, n int) string {
	key := msgid
	if msgctxt != "" {
		key = msgctxt + "\x04" + msgid
	}
	for _, cand := range candidates(effective) {
		c := loadCatalog(dir + "/" + cand + "/LC_MESSAGES/" + domain + ".mo")
		if c == nil {
			continue
		}
		forms, ok := c.entries[key]
		if !ok {
			continue
		}
		idx := 0
		if msgidPlural != "" {
			idx = c.rule.index(n)
		}
		if idx < len(forms) && forms[idx] != "" {
			return forms[idx]
		}
	}
	return fallback(msgid, msgidPlural, n)
}

// gettextEscape escapes backslash, newline, tab, carriage return and double
// quote for a dry-run line, in that order, as gettext_escape in Perl and
// Python does.
func gettextEscape(s string) string {
	s = strings.ReplaceAll(s, `\`, `\\`)
	s = strings.ReplaceAll(s, "\n", `\n`)
	s = strings.ReplaceAll(s, "\t", `\t`)
	s = strings.ReplaceAll(s, "\r", `\r`)
	return strings.ReplaceAll(s, `"`, `\"`)
}

// writeDry appends one block to file. The bytes go out as built here, with
// "\n" line ends on every platform and the strings' UTF-8 unchanged.
func writeDry(file, domain, msgctxt, msgid, msgidPlural string) {
	var b strings.Builder
	if domain != "" {
		b.WriteString("# domain: " + domain + "\n")
	}
	if msgctxt != "" {
		b.WriteString(`msgctxt "` + gettextEscape(msgctxt) + "\"\n")
	}
	b.WriteString(`msgid "` + gettextEscape(msgid) + "\"\n")
	if msgidPlural != "" {
		b.WriteString(`msgid_plural "` + gettextEscape(msgidPlural) + "\"\n")
	}
	b.WriteString("\n")
	dryMu.Lock()
	defer dryMu.Unlock()
	f, err := os.OpenFile(file, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return
	}
	defer f.Close()
	f.WriteString(b.String())
}
