//go:build ignore

package main

import ls "github.com/Getty/locale-simple/go"

func main() {
	ls.N_("Go N plain")
	ls.Nn_("Go N one", "Go N many")
	ls.Np_("Go_ctx", "Go N ctx plain")
	ls.Nnp_("Go_ctx", "Go N ctx one", "Go N ctx many")
	ls.Nd_("Go_dom", "Go N dom plain")
	ls.Ndn_("Go_dom", "Go N dom one", "Go N dom many")
	ls.Ndp_("Go_dom", "Go_ctx", "Go N dom ctx plain")
	ls.Ndnp_("Go_dom", "Go_ctx", "Go N dom ctx one", "Go N dom ctx many")
	N_("Go N bare plain")
	Nn_("Go N bare one", "Go N bare many")
	Np_("Go_ctx", "Go N bare ctx plain")
	Nnp_("Go_ctx", "Go N bare ctx one", "Go N bare ctx many")
	Nd_("Go_dom", "Go N bare dom plain")
	Ndn_("Go_dom", "Go N bare dom one", "Go N bare dom many")
	Ndp_("Go_dom", "Go_ctx", "Go N bare dom ctx plain")
	Ndnp_("Go_dom", "Go_ctx", "Go N bare dom ctx one", "Go N bare dom ctx many")
}
