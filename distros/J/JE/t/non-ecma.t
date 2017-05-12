#!perl  -T

# Tests for non-ECMA JavaScript features

BEGIN { require './t/test.pl' }

use Test::More tests => 2;
use strict;
use utf8;

use JE;
our $j = JE->new;

#--------------------------------------------------------------------#
# Tests 1-2: arguments as a property of the function itself

$j->eval("
	var x = 0,s='';
	function f() { if(++x<3)f(); s+=+(arguments==f.arguments)}
	f();
");
is $j->{s}, 111, 'arguments as a property of a function';

$j->eval('
	function g() { f() }
	function f(){ s = g.arguments[0] }
	g("G");
	s += g.arguments
');
is $j->{s}, "Gnull", 'func.arguments is accessible from other functions';
