#!/usr/bin/perl

use 5.006;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use Devel::Eval 'dval';

dval <<'END_PERL';

package Foo;

sub my_function {
	return "Hello World!";
}

1;
END_PERL

is( Foo::my_function(), "Hello World!", 'Function is generated' );
