//go:build ignore

package main

import . "github.com/Getty/locale-simple/go"

// Go: escapes in double quotes only; \x and octal are bytes.
func main() {
	L("GO newline\n")
	L("GO tab\t quote \" backslash \\")
	L("GO bytes \xc3\xa4 octal \303\244 unicode ä \U0001F600")
	L(`GO raw \n stays`)
	L("GO joined\n" + `GO raw\t` + "\tGO end")
	Ln("GO one\n", "GO many\n", n)
	L("0")
	Lp("0", "GO context zero")
	L("GO bad \q is not read")
}
