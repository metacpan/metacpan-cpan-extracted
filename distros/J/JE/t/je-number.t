#!perl  -T

BEGIN { require './t/test.pl' }

use Test::More tests => 96;
use Scalar::Util 'refaddr';
use strict;
use utf8;


#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN { use_ok 'JE::Number' }; # Make sure it loads without JE
                                # already loaded.
BEGIN { use_ok 'JE' };


#--------------------------------------------------------------------#
# Tests 3-18: Object creation and the 'value' method

our $j = JE->new,;
isa_ok $j, 'JE', 'global object';

{
	no warnings 'once';
	local *__::to_number = sub { bless [763], '___' };
	local @___::ISA = 'JE::Number';
	my $n = JE::Number->new($j,bless [], '__');
	isa_ok $n, 'JE::Number';
	cmp_ok $n->value, '==', 763;
}

our $inf = JE::Number->new($j,'informative');	
isa_ok $inf, 'JE::Number', 'informative';
cmp_ok $inf->value, '==', 9**9**9, 'informative == inf';

our $nan = JE::Number->new($j,'nanometre');	
isa_ok $nan, 'JE::Number', 'nanometre';
cmp_ok $nan->value, '!=', $nan->value, 'nanometre != nanometre';

our $int = JE::Number->new($j,17);	
isa_ok $int, 'JE::Number', '17';
cmp_ok $int->value, '==', 17, 'value == 17';

our $sci = JE::Number->new($j,17.5e-9);
isa_ok $sci, 'JE::Number', '17.5e-9';
cmp_ok $sci->value, '==', 17.5e-9, 'value == 17.5e-9';

our $n = JE::Number->new($j,17.6);
isa_ok $n, 'JE::Number', '17.6';
cmp_ok $n->value, '==', 17.6, 'value == 17.6';

our $z = JE::Number->new($j,0);
isa_ok $z, 'JE::Number', '0';
cmp_ok $z->value, '==', 0, 'value == 0';

eval {
	local $SIG{__WARN__} = sub{}; # silence JE::Number’s warnings
	no warnings 'utf8'; # compile-time surrogate warnings
	new JE::Number $j, "\x{d800}";
};
is $@, '', 'new JE::Number with surrogate';


#--------------------------------------------------------------------#
# Tests 19-21: prop

{
	my $a = $n->prop(thing => [1,2,3]);
	is_deeply $a, [1,2,3], 'prop returns the assigned value';
	isa_ok my $func = $n->prop('toString'), 'JE::Object::Function';
	ok refaddr $func ==
		refaddr $j->eval('Number.prototype.toString')->get,
		'->prop returns the right value';
}


#--------------------------------------------------------------------#
# Tests 22-3: keys

is_deeply [$n->keys], [], '->keys returns empty list';
$j->eval('Number.prototype.something')->set(undef);
is_deeply [$n->keys], ['something'], '->keys returns ("something")';


#--------------------------------------------------------------------#
# Test 24: delete

is_deeply $n->delete('anything'), 1, 'delete returns true';

#--------------------------------------------------------------------#
# Tests 25-6: method

{
	isa_ok my $ret = $n->method('toString'), 'JE::String';
	ok $ret eq '17.6', '$n->method("toString") returns "17.6"';
}


#--------------------------------------------------------------------#
# Test 27: call

eval {
	$n->call
};
like $@, qr/^Can't locate object method/, '$n->call dies';


#--------------------------------------------------------------------#
# Test 28: apply

eval {
	$n->apply
};
like $@, qr/^Can't locate object method/, 'apply dies';


#--------------------------------------------------------------------#
# Test 29: construct

eval {
	$n->construct
};
like $@, qr/^Can't locate object method/, 'construct dies';


#--------------------------------------------------------------------#
# Test 30: exists

is_deeply $n->exists('anything'), !1, 'exists returns false';


#--------------------------------------------------------------------#
# Test 31: typeof

is_deeply typeof $n, 'number', 'typeof returns "number"';


#--------------------------------------------------------------------#
# Test 32: class

is_deeply $n->class, 'Number', 'class returns "Number"';


#--------------------------------------------------------------------#
# Tests 33-8: id

# The exact return values are not documented, neither are these tests
# normative.
is_deeply $inf->id, 'num:inf', '$inf->id';
is_deeply $nan->id, 'num:nan', '$nan->id';
is_deeply $int->id, 'num:17',  '$int->id';
ok !ref $sci->id && $sci->id =~ /^num:(.*)/ && $1 eq 17.5e-9, '$sci->id';
	# Hafta use 'eq' here rather than '=='. printf "%.30f" will demon-
	# strate why.
is_deeply $n->id, 'num:17.6',  '$n->id';
is_deeply $z->id, 'num:0',  '$z->id';


#--------------------------------------------------------------------#
# Test 39: primitive like an ape

is_deeply $n->primitive, 1, 'primitive returns 1';


#--------------------------------------------------------------------#
# Test 40: to_primitive

cmp_ok refaddr $n->to_primitive, '==', refaddr $n, 'to_primitive';


#--------------------------------------------------------------------#
# Tests 41-52: to_boolean

{
	isa_ok my $thing = $inf->to_boolean, 'JE::Boolean';
	is $thing, 'true',  '$inf->to_boolean is true';
	isa_ok    $thing = $nan->to_boolean, 'JE::Boolean';
	is $thing, 'false', '$nan->to_boolean is false';
	isa_ok    $thing = $int->to_boolean, 'JE::Boolean';
	is $thing, 'true', '$int->to_boolean is true';
	isa_ok    $thing = $sci->to_boolean, 'JE::Boolean';
	is $thing, 'true', '$sci->to_boolean is true';
	isa_ok    $thing = $n->to_boolean, 'JE::Boolean';
	is $thing, 'true', '$n->to_boolean is true';
	isa_ok    $thing = $z->to_boolean, 'JE::Boolean';
	is $thing, 'false', '$z->to_boolean is false';
}


#--------------------------------------------------------------------#
# Tests 53-64: to_string

{
	isa_ok my $thing = $inf->to_string, 'JE::String';
	is $thing, 'Infinity',  '$inf->to_string is "Infinity"';
	isa_ok    $thing = $nan->to_string, 'JE::String';
	is $thing, 'NaN', '$nan->to_string is "NaN"';
	isa_ok    $thing = $int->to_string, 'JE::String';
	is $thing, '17', '$int->to_string is "17"';
	isa_ok    $thing = $sci->to_string, 'JE::String';
	is $thing, 17.5e-9, '$sci->to_string is 1.75e-8';
	isa_ok    $thing = $n->to_string, 'JE::String';
	is $thing, '17.6', '$n->to_string is 17.6';
	isa_ok    $thing = $z->to_string, 'JE::String';
	is $thing, '0', '$z->to_string is 0';
}


#--------------------------------------------------------------------#
# Test 65: to_number

cmp_ok refaddr $n-> to_number, '==', refaddr $n, 'to_number';


#--------------------------------------------------------------------#
# Tests 66-77: to_object

{
	isa_ok my $thing = $inf->to_object, 'JE::Object::Number';
	cmp_ok $thing->value, '==', 9**9**9,
		'$inf->to_object->value is inf';
	isa_ok    $thing = $nan->to_object, 'JE::Object::Number';
	cmp_ok $thing->value, '!=', $thing->value,
		'$nan->to_object->value is nan';
	isa_ok    $thing = $int->to_object, 'JE::Object::Number';
	is $thing->value, '17', '$int->to_object->value is 17';
	isa_ok    $thing = $sci->to_object, 'JE::Object::Number';
	is $thing->value, 17.5e-9, '$sci->to_object->value is 1.75e-8';
	isa_ok    $thing = $n->to_object, 'JE::Object::Number';
	is $thing->value, '17.6', '$n->to_object->value is 17.6';
	isa_ok    $thing = $z->to_object, 'JE::Object::Number';
	is $thing->value, '0', '$z->to_object->value is 0';
}


#--------------------------------------------------------------------#
# Test 78: global

is refaddr $j, refaddr global $n, '->global';


#--------------------------------------------------------------------#
# Tests 79-96: Overloading

is "$inf", 'Infinity', '"$inf"';
is "$nan", 'NaN',      '"$nan"';
is "$int", '17',       '"$int"';
TODO : {
	local $TODO = 'number stringification not yet acc. to spec.';
	is "$sci", '1.75e-8',  '"$sci"';
}
is "$n",   '17.6',     '"$n"';
is "$z",   '0',        '"$z"';
is !$inf,  '',         '!$inf';
is !$nan,  '1',        '!$nan';
is !$int,  '',         '!$int';
is !$sci,  '',         '!$sci';
is !$n,    '',         '!$n';
is !$z,    '1',        '!$z';
cmp_ok 0+$inf, '==', 9**9**9, '0+$inf';
cmp_ok 0+$nan, '!=', 0+$nan,  '0+$nan';
cmp_ok 0+$int, '==', 17,      '0+$int';
cmp_ok 0+$sci, 'eq', 1.75e-8, '0+$sci'; # printf "%.30f" will show why I
                                        # use eq
cmp_ok 0+$n,   '==', 17.6,    '0+$n';
cmp_ok 0+$z,   '==', 0,       '0+$z';


