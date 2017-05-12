#!/usr/bin/perl 

use strict;
use warnings;

use Test::More tests => 8;

use ok "Devel::Sub::Which";

{
	package foo;
	use Devel::Sub::Which qw/which ref_to_name/;
}

ok(foo->can("which"), "which exported");
ok(foo->can("ref_to_name"), "ref_to_name exported");

is(foo::ref_to_name(foo->can("which")), "Devel::Sub::Which::which", "and exported which is the real one");

{
	package bar;
	Devel::Sub::Which->import(qw/:universal/);
}

{
	package anyone;
}

ok(anyone->can("which"), "anyone->can('which')");
ok(UNIVERSAL->can("which"), "UNIVERSAL->can('which')");

{
	package gorch;

	sub new { bless {}, shift }
	sub method {}
}

my $gorch = gorch->new();

is($gorch->which("method"), "gorch::method", '$gorch->which("method")');
is($gorch->which("which"), "Devel::Sub::Which::which", '$gorch->which("which")');

