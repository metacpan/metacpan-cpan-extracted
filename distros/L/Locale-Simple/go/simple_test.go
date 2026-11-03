package simple

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
	"sync"
	"testing"
)

const localeDir = "../t/data/locale"

// setup resets the process-wide state to the fixture directory, German.
func setup(t *testing.T) {
	t.Helper()
	global = NewTranslator()
	resetCatalogs()
	resetPluralWarning()
	LDir(localeDir)
	Ltd("test")
	LLang("de_DE")
}

func eq(t *testing.T, got, want string) {
	t.Helper()
	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}

// ----------------------------------------------------------------------
// python/test.py
// ----------------------------------------------------------------------

func TestTranslate(t *testing.T) {
	setup(t)
	eq(t, L("Hello"), "Hallo")
	eq(t, Ln("You have %d message", "You have %d messages", 4), "Du hast 4 Nachrichten")
	eq(t, Ln("You have %d message", "You have %d messages", 1), "Du hast 1 Nachricht")
	eq(t, Ln("You have %d message", "You have %d messages", 0), "Du hast 0 Nachrichten")
	eq(t, Ln("You have %d message of %s", "You have %d messages of %s", 1, "harry"), "Du hast 1 Nachricht von harry")
	eq(t, Ln("You have %d message of %s", "You have %d messages of %s", 4, "harry"), "Du hast 4 Nachrichten von harry")
	eq(t, Ln("%2$s brought %1$d message", "%2$s brought %1$d messages", 1, "harry"), "1 Nachricht gebracht von harry")
	eq(t, Ln("%2$s has %1$d message", "%2$s has %1$d messages", 4, "harry"), "harry hat 4 Nachrichten")
	eq(t, L("Change order test %s %s", "one", "two"), "Andere Reihenfolge hier two one")
	eq(t, L("Other change order test %s %s %s", 1, 2, 3), "Verhalten aus http://perldoc.perl.org/functions/sprintf.html 3 1 1")
	eq(t, Lp("alien", "Hello"), "Hallo Ausserirdischer")
	eq(t, L(""), "")
}

func TestContextPlural(t *testing.T) {
	setup(t)
	eq(t, Lnp("some_ctxt", "You have %d message", "You have %d messages", 1), "You have 1 message")
	eq(t, Lnp("some_ctxt", "You have %d message", "You have %d messages", 4), "You have 4 messages")
}

func TestDomainSwitching(t *testing.T) {
	setup(t)
	Ltd("othertest")
	Ltd("test")
	eq(t, Ld("othertest", "Hello"), "Anderes Hallo")
	eq(t, Ldn("othertest", "You have %d message", "You have %d messages", 4), "Du hast 4 AndereNachrichten")
	eq(t, Ldn("othertest", "You have %d message", "You have %d messages", 1), "Du hast 1 AndereNachricht")
	eq(t, Ld("nonexistent", "Hello"), "Hello")
	eq(t, Ldp("othertest", "no_such_ctxt", "Hello"), "Hello")
	eq(t, L("Hello"), "Hallo")
	eq(t, Ldnp("othertest", "", "Hello", "", 0), "Anderes Hallo")
}

func TestDryRun(t *testing.T) {
	setup(t)
	file := filepath.Join(t.TempDir(), "dry.po")
	LDry(file, false)
	eq(t, L("Hello %s", "World"), "Hello World")
	eq(t, Ln("One %d", "Many %d", 1), "One 1")
	eq(t, Ln("One %d", "Many %d", 5), "Many 5")
	eq(t, Ldp("dom", "ctx", "Hello"), "Hello")
	b, _ := os.ReadFile(file)
	content := string(b)
	for _, want := range []string{
		`msgid "Hello %s"`, `msgid "One %d"`, `msgid_plural "Many %d"`,
		"# domain: dom\nmsgctxt \"ctx\"\nmsgid \"Hello\"\n\n",
	} {
		if !strings.Contains(content, want) {
			t.Errorf("dry file lacks %q:\n%s", want, content)
		}
	}
}

// What t/21-dryrun.t and python/test.py expect from the same calls, byte for byte.
const dryShared = "msgid \"Hello\"\n" +
	"\n" +
	"# domain: othertest\n" +
	"msgid \"Hello\"\n" +
	"\n" +
	"msgctxt \"alien\"\n" +
	"msgid \"Hello\"\n" +
	"\n" +
	"msgid \"%2$s has %1$d message\"\n" +
	"msgid_plural \"%2$s has %1$d messages\"\n" +
	"\n" +
	"# domain: othertest\n" +
	"msgctxt \"inbox\"\n" +
	"msgid \"You have %d message\"\n" +
	"msgid_plural \"You have %d messages\"\n" +
	"\n" +
	`msgid "Say \"%s\"\\n\nGrüße"` + "\n" +
	"\n" +
	`msgid "Tab\there\rand CR"` + "\n" +
	"\n"

func TestDryRunSharedFormat(t *testing.T) {
	setup(t)
	file := filepath.Join(t.TempDir(), "shared.po")
	LDry(file, false)
	eq(t, L("Hello"), "Hello")
	eq(t, L(""), "")
	eq(t, Ld("othertest", "Hello"), "Hello")
	eq(t, Lp("alien", "Hello"), "Hello")
	eq(t, Ln("%2$s has %1$d message", "%2$s has %1$d messages", 2, "harry"), "harry has 2 messages")
	eq(t, Ldnp("othertest", "inbox", "You have %d message", "You have %d messages", 1), "You have 1 message")
	eq(t, L("Say \"%s\"\\n\nGrüße", "hi"), "Say \"hi\"\\n\nGrüße")
	eq(t, L("Tab\there\rand CR"), "Tab\there\rand CR")
	b, err := os.ReadFile(file)
	if err != nil {
		t.Fatal(err)
	}
	eq(t, string(b), dryShared)
}

func TestDryRunNowrite(t *testing.T) {
	setup(t)
	file := filepath.Join(t.TempDir(), "dry.po")
	LDry(file, true)
	eq(t, L("Hello"), "Hello")
	if _, err := os.Stat(file); err == nil {
		t.Error("nowrite created the file")
	}
}

func TestErrorWithoutLocaleDir(t *testing.T) {
	global = NewTranslator()
	func() {
		defer func() {
			if r := recover(); r != noDirMessage {
				t.Errorf("recovered %v", r)
			}
		}()
		L("Hello")
	}()
	LNolocales(true)
	eq(t, L("Hello %d", 1), "Hello 1")
	LNolocales(false)
	LDir(localeDir)
	Ltd("test")
	LLang("de_DE")
	LNolocales(true)
	eq(t, L("Hello"), "Hallo") // unlike in JS the flag only lifts the check
}

func TestLanguageSwitchingLifecycle(t *testing.T) {
	setup(t)
	eq(t, L("Hello"), "Hallo")
	LLang("xx_YY")
	eq(t, L("Hello"), "Hello")
	LLang("de_DE")
	eq(t, L("Hello"), "Hallo")
}

func TestDeferredMarkers(t *testing.T) {
	setup(t)
	eq(t, N_("Hello"), "Hello")
	eq(t, Np_("menu", "Open"), "Open")
	eq(t, Nd_("app", "Hi"), "Hi")
	eq(t, Ndp_("app", "menu", "Open"), "Open")
	for _, pair := range [][2]string{
		func() [2]string { a, b := Nn_("1 file", "%d files"); return [2]string{a, b} }(),
		func() [2]string { a, b := Nnp_("ctx", "1 file", "%d files"); return [2]string{a, b} }(),
		func() [2]string { a, b := Ndn_("dom", "1 file", "%d files"); return [2]string{a, b} }(),
		func() [2]string { a, b := Ndnp_("dom", "ctx", "1 file", "%d files"); return [2]string{a, b} }(),
	} {
		if pair != [2]string{"1 file", "%d files"} {
			t.Errorf("plural marker returned %v", pair)
		}
	}
	eq(t, L(N_("Hello")), "Hallo")
	sg, pl := Nn_("You have %d message", "You have %d messages")
	eq(t, Ln(sg, pl, 1), "Du hast 1 Nachricht")
	eq(t, Ln(sg, pl, 4), "Du hast 4 Nachrichten")
}

// ----------------------------------------------------------------------
// sprintf
// ----------------------------------------------------------------------

// sprintfRow is one row of t/data/sprintf.json (mo-reader.md §5). JSON
// numbers arrive as float64.
type sprintfRow struct {
	Format string `json:"format"`
	Args   []any  `json:"args"`
	Want   string `json:"want"`
}

// TestSprintfRows runs the "rows" every runtime shares through L without a
// directory, which returns the msgid formatted. "perl_python_rows" are the
// Perl and Python extras.
func TestSprintfRows(t *testing.T) {
	data, err := os.ReadFile("../t/data/sprintf.json")
	if err != nil {
		t.Fatal(err)
	}
	var vectors struct {
		Rows []sprintfRow `json:"rows"`
	}
	if err := json.Unmarshal(data, &vectors); err != nil {
		t.Fatal(err)
	}
	if len(vectors.Rows) == 0 {
		t.Fatal("no rows in sprintf.json")
	}
	global = NewTranslator()
	LNolocales(true)
	for _, r := range vectors.Rows {
		if got := L(r.Format, r.Args...); got != r.Want {
			t.Errorf("L(%q, %v) = %q, want %q", r.Format, r.Args, got, r.Want)
		}
	}
}

// ----------------------------------------------------------------------
// .mo reader
// ----------------------------------------------------------------------

// buildMo writes a .mo file. plurals maps a msgid to its msgid_plural.
func buildMo(order binary.AppendByteOrder, entries map[string]string, plurals map[string]string) []byte {
	type pair struct{ id, str string }
	var pairs []pair
	for id, str := range entries {
		if p, ok := plurals[id]; ok {
			id += "\x00" + p
		}
		pairs = append(pairs, pair{id, str})
	}
	sort.Slice(pairs, func(i, j int) bool { return pairs[i].id < pairs[j].id })
	n := len(pairs)
	o, tt := 28, 28+8*n
	pos := tt + 8*n
	var otab, ttab, blob []byte
	put := func(b []byte, l, off int) []byte {
		b = order.AppendUint32(b, uint32(l))
		return order.AppendUint32(b, uint32(off))
	}
	for _, p := range pairs {
		otab = put(otab, len(p.id), pos+len(blob))
		blob = append(blob, p.id...)
		blob = append(blob, 0)
		ttab = put(ttab, len(p.str), pos+len(blob))
		blob = append(blob, p.str...)
		blob = append(blob, 0)
	}
	var out []byte
	for _, v := range []int{0x950412de, 0, n, o, tt, 0, 0} {
		out = order.AppendUint32(out, uint32(v))
	}
	return append(append(append(out, otab...), ttab...), blob...)
}

func writeMo(t *testing.T, dir, lang, domain string, data []byte) {
	t.Helper()
	p := filepath.Join(dir, lang, "LC_MESSAGES")
	if err := os.MkdirAll(p, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(p, domain+".mo"), data, 0o644); err != nil {
		t.Fatal(err)
	}
}

const stdHeader = "Plural-Forms: nplurals=2; plural=n != 1;\n"

func TestMoReaderFixture(t *testing.T) {
	data, err := os.ReadFile(localeDir + "/de_DE/LC_MESSAGES/test.mo")
	if err != nil {
		t.Fatal(err)
	}
	c := parseMo(data)
	if c == nil {
		t.Fatal("fixture rejected")
	}
	if got := c.entries["alien\x04Hello"]; !reflect.DeepEqual(got, []string{"Hallo Ausserirdischer"}) {
		t.Errorf("context entry: %q", got)
	}
	if got := c.entries["You have %d message"]; !reflect.DeepEqual(got, []string{"Du hast %d Nachricht", "Du hast %d Nachrichten"}) {
		t.Errorf("plural entry: %q", got)
	}
}

func TestMoReaderBigEndian(t *testing.T) {
	c := parseMo(buildMo(binary.BigEndian, map[string]string{"": stdHeader, "Hello": "Hallo"}, nil))
	if c == nil || c.entries["Hello"][0] != "Hallo" {
		t.Fatalf("big endian file not read: %v", c)
	}
}

func TestMoReaderRejectsBadInput(t *testing.T) {
	good, _ := os.ReadFile(localeDir + "/de_DE/LC_MESSAGES/test.mo")
	revOne := append([]byte{}, good...)
	revOne[6] = 1
	for name, data := range map[string][]byte{
		"empty":     nil,
		"zeros":     make([]byte, 64),
		"truncated": good[:120],
		"revision1": revOne,
	} {
		if parseMo(data) != nil {
			t.Errorf("%s accepted", name)
		}
	}
}

func TestEmptyMsgstrFallsThroughTheChain(t *testing.T) {
	setup(t)
	dir := t.TempDir()
	writeMo(t, dir, "de_AT", "d", buildMo(binary.LittleEndian, map[string]string{"": stdHeader, "Hi": ""}, nil))
	writeMo(t, dir, "de", "d", buildMo(binary.LittleEndian, map[string]string{"": stdHeader, "Hi": "Hallo"}, nil))
	LDir(dir)
	Ltd("d")
	LLang("de_AT")
	eq(t, L("Hi"), "Hallo")
}

// ----------------------------------------------------------------------
// shared vectors
// ----------------------------------------------------------------------

type vectors struct {
	PluralForms []struct {
		Lang   string   `json:"lang"`
		Header string   `json:"header"`
		Cases  [][2]int `json:"cases"`
	} `json:"plural_forms"`
	PluralEdgeCases []struct {
		Name   string   `json:"name"`
		Header *string  `json:"header"`
		Warns  bool     `json:"warns"`
		Cases  [][2]int `json:"cases"`
	} `json:"plural_edge_cases"`
	LocaleFallback []struct {
		Input      string   `json:"input"`
		Candidates []string `json:"candidates"`
	} `json:"locale_fallback"`
	EnvResolution []struct {
		Env       map[string]string `json:"env"`
		Effective string            `json:"effective"`
	} `json:"env_resolution"`
}

func loadVectors(t *testing.T) vectors {
	t.Helper()
	b, err := os.ReadFile("../t/data/plural-forms.json")
	if err != nil {
		t.Fatal(err)
	}
	var v vectors
	if err := json.Unmarshal(b, &v); err != nil {
		t.Fatal(err)
	}
	return v
}

// checkPlural feeds a header through a real .mo file and the lookup path.
func checkPlural(t *testing.T, tag string, header *string, warns bool, cases [][2]int) {
	t.Helper()
	setup(t)
	nplurals := 2
	if header != nil {
		if m := reNplurals.FindStringSubmatch(*header); m != nil {
			fmt.Sscan(m[1], &nplurals)
		}
	}
	forms := make([]string, nplurals)
	for k := range forms {
		forms[k] = fmt.Sprintf("form%d", k)
	}
	entries := map[string]string{"one": strings.Join(forms, "\x00")}
	if header != nil {
		entries[""] = *header + "\n"
	}
	dir := t.TempDir()
	writeMo(t, dir, "xx", "pf", buildMo(binary.LittleEndian, entries, map[string]string{"one": "many"}))
	var warnings []string
	old := warnPlural
	warnPlural = func(m string) { warnings = append(warnings, m) }
	defer func() { warnPlural = old }()

	LDir(dir)
	Ltd("pf")
	LLang("xx")
	for _, c := range cases {
		eq(t, Ln("one", "many", c[0]), fmt.Sprintf("form%d", c[1]))
	}
	want := 0
	if warns {
		want = 1
	}
	if len(warnings) != want {
		t.Errorf("%s: %d warnings, want %d", tag, len(warnings), want)
	}
}

func TestPluralVectors(t *testing.T) {
	v := loadVectors(t)
	for _, r := range v.PluralForms {
		h := r.Header
		t.Run("forms/"+r.Lang, func(t *testing.T) { checkPlural(t, r.Lang, &h, false, r.Cases) })
	}
	for _, r := range v.PluralEdgeCases {
		t.Run("edge/"+r.Name, func(t *testing.T) { checkPlural(t, r.Name, r.Header, r.Warns, r.Cases) })
	}
}

func TestPluralWarningOncePerProcess(t *testing.T) {
	setup(t)
	var warnings []string
	old := warnPlural
	warnPlural = func(m string) { warnings = append(warnings, m) }
	defer func() { warnPlural = old }()
	dir := t.TempDir()
	writeMo(t, dir, "aa", "w", buildMo(binary.LittleEndian, map[string]string{"x": "y"}, nil))
	writeMo(t, dir, "bb", "w", buildMo(binary.LittleEndian, map[string]string{"": "Plural-Forms: nplurals=2; plural=n ** 2;\n", "x": "z"}, nil))
	LDir(dir)
	Ltd("w")
	for _, lang := range []string{"aa", "bb", "aa", "nothing"} {
		LLang(lang)
		L("x")
		Ln("x", "xs", 3)
	}
	if len(warnings) != 1 {
		t.Errorf("%d warnings, want 1", len(warnings))
	}
}

func TestLocaleFallback(t *testing.T) {
	for _, r := range loadVectors(t).LocaleFallback {
		if got := candidates(r.Input); !reflect.DeepEqual(got, r.Candidates) {
			t.Errorf("candidates(%q) = %q, want %q", r.Input, got, r.Candidates)
		}
	}
}

func TestEnvResolution(t *testing.T) {
	for _, r := range loadVectors(t).EnvResolution {
		env := r.Env
		got := effectiveLang(func(k string) string { return env[k] }, "")
		if got != r.Effective {
			t.Errorf("env %v: %q, want %q", r.Env, got, r.Effective)
		}
	}
}

func TestLLangWinsOverEnvironment(t *testing.T) {
	if got := effectiveLang(nil, "fr"); got != "fr" {
		t.Errorf("got %q", got)
	}
}

// ----------------------------------------------------------------------
// Translator
// ----------------------------------------------------------------------

func TestTranslatorIndependentOfGlobalState(t *testing.T) {
	setup(t)
	tr := NewTranslator()
	tr.LDir(localeDir)
	tr.Ltd("test")
	tr.LLang("xx_YY")
	eq(t, tr.L("Hello"), "Hello")
	eq(t, L("Hello"), "Hallo")
	tr.LLang("de_DE")
	eq(t, tr.Ln("You have %d message", "You have %d messages", 4), "Du hast 4 Nachrichten")
}

func TestTranslatorSharesCatalogCache(t *testing.T) {
	setup(t)
	tr := NewTranslator()
	tr.LDir(localeDir)
	tr.Ltd("test")
	tr.LLang("de_DE")
	L("Hello")
	tr.L("Hello")
	catalogMu.Lock()
	defer catalogMu.Unlock()
	if len(catalogs) != 1 { // one file, read once for both
		t.Errorf("%d cache entries, want 1", len(catalogs))
	}
}

func TestTranslatorRequiresDir(t *testing.T) {
	defer func() {
		if recover() != noDirMessage {
			t.Error("no panic without a directory")
		}
	}()
	NewTranslator().L("Hello")
}

// Run with -race: per-request translators next to the shared catalog cache and
// the process-wide state.
func TestConcurrentUse(t *testing.T) {
	setup(t)
	var wg sync.WaitGroup
	for i := 0; i < 16; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			tr := NewTranslator()
			tr.LDir(localeDir)
			tr.Ltd("test")
			tr.LLang("de_DE")
			for j := 0; j < 50; j++ {
				if tr.L("Hello") != "Hallo" {
					t.Error("translator result")
				}
				if i%4 == 0 {
					LLang("de_DE")
				}
				_ = L("Hello")
			}
		}(i)
	}
	wg.Wait()
}
