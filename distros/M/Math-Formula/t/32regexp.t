#!/usr/bin/env perl
# Test regular expressions, as far as not run by t/22string
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Math::Formula::Context ();

use Test::More;

my $expr    = Math::Formula->new(test => 1);
my $context = Math::Formula::Context->new(name => 'test');

### PREFIX

### INFIX

my @infix = (
	[ true  => 'MF::BOOLEAN', '"abc" =~ "b"', [ '1' ] ],
	[ false => 'MF::BOOLEAN', '"abc" =~ "d"' ],
	[ false => 'MF::BOOLEAN', '"abc" !~ "b"' ],
	[ true  => 'MF::BOOLEAN', '"abc" !~ "d"' ],

	[ true  => 'MF::BOOLEAN', '"abc" =~ "(b)"', [ 'b' ] ],
	[ true  => 'MF::BOOLEAN', '"abc" =~ "(a).(c)"', [ 'a', 'c' ] ],

	[ '"a"'   => 'MF::STRING',  '"abc" =~ "(.)" -> $1' ],
	[ '"ab"'  => 'MF::STRING',  '"abc" =~ "(.+)c" -> $1' ],
	[ '"ac"'  => 'MF::STRING',  '"abc" =~ "(.).(.)" -> $1 ~ $2' ],
);

### ATTRIBUTES

my @attrs = (
);

foreach (@infix, @attrs)
{	my ($result, $type, $rule, $capture) = @$_;

	ok 1, "test '$rule -> $result'";
	$expr->_test($rule);

	my $eval = $expr->evaluate($context);
	is $eval->token, $result, '... token';
	isa_ok $eval, $type, '... ';

	is_deeply $context->_captures, $capture, '... capture'
		if $capture;
}

done_testing;
