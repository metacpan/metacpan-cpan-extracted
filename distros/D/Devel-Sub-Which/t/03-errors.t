#!/usr/bin/perl

use Test::More;

BEGIN {
	eval { use Test::Exception };
	if ($@){
		skip_all("This test needs Test::Exception");
	} else {
		plan(tests => 3);
	}
}

use ok "Devel::Sub::Which";

dies_ok {
	Devel::Sub::Which::ref_to_name("not a ref");
} "B dies when ref_to_name doesn't get a ref";


{
	package foo;
	sub new { bless {}, shift }
	sub can { return 1 }
	sub method { }
}

throws_ok {
	Devel::Sub::Which::which(foo->new, "method");
} qr/did not return/, "broken can causes error";
