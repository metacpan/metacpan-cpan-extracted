#!perl  -T

BEGIN { require './t/test.pl' }

use strict; use warnings; no warnings 'utf8';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use Scalar::Util 'refaddr';
use utf8;

#--------------------------------------------------------------------#
use tests 2; # See if the modules load

use_ok 'JE::Object::Number'; # Make sure it loads without JE
                                # already loaded.
use_ok 'JE' ;


#--------------------------------------------------------------------#
use tests 5; # Object creation

our $j = JE->new,;
isa_ok $j, 'JE', 'global object';

our $a1 = new JE::Object::Number $j , '6.7';
our $nan = new JE::Object::Number $j, 'nanometre';
our $inf = new JE::Object::Number $j, 'information';
isa_ok $a1, 'JE::Object::Number', '6.7';
isa_ok $nan, 'JE::Object::Number', 'inf';
isa_ok $inf, 'JE::Object::Number', 'nan';

eval {
	local $SIG{__WARN__} = sub{};
	new JE::Object::Number $j, "\x{d800}";
};
is $@, '', 'new JE::Object::Number with surrogate';


#--------------------------------------------------------------------#
use tests 3; # string overloading

is "$a1", '6.7', 'string overloading';
is "$nan", 'NaN',        'string overloading (nan)';;
is "$inf", 'Infinity',       'string overloading (inf)';

#--------------------------------------------------------------------#
use tests 2; # prop

{
	is $a1->prop(thing => JE::String->new($j,'value')), 'value',
		'prop returns the assigned value';
	is $a1->prop('thing'), 'value', 'the assignment worked';
}


#--------------------------------------------------------------------#
use tests 1; # keys

is_deeply [$a1->keys], ['thing'], 'keys';


#--------------------------------------------------------------------#
use tests 3; # delete

is_deeply $a1->delete('anything'), 1, 'delete nonexistent property';
is_deeply $a1->delete('thing'), 1, 'delete property';
is_deeply $a1->prop('thing'), undef, 'was the property deleted?';


#--------------------------------------------------------------------#
use tests 2; # method

{
	isa_ok my $ret = $a1->method('toString'), 'JE::String',
		'result of method("toString")';
	ok $ret eq '6.7',
		'$a1->method("toString") returns "an,array,"';
}


#--------------------------------------------------------------------#
use tests 2; # value

{
	my $value;

	is ref($value = $a1->value), '',
		'$a1->value returns a plain scalar';
	is $value, 6.7, '$a1->value';
}

#--------------------------------------------------------------------#
use tests 1; # call

eval {
	$a1->call
};
like $@, qr/^Can't locate object method/, 'call dies';


#--------------------------------------------------------------------#
use tests 1; # app/y

eval {
	$a1->apply
};
like $@, qr/^Can't locate object method/, 'apply dies';


#--------------------------------------------------------------------#
use tests 1; # construct

eval {
	$a1->construct
};
like $@, qr/^Can't locate object method/, 'construct dies';


#--------------------------------------------------------------------#
use tests 3; # exists

$a1->prop(thing => undef);

is_deeply $a1->exists('anything'), !1, 'exists(nonexistent property)';
is_deeply $a1->exists(2), !1, 'exists(nonexistent elem)';
is_deeply $a1->exists('thing'), 1, 'exists(property)';


#--------------------------------------------------------------------#
use tests 4; # is_readonly

is_deeply $a1-> is_readonly('anything'), !1,
	'is_readonly(nonexistent property)';
is_deeply $a1-> is_readonly(2), !1, 'is_readonly(nonexistent elem)';
is_deeply $a1-> is_readonly('thing'), !1, 'is_readonly(property)';
is_deeply $a1-> is_readonly('toString'), !1, 'is_readonly(inherited prop)';


#--------------------------------------------------------------------#
use tests 3; # is_enum

is_deeply $a1-> is_enum('anything'), !1,
	'is_enum(nonexistent property)';
is_deeply $a1-> is_enum('thing'), 1, 'is_enum(property)';
is_deeply $a1-> is_enum('toString'), !1, 'is_enum(inherited prop)';


#--------------------------------------------------------------------#
use tests 1; # typeof

is_deeply typeof $a1, 'object', 'typeof returns "object"';


#--------------------------------------------------------------------#
use tests 1; # class

is_deeply $a1->class, 'Number', 'class returns "Number"';


#--------------------------------------------------------------------#
use tests 1; # id

is_deeply $a1->id, refaddr $a1, 'id';


#--------------------------------------------------------------------#
use tests 1; # primitive

is_deeply $a1->primitive, !1, 'primitive returns !1';


#--------------------------------------------------------------------#
use tests 7; # to_primitive

{
	my $thing;
	isa_ok $thing = $a1->to_primitive, 'JE::Number',
		'$a1->to_primitive';
	is $thing, '6.7',  '$a1->to_primitive';
	isa_ok $thing = $nan->to_primitive, 'JE::Number',
		'$nan->to_primitive';
	cmp_ok $thing, '!=', $thing, '$nan->to_primitive';
	isa_ok $thing = $inf->to_primitive, 'JE::Number',
		'$inf->to_primitive';
	cmp_ok $thing+1, '==', $thing, '$inf->to_primitive';
	cmp_ok $thing, '>', 0, '$inf->to_primitive > 0';
}


#--------------------------------------------------------------------#
use tests 2; # to_boolean

{
	my $z = new JE::Object::Number $j, 0;
	isa_ok my $thing = $z->to_boolean, 'JE::Boolean',
		'result of to_boolean';
	is $thing, 'true',  'to_boolean returns true';
}


#--------------------------------------------------------------------#
use tests 6; # to_string

{
	my $thing;
	isa_ok $thing = $a1->to_string, 'JE::String',
		'$a1->to_string';
	is $thing, '6.7',  '$a1->to_string';
	isa_ok $thing = $nan->to_string, 'JE::String',
		'$nan->to_string';
	is $thing, 'NaN', '$nan->to_string';
	isa_ok $thing = $inf->to_string, 'JE::String',
		'$inf->to_string';
	is $thing, 'Infinity', '$inf->to_string';
}


#--------------------------------------------------------------------#
use tests 7; # to_number

{
	my $thing;
	isa_ok $thing = $a1->to_number, 'JE::Number',
		'$a1->to_number';
	is $thing, '6.7',  '$a1->to_number';
	isa_ok $thing = $nan->to_number, 'JE::Number',
		'$nan->to_number';
	cmp_ok $thing, '!=', $thing, '$nan->to_number';
	isa_ok $thing = $inf->to_number, 'JE::Number',
		'$inf->to_number';
	cmp_ok $thing+1, '==', $thing, '$inf->to_number';
	cmp_ok $thing, '>', 0, '$inf->to_number > 0';
}


#--------------------------------------------------------------------#
use tests 1; # to_object

cmp_ok refaddr $a1-> to_object, '==', refaddr $a1, 'to_object';


#--------------------------------------------------------------------#
use tests 1; # global

is refaddr $j, refaddr global $a1, '->global';


#--------------------------------------------------------------------#
use tests 4; # Overloading

# %{} will be dealt with in je-object.t

is !$a1,  '',         '!$a1';

cmp_ok 0+$a1, '==', 6.7,  '0+$a1';
cmp_ok 0+$nan, '!=', 0+$nan,  '0+$nan';
cmp_ok 0+$inf, '==', 1+$inf,  '0+$inf';

