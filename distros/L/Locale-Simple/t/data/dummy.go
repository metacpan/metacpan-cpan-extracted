//go:build ignore

package main

import ls "github.com/Getty/locale-simple/go"

func main() {
	for _, c := range "x" {
		if c == 'a' {
			ls.L("Go after rune literal")
		}
	}
	q := '\''
	ls.Ld("go_dom", `Go raw "string" with \ backslash`)
	ls.L("Go " + "concat")
	other.Foo('b', "not a call")
	_ = q
}
