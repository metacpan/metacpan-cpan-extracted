//go:build ignore

package main

import ls "github.com/Getty/locale-simple/go"

func main() {
	ls.L("Go N plain")
	ls.Ln("Go N one", "Go N many", 4)
	ls.Lp("Go_ctx", "Go N ctx plain")
	ls.Lnp("Go_ctx", "Go N ctx one", "Go N ctx many", 4)
	ls.Ld("Go_dom", "Go N dom plain")
	ls.Ldn("Go_dom", "Go N dom one", "Go N dom many", 4)
	ls.Ldp("Go_dom", "Go_ctx", "Go N dom ctx plain")
	ls.Ldnp("Go_dom", "Go_ctx", "Go N dom ctx one", "Go N dom ctx many", 4)
	L("Go N bare plain")
	Ln("Go N bare one", "Go N bare many", 4)
	Lp("Go_ctx", "Go N bare ctx plain")
	Lnp("Go_ctx", "Go N bare ctx one", "Go N bare ctx many", 4)
	Ld("Go_dom", "Go N bare dom plain")
	Ldn("Go_dom", "Go N bare dom one", "Go N bare dom many", 4)
	Ldp("Go_dom", "Go_ctx", "Go N bare dom ctx plain")
	Ldnp("Go_dom", "Go_ctx", "Go N bare dom ctx one", "Go N bare dom ctx many", 4)
}
