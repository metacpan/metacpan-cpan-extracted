#!perl  -T

BEGIN { require './t/test.pl' }

use Test::More tests => 146;
use Scalar::Util 'refaddr';
use strict;
use utf8;


#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN { use_ok 'JE::Object::Array' }; # Make sure it loads without JE
                                # already loaded.
BEGIN { use_ok 'JE' };


#--------------------------------------------------------------------#
# Tests 3-6: Object creation

our $j = JE->new,;
isa_ok $j, 'JE', 'global object';

our $a1 = new JE::Object::Array $j ,[qw/an array ref/];
our $a2 = new JE::Object::Array $j, $j->eval(6);
our $a3 = new JE::Object::Array $j, qw/a list/;
isa_ok $a1, 'JE::Object::Array', 'array from array ref';
isa_ok $a2, 'JE::Object::Array', 'array with specified length';
isa_ok $a3, 'JE::Object::Array', 'array from list';


#--------------------------------------------------------------------#
# Tests 7-9: string overloading (check that the arrays were initialised
#            properly before we go and mangle them)

is "$a1", 'an,array,ref', 'string overloading (1)';
is "$a2", ',,,,,',        'string overloading (2)';;
is "$a3", 'a,list',       'string overloading (3)';

#--------------------------------------------------------------------#
# Tests 10-13: prop

{
	is $a1->prop(thing => $j->upgrade('value')), 'value',
		'prop returns the assigned value';
	is $a1->prop('thing'), 'value', 'the assignment worked';
	is $a1->prop(0), 'an', 'get property';
	isa_ok $a1->prop(0), 'JE::String', 'the property';
}


#--------------------------------------------------------------------#
# Test 14: keys

is_deeply [sort $a1->keys], [qw/0 1 2 thing/], 'keys';


#--------------------------------------------------------------------#
# Test 15-24: delete

is_deeply $a1->delete('anything'), 1, 'delete nonexistent property';
is_deeply $a2->delete('0'), 1, 'delete nonexistent array elem';
is_deeply $a1->delete('thing'), 1, 'delete property';
is_deeply $a1->prop('thing'), undef, 'was the property deleted?';
is_deeply $a1->delete('2'), 1, 'delete array elem';
is_deeply $a1->prop(2), undef, 'was it deleted?';
is $a1->prop('length'), 3, 'was length left untouched?';
is_deeply $a2->delete('0'), 1, 'delete nonexistent array elem';
is_deeply $a1->delete('length'), !1, 'delete length';
is $a1->prop('length'), 3, 'does length still exist?';


#--------------------------------------------------------------------#
# Tests 25-6: method

{
	isa_ok my $ret = $a1->method('toString'), 'JE::String',
		'result of method("toString")';
	ok $ret eq 'an,array,',
		'$a1->method("toString") returns "an,array,"';
}


#--------------------------------------------------------------------#
# Tests 27-47: value

{
	my $value;

	is ref($value = $a1->value), 'ARRAY',
		'$a1->value returns an ARRAY';
	is scalar(@$value), 3, 'scalar @{$a1->value}';
	isa_ok $value->[0], 'JE::String', '$a1->value->[0]';
	is $value->[0], 'an', '$a1->value->[0]';
	isa_ok $value->[1], 'JE::String', '$a1->value->[1]';
	is $value->[1], 'array', '$a1->value->[1]';
	is_deeply $value->[2], undef, '$a1->value->[2]';

	is ref($value = $a2->value), 'ARRAY',
		'$a2->value returns an ARRAY';
	is scalar(@$value), 6, 'scalar @{$a2->value}';
	for(0..5) {
		is_deeply $value->[$_], undef, "\$a2->value->[$_]";
	}

	is ref($value = $a3->value), 'ARRAY',
		'$a3->value returns an ARRAY';
	is scalar(@$value), 2, 'scalar @{$a3->value}';
	isa_ok $value->[0], 'JE::String', '$a3->value->[0]';
	is $value->[0], 'a', '$a3->value->[0]';
	isa_ok $value->[1], 'JE::String', '$a3->value->[1]';
	is $value->[1], 'list', '$a3->value->[1]';
}

#--------------------------------------------------------------------#
# Test 48: call

eval {
	$a1->call
};
like $@, qr/^Can't locate object method/, 'call dies';


#--------------------------------------------------------------------#
# Test 49: apply

eval {
	$a1->apply
};
like $@, qr/^Can't locate object method/, 'apply dies';


#--------------------------------------------------------------------#
# Test 50: construct

eval {
	$a1->construct
};
like $@, qr/^Can't locate object method/, 'construct dies';


#--------------------------------------------------------------------#
# Tests 51-5: exists

$a1->prop(thing => $j->undefined);

is_deeply $a1->exists('anything'), !1, 'exists(nonexistent property)';
is_deeply $a1->exists(2), !1, 'exists(nonexistent elem)';
is_deeply $a1->exists('thing'), 1, 'exists(property)';
is_deeply $a1->exists(0), 1, 'exists(elem)';
is_deeply $a1->exists('length'), 1, 'exists(length)';


#--------------------------------------------------------------------#
# Tests 56-61: is_readonly

# Arrays never have any readonly properties

is_deeply $a1-> is_readonly('anything'), !1,
	'is_readonly(nonexistent property)';
is_deeply $a1-> is_readonly(2), !1, 'is_readonly(nonexistent elem)';
is_deeply $a1-> is_readonly('thing'), !1, 'is_readonly(property)';
is_deeply $a1-> is_readonly(0), !1, 'is_readonly(elem)';
is_deeply $a1-> is_readonly('length'), !1, 'is_readonly(length)';
is_deeply $a1-> is_readonly('toString'), !1, 'is_readonly(inherited prop)';


#--------------------------------------------------------------------#
# Tests 62-7: is_enum

is_deeply $a1-> is_enum('anything'), !1,
	'is_enum(nonexistent property)';
is_deeply $a1-> is_enum(2), !1, 'is_enum(nonexistent elem)';
is_deeply $a1-> is_enum('thing'), 1, 'is_enum(property)';
is_deeply $a1-> is_enum(0), 1, 'is_enum(elem)';
is_deeply $a1-> is_enum('length'), !1, 'is_enum(length)';
is_deeply $a1-> is_enum('toString'), !1, 'is_enum(inherited prop)';


#--------------------------------------------------------------------#
# Test 68: typeof

is_deeply typeof $a1, 'object', 'typeof returns "object"';


#--------------------------------------------------------------------#
# Test 69: class

is_deeply $a1->class, 'Array', 'class returns "Array"';


#--------------------------------------------------------------------#
# Test 70: id

is_deeply $a1->id, refaddr $a1, 'id';


#--------------------------------------------------------------------#
# Test 71: primitive like an ape

is_deeply $a1->primitive, !1, 'primitive returns !1';


#--------------------------------------------------------------------#
# Tests 72-7: to_primitive

{
	my $thing;
	isa_ok $thing = $a1->to_primitive, 'JE::String',
		'$a1->to_primitive';
	is $thing, 'an,array,',  '$a1->to_primitive';
	isa_ok $thing = $a2->to_primitive, 'JE::String',
		'$a2->to_primitive';
	is $thing, ',,,,,', '$a2->to_primitive';
	isa_ok $thing = $a3->to_primitive, 'JE::String',
		'$a3->to_primitive';
	is $thing, 'a,list', '$a3->to_primitive';
}


#--------------------------------------------------------------------#
# Tests 78-9: to_boolean

{
	isa_ok my $thing = $a1->to_boolean, 'JE::Boolean',
		'result of to_boolean';
	is $thing, 'true',  'to_boolean returns true';
}


#--------------------------------------------------------------------#
# Tests 80-85: to_string

{
	my $thing;
	isa_ok $thing = $a1->to_string, 'JE::String',
		'$a1->to_string';
	is $thing, 'an,array,',  '$a1->to_string';
	isa_ok $thing = $a2->to_string, 'JE::String',
		'$a2->to_string';
	is $thing, ',,,,,', '$a2->to_string';
	isa_ok $thing = $a3->to_string, 'JE::String',
		'$a3->to_string';
	is $thing, 'a,list', '$a3->to_string';
}


#--------------------------------------------------------------------#
# Test 86-91: to_number

{
	my $thing;
	isa_ok $thing = $a1->to_number, 'JE::Number',
		'$a1->to_number';
	is $thing, 'NaN',  '$a1->to_number';
	isa_ok $thing = $a2->to_number, 'JE::Number',
		'$a2->to_number';
	is $thing, 'NaN', '$a2->to_number';
	isa_ok $thing = $a3->to_number, 'JE::Number',
		'$a3->to_number';
	is $thing, 'NaN', '$a3->to_number';
}


#--------------------------------------------------------------------#
# Test 92: to_object

cmp_ok refaddr $a1-> to_object, '==', refaddr $a1, 'to_object';


#--------------------------------------------------------------------#
# Test 93: global

is refaddr $j, refaddr global $a1, '->global';


#--------------------------------------------------------------------#
# Tests 94-7: Overloading

# @{} and %{} are dealt with further down

is !$a1,  '',         '!$a1';

cmp_ok 0+$a1, '!=', 0+$a1,  '0+$a1';
cmp_ok 0+$a2, '!=', 0+$a2,  '0+$a2';
cmp_ok 0+$a3, '!=', 0+$a3,  '0+$a3';


#--------------------------------------------------------------------#
# Tests 98-122: Array ties

our @a;
*a = \@$a1; # for convenience' sake
is $a[0], 'an', 'array FETCH';
$a[0] = 'and';
is $a1->prop(0), 'and', 'array STORE';
is @a, 3, 'FETCHSIZE';
$#a = 3;
is $a1->prop('length'), 4, 'STORESIZE';
ok  exists $a[0], 'EXISTS';
ok !exists $a[2], 'EXISTS (nonexistent)';
is delete $a[0], 'and', 'DELETE returns the deleted value';
is_deeply $a1->prop(0), undef, 'DELETE works';
is push(@a, 'Χριστὸς ἀνέστη!'), 5, 'PUSH';
is $a1->prop('length'), 5, 'PUSH modified the length property';
is $a1->prop(4), 'Χριστὸς ἀνέστη!', 'PUSH assigned the pushed value';
is pop @a, 'Χριστὸς ἀνέστη!', 'POP';
is $a1->prop('length'), 4, 'POP modified the length property';
$a1->prop(0,'Ἀληθῶς ἀνέστη!');
is shift @a, 'Ἀληθῶς ἀνέστη!', 'SHIFT';
is $a1->prop('length'), 3, 'SHIFT adjusts the length';
is unshift(@a, 'I'), 4, 'UNSHIFT';
is $a1->prop('length'), 4, 'UNSHIFT changes the length';
is_deeply [splice @a, 2, 2, qw/myself in it./], [(undef)x2],
	'SPLICE';
is_deeply \@a, [qw/I array myself in it./], 'result of SPLICE';

eval {
	@a = ();
};
like $@, qr/^Can't locate object method/, '@$a1 = () dies';
delete $a[0];
$a[0]{1} = 3;
isa_ok $a[0], 'JE::Object', '$a[0] (after []{} autovivifcation)';
is $a[0]{1}, 3, '$a[0]{1} after []{} autovivification';
delete $a[0];
$a[0][1] = 3;
isa_ok $a[0], 'JE::Object::Array', '$a[0] (after [][] autovivifcation)';
is $a[0][1], 3, '$a[0][1] after [][] autovivification';
delete $a[0];
$a[0] = \@@;
ok !tied @@,
	'explicit array assignment is not confused with autovivification';



#--------------------------------------------------------------------#
# Tests 123-42: Hash ties

our %h;
*h = \%$a1;
$a1->delete(0);

is_deeply $h{0}, undef, '$a1->{0} (FETCH)';
is $h{1}, 'array', '$a1->{1} (FETCH)';
is $h{thing}, 'undefined', '$a1->{thing} (FETCH)';
$h{1} = 3;
is $a1->prop(1), 3, 'STORE array elem';
$h{aoeu} = 'htns';
is $a1->prop('aoeu'), 'htns', 'STORE property';
is delete $h{1}, 3, 'return value of DELETE (hash)';
is_deeply $a1->prop(1), undef, 'hash DELETE works';
ok !exists $h{1}, 'hash EXISTS nonexistent elem';
ok  exists $h{2}, 'hash EXISTS(elem)';
ok !exists $h{snth}, 'hash EXISTS(nonexistent prop)';
ok  exists $h{thing}, 'hash EXISTS(prop)';
ok  exists $h{length}, 'hash EXISTS(length)';
ok !exists $h{toString}, 'hash EXISTS(inherited prop)';
is join('-', keys %h), '2-3-4-thing-aoeu', 'keys %{}';

eval {
	%h = ();
};
like $@, qr/^Can't locate object method/, '%$a1 = () dies';
$h{0}{1} = 3;
isa_ok $h{0}, 'JE::Object', '$h{0} (after {}{} autovivifcation)';
is $h{0}{1}, 3, '$h{0}{1} after {}{} autovivification';
delete $h{0};
$h{0}[1] = 3;
isa_ok $h{0}, 'JE::Object::Array', '$h{0} (after {}[] autovivifcation)';
is $h{0}[1], 3, '$h{0}[1] after {}[] autovivification';
delete $h{0};
$h{0} = \%@;
ok !tied(%@),
	'explicit hash assignment is not confused with autovivification';


#--------------------------------------------------------------------#
# Tests 143-6: Freezing with ties present

SKIP: {
	eval 'require Data::Dump::Streamer' or
		skip 'Data::Dump::Streamer not present', 4;
	import Data::Dump::Streamer;

	ok exists $$$a1{tie}, 'hash tie is present before freeze';
	ok exists $$$a1{array_tie}, 'array tie is present before freeze';
	{ my $black_hole = Dump($a1)->Out; }
	ok !exists $$$a1{tie}, 'hash tie\'s gone';
	ok !exists $$$a1{array_tie}, 'array tie\'s gone';
}
