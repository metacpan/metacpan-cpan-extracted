#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use ok "Devel::Sub::Which";

{
	package foo;
	sub new { bless {}, shift }
	sub method { }
	sub other { }
}

my $foo = foo->new();

is($foo->Devel::Sub::Which::which("method"), "foo::method", '$foo->which("method")');

is(Devel::Sub::Which::ref_to_name(\&foo::new), "foo::new", "ref_to_name(cref)");
is(Devel::Sub::Which::which(\&foo::other), "foo::other", "which(cref)");


