//go:build ignore

// Fixture for t/52-scrape-args.t: what follows the strings is code.
package main

import ls "github.com/Getty/locale-simple/go"

func main() {
	ls.L("Go var %s", name)
	y := ls.L("Go assign %s", u.Name)
	ls.Ln("Go count one", "Go count many", n)
	ls.Ln("Go len %d", "Go lens %d", len(items))
	ls.Ln("Go field %d", "Go fields %d", u.Count, items[0])
	ls.L("Go paren %s", ")")
	ls.L("Go comma %s %s", ",", `raw, ( "x"`)
	ls.L("Go escape %s", "tab\t(")
	ls.L("Go nested %s and %s", ls.L("Go Apple"), x)
	ls.Ldnp("Go_dom", "Go_ctx", "Go dnp one", "Go dnp many", int64(len(m)), map[string]int{"a": 1, "b": 2})
	L(
		"Go multi %s %s",
		first,
		strings.Join(names, ", "),
	)
	ls.Ln("Go nested count one", "Go nested count many", len(ls.L("Go in count")))
	ls.L(notConstant, ls.L("Go inside skipped"))
	// Last: no code after it could make up for a bracket read wrongly.
	ls.L("Go rune %c", '(')
}
