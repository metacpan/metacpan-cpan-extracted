#!perl  -T

BEGIN { require './t/test.pl' }

use Test::More tests => 61;
use Scalar::Util 'refaddr';
use strict;
use utf8;


#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN { use_ok 'JE::Boolean' }; # Make sure it loads without JE
                                # already loaded.
BEGIN { use_ok 'JE' };


#--------------------------------------------------------------------#
# Tests 3-6: Object creation

our $j = JE->new,;
isa_ok $j, 'JE', 'global object';
our $f = JE::Boolean->new($j,0);
isa_ok $f, 'JE::Boolean', 'true boolean';
our $t = JE::Boolean->new($j,1);
isa_ok $t, 'JE::Boolean', 'false boolean';
our $n = JE::Boolean->new($j);
isa_ok $n, 'JE::Boolean', 'default boolean';


#--------------------------------------------------------------------#
# Tests 7-9: prop

{
	my $a = $t->prop(thing => [1,2,3]);
	is_deeply $a, [1,2,3], 'prop returns the assigned value';
	isa_ok my $func = $t->prop('toString'), 'JE::Object::Function';
	ok refaddr $func ==
		refaddr $j->eval('Boolean.prototype.toString')->get,
		'->prop returns the right value';
}


#--------------------------------------------------------------------#
# Tests 10-11: keys

is_deeply [$t->keys], [], '->keys returns empty list';
$j->eval('Boolean.prototype.something')->set(undef);
is_deeply [$t->keys], ['something'], '->keys returns ("something")';


#--------------------------------------------------------------------#
# Test 12: delete

is_deeply $t->delete('anything'), 1, 'delete returns true';

#--------------------------------------------------------------------#
# Tests 13-18: method

{
	isa_ok my $ret = $t->method('toString'), 'JE::String';
	ok $ret eq 'true', '$t->method("toString") returns "true"';
	isa_ok $ret = $f->method('toString'), 'JE::String';
	ok $ret eq 'false', '$f->method("toString") returns "false"';
	isa_ok $ret = $n->method('toString'), 'JE::String';
	ok $ret eq 'false', '$n->method("toString") returns "false"';
}


#--------------------------------------------------------------------#
# Tests 19-21: value

is_deeply $t->value,  1, '$t->value';
is_deeply $f->value, !1, '$f->value';
is_deeply $n->value, !1, '$n->value';


#--------------------------------------------------------------------#
# Test 22: call

eval {
	$t->call
};
like $@, qr/^Can't locate object method/, '$t->call dies';


#--------------------------------------------------------------------#
# Test 23: apply

eval {
	$t->apply
};
like $@, qr/^Can't locate object method/, '$t->call dies';


#--------------------------------------------------------------------#
# Test 24: construct

eval {
	$t->construct
};
like $@, qr/^Can't locate object method/, '$t->construct dies';


#--------------------------------------------------------------------#
# Test 25: exists

is_deeply $t->exists('anything'), !1, 'exists returns false';


#--------------------------------------------------------------------#
# Test 26: typeof

is_deeply typeof $t, 'boolean', 'typeof returns "boolean"';


#--------------------------------------------------------------------#
# Test 27: class

is_deeply $t->class, 'Boolean', 'class returns "Boolean"';


#--------------------------------------------------------------------#
# Tests 28-30: id

# The exact return values are not documented, neither are these tests
# normative.
is_deeply $t->id, 'bool:1', '$t->id';
is_deeply $f->id, 'bool:',  '$f->id';
is_deeply $n->id, 'bool:',  '$n->id';


#--------------------------------------------------------------------#
# Test 31: primitive like an ape

is_deeply $t->primitive, 1, 'primitive returns 1';


#--------------------------------------------------------------------#
# Test 32: to_primitive

cmp_ok refaddr $t->to_primitive, '==', refaddr $t, 'to_primitive';


#--------------------------------------------------------------------#
# Test 33: to_boolean

cmp_ok refaddr $t->to_boolean, '==', refaddr $t, 'to_boolean';


#--------------------------------------------------------------------#
# Tests 34-9: to_string

{
	isa_ok my $thing = $t->to_string, 'JE::String';
	is $thing, 'true',  '$t->to_string is "true"';
	isa_ok    $thing = $f->to_string, 'JE::String';
	is $thing, 'false', '$f->to_string is "false"';
	isa_ok    $thing = $n->to_string, 'JE::String';
	is $thing, 'false', '$n->to_string is "false"';
}


#--------------------------------------------------------------------#
# Tests 40-5: to_number

{
	isa_ok my $thing = $t->to_number, 'JE::Number';
	cmp_ok $thing, '==', 1, '$t->to_number == 1';
	isa_ok    $thing = $f->to_number, 'JE::Number';
	cmp_ok $thing, '==', 0, '$f->to_number == 0';
	isa_ok    $thing = $n->to_number, 'JE::Number';
	cmp_ok $thing, '==', 0, '$n->to_number == 0';
}


#--------------------------------------------------------------------#
# Tests 46-51: to_object

{
	isa_ok my $thing = $t->to_object, 'JE::Object::Boolean';
	is $thing->value,  1, '$t->to_object->value is 1';
	isa_ok    $thing = $f->to_object, 'JE::Object::Boolean';
	is $thing->value, !1, '$f->to_object->value is !1';
	isa_ok    $thing = $n->to_object, 'JE::Object::Boolean';
	is $thing->value, !1, '$n->to_object->value is !1';
}


#--------------------------------------------------------------------#
# Test 52: global

is refaddr $j, refaddr global $t, '->global';


#--------------------------------------------------------------------#
# Tests 53-61: Overloading

is "$t", 'true',  '"$t"';
is "$f", 'false', '"$f"';
is "$n", 'false', '"$n"';
is !$t,  '',      '!$t';
is !$f,  '1',     '!$f';
is !$n,  '1',     '!$n';
is 0+$t, '1',     '0+$t';
is 0+$f, '0',     '0+$f';
is 0+$n, '0',     '0+$n';


