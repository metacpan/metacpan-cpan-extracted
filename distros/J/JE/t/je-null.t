#!perl  -T

BEGIN { require './t/test.pl' }

use Test::More tests => 29;
use Scalar::Util 'refaddr';
use strict;
use utf8;


#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN { use_ok 'JE::Null' }; # Make sure it loads without JE
                                # already loaded.
BEGIN { use_ok 'JE' };


#--------------------------------------------------------------------#
# Tests 3-4: Object creation

our $j = JE->new,;
isa_ok $j, 'JE', 'global object';
our $null = JE::Null->new($j,0);
isa_ok $null, 'JE::Null', 'null';


#--------------------------------------------------------------------#
# Test 5: prop

eval {
	$null->prop
};
like $@, qr/^Can't locate object method/, '$null->prop dies';


#--------------------------------------------------------------------#
# Test 6: keys

eval {
	$null->keys
};
like $@, qr/^Can't locate object method/, '$null->keys die';


#--------------------------------------------------------------------#
# Test 7: delete

eval {
	$null->delete
};
like $@, qr/^Can't locate object method/, '$null->delete dies';


#--------------------------------------------------------------------#
# Test 8: method

eval {
	$null->method
};
like $@, qr/^Can't locate object method/, '$null->method dies';


#--------------------------------------------------------------------#
# Test 9: value

is_deeply $null->value,  undef, 'value';


#--------------------------------------------------------------------#
# Test 10: call

eval {
	$null->call
};
like $@, qr/^Can't locate object method/, '$null->call dies';


#--------------------------------------------------------------------#
# Test 11: apply

eval {
	$null->apply
};
like $@, qr/^Can't locate object method/, '$null->call dies';


#--------------------------------------------------------------------#
# Test 12: construct

eval {
	$null->construct
};
like $@, qr/^Can't locate object method/, '$null->construct dies';


#--------------------------------------------------------------------#
# Test 13: exists

eval {
	$null-> exists
};
like $@, qr/^Can't locate object method/, '$null->exists dies';


#--------------------------------------------------------------------#
# Test 14: typeof

is_deeply typeof $null, 'object', 'typeof returns "object"';


#--------------------------------------------------------------------#
# Test 15: class

eval {
	$null-> class
};
like $@, qr/^Can't locate object method/, '$null->class dies';


#--------------------------------------------------------------------#
# Test 16: id

is_deeply $null->id, 'null', '$null->id';


#--------------------------------------------------------------------#
# Test 17: primitive like an ape

is_deeply $null->primitive, 1, 'primitive returns 1';


#--------------------------------------------------------------------#
# Test 18: to_primitive

cmp_ok refaddr $null->to_primitive, '==', refaddr $null, 'to_primitive';


#--------------------------------------------------------------------#
# Tests 19-20: to_boolean

{
	isa_ok my $nullhing = $null-> to_boolean, 'JE::Boolean';
	is $nullhing, 'false',  '$null->to_boolean is floss';
}


#--------------------------------------------------------------------#
# Tests 21-2: to_string

{
	isa_ok my $nullhing = $null->to_string, 'JE::String';
	is $nullhing, 'null',  '$null->to_string is "null"';
}


#--------------------------------------------------------------------#
# Tests 23-4: to_number

{
	isa_ok my $nullhing = $null->to_number, 'JE::Number';
	cmp_ok $nullhing, '==', 0, '$null->to_number == 0';
}


#--------------------------------------------------------------------#
# Test 25: to_object

eval {
	$null-> to_object
};
like $@, qr/^Can't locate object method/, '$null->to_object dies';


#--------------------------------------------------------------------#
# Test 26: global

is refaddr $j, refaddr global $null, '->global';


#--------------------------------------------------------------------#
# Tests 27-9: Overloading

is  "$null", 'null',  '"$null"';
is  !$null,   1,      '!$null';
is 0+$null,   0,     '0+$null';


