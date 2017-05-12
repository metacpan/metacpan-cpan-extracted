#!perl  -T

use Test::More tests => 10;
use strict;



#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN {
	use_ok 'JE::Object::Function'; # see if it loads without je loaded
	use_ok 'JE';
}


#--------------------------------------------------------------------#
# Tests 3-4: object creation

my $j = new JE;
isa_ok $j, 'JE';
my $func = new JE::Object::Function $j, sub { 34 };
isa_ok $func, 'JE::Object::Function';


#--------------------------------------------------------------------#
# Tests 5-6: Overloading

is &$func, 34, '&{} overloading';
is &{$j->eval('0,function(){}')}, undef,
 '&{} overloading changes a returned JE::Undefined into undef';

#--------------------------------------------------------------------#
# Test 7: no_proto makes construct die

{
	my $func = new JE::Object::Function {
		scope => $j,
		function => sub { 34 },
		no_proto => 1,
	};
	ok !eval { $func->construct;1 }, 'construct dies with no_proto';
}

#--------------------------------------------------------------------#
# Test 8: The really weird ‘warn’ bug

ok eval{local $SIG{__WARN__}=sub{};
        $j->upgrade(sub{warn})->();1}, 'the really weird warn bug';

#--------------------------------------------------------------------#
# Tests 9-10: call_with

is $j->eval('0,function(a){return this + " " + a}')->call_with(
    "quext","qued"
   ), 'quext qued', 'call_with';
is $j->eval('0,function(){}')->call_with({}), undef,
 'call_with turns an undefined retval into undef';


diag 'TO DO: Finish writing this script.';

