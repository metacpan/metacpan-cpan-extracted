package simple

import (
	"log"
	"regexp"
	"strconv"
	"strings"
	"sync"
)

// pluralRule selects the translation form for a count.
type pluralRule struct {
	nplurals int
	eval     func(n int64) int64
}

func (r pluralRule) index(n int) int {
	v := int64(n)
	if v < 0 {
		v = -v // MinInt64 stays negative, which the range check below maps to 0
	}
	i := r.eval(v)
	if i < 0 || i >= int64(r.nplurals) {
		return 0
	}
	return int(i)
}

const (
	maxPluralDepth  = 100
	maxPluralLength = 1000
)

var (
	pluralWarnMu sync.Mutex
	pluralWarned bool
	// warnPlural reports the fallback to the standard logger; tests replace it.
	warnPlural = func(msg string) { log.Println(msg) }
)

func resetPluralWarning() {
	pluralWarnMu.Lock()
	pluralWarned = false
	pluralWarnMu.Unlock()
}

func warnPluralOnce() {
	pluralWarnMu.Lock()
	defer pluralWarnMu.Unlock()
	if pluralWarned {
		return
	}
	pluralWarned = true
	warnPlural(`locale-simple: missing or unusable Plural-Forms header, falling back to "n != 1"`)
}

func defaultRule() pluralRule {
	return pluralRule{nplurals: 2, eval: func(n int64) int64 {
		if n != 1 {
			return 1
		}
		return 0
	}}
}

// ruleFromHeader finds the Plural-Forms line in the header entry (nil: no
// header) and compiles it; anything unusable selects "n != 1" and warns once.
func ruleFromHeader(header *string) pluralRule {
	if header != nil {
		for _, line := range strings.Split(*header, "\n") {
			line = strings.TrimSuffix(line, "\r")
			if strings.HasPrefix(line, "Plural-Forms:") {
				if r, ok := parsePluralForms(line); ok {
					return r
				}
				break
			}
		}
	}
	warnPluralOnce()
	return defaultRule()
}

var (
	reNplurals = regexp.MustCompile(`\bnplurals\s*=\s*(\d+)`)
	rePlural   = regexp.MustCompile(`\bplural\s*=\s*([^;\n]*)`)
)

func parsePluralForms(line string) (pluralRule, bool) {
	np := reNplurals.FindStringSubmatch(line)
	ex := rePlural.FindStringSubmatch(line)
	if np == nil || ex == nil {
		return pluralRule{}, false
	}
	nplurals, err := strconv.Atoi(np[1])
	if err != nil || nplurals < 1 {
		return pluralRule{}, false
	}
	fn, ok := compilePlural(ex[1])
	if !ok {
		return pluralRule{}, false
	}
	return pluralRule{nplurals: nplurals, eval: fn}, true
}

type planError struct{}

type pluralParser struct {
	toks  []string
	pos   int
	depth int
}

var pluralLevels = [][]string{{"||"}, {"&&"}, {"==", "!="}, {"<", ">", "<=", ">="}, {"+", "-"}, {"*", "/", "%"}}

func b2i(b bool) int64 {
	if b {
		return 1
	}
	return 0
}

var pluralOps = map[string]func(x, y int64) int64{
	"||": func(x, y int64) int64 { return b2i(x != 0 || y != 0) },
	"&&": func(x, y int64) int64 { return b2i(x != 0 && y != 0) },
	"==": func(x, y int64) int64 { return b2i(x == y) },
	"!=": func(x, y int64) int64 { return b2i(x != y) },
	"<":  func(x, y int64) int64 { return b2i(x < y) },
	">":  func(x, y int64) int64 { return b2i(x > y) },
	"<=": func(x, y int64) int64 { return b2i(x <= y) },
	">=": func(x, y int64) int64 { return b2i(x >= y) },
	"+":  func(x, y int64) int64 { return x + y },
	"-":  func(x, y int64) int64 { return x - y },
	"*":  func(x, y int64) int64 { return x * y },
	"/": func(x, y int64) int64 {
		if y == 0 {
			return 0
		}
		return x / y
	},
	"%": func(x, y int64) int64 {
		if y == 0 {
			return 0
		}
		return x % y
	},
}

// compilePlural tokenizes and parses the expression into a closure tree. The
// expression is data from a file and is never executed any other way.
func compilePlural(src string) (fn func(int64) int64, ok bool) {
	if len(src) > maxPluralLength {
		return nil, false
	}
	var toks []string
	for i := 0; i < len(src); {
		c := src[i]
		switch {
		case c == ' ' || c == '\t' || c == '\r' || c == '\n':
			i++
		case c >= '0' && c <= '9':
			j := i
			for j < len(src) && src[j] >= '0' && src[j] <= '9' {
				j++
			}
			toks = append(toks, src[i:j])
			i = j
		case c == 'n' || strings.IndexByte("+-*/%()?:", c) >= 0:
			toks = append(toks, string(c))
			i++
		default:
			two := ""
			if i+1 < len(src) {
				two = src[i : i+2]
			}
			switch two {
			case "||", "&&", "==", "!=", "<=", ">=":
				toks = append(toks, two)
				i += 2
			default:
				if c == '<' || c == '>' || c == '!' {
					toks = append(toks, string(c))
					i++
				} else {
					return nil, false
				}
			}
		}
	}
	p := &pluralParser{toks: toks}
	defer func() {
		if r := recover(); r != nil {
			if _, is := r.(planError); !is {
				panic(r)
			}
			fn, ok = nil, false
		}
	}()
	fn = p.expr()
	if p.pos != len(p.toks) {
		return nil, false
	}
	return fn, true
}

func (p *pluralParser) peek() string {
	if p.pos < len(p.toks) {
		return p.toks[p.pos]
	}
	return ""
}

func (p *pluralParser) nested(f func() func(int64) int64) func(int64) int64 {
	p.depth++
	if p.depth > maxPluralDepth {
		panic(planError{})
	}
	r := f()
	p.depth--
	return r
}

func (p *pluralParser) expect(t string) {
	if p.peek() != t {
		panic(planError{})
	}
	p.pos++
}

func (p *pluralParser) expr() func(int64) int64 {
	cond := p.binary(0)
	if p.peek() != "?" {
		return cond
	}
	p.pos++
	a := p.nested(p.expr)
	p.expect(":")
	b := p.nested(p.expr)
	return func(n int64) int64 {
		if cond(n) != 0 {
			return a(n)
		}
		return b(n)
	}
}

func (p *pluralParser) binary(level int) func(int64) int64 {
	if level == len(pluralLevels) {
		return p.unary()
	}
	left := p.binary(level + 1)
	for {
		tok := p.peek()
		found := false
		for _, o := range pluralLevels[level] {
			if o == tok {
				found = true
			}
		}
		if !found {
			return left
		}
		p.pos++
		op := pluralOps[tok]
		l, r := left, p.binary(level+1)
		left = func(n int64) int64 { return op(l(n), r(n)) }
	}
}

func (p *pluralParser) unary() func(int64) int64 {
	if p.peek() == "!" {
		p.pos++
		inner := p.nested(p.unary)
		return func(n int64) int64 { return b2i(inner(n) == 0) }
	}
	return p.primary()
}

func (p *pluralParser) primary() func(int64) int64 {
	t := p.peek()
	p.pos++
	switch {
	case t == "n":
		return func(n int64) int64 { return n }
	case t == "(":
		inner := p.nested(p.expr)
		p.expect(")")
		return inner
	case t != "" && t[0] >= '0' && t[0] <= '9':
		v, err := strconv.ParseInt(t, 10, 64)
		if err != nil {
			v = 1<<63 - 1
		}
		return func(int64) int64 { return v }
	}
	panic(planError{})
}
