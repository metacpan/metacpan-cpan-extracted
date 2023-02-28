#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

my $expr = Math::Formula->new(test => 1);

is_deeply $expr->_tokenize('48'), [ MF::INTEGER->new('48') ];

### PARSING

foreach (
	[ '42'          => 42          ],
	[ '43k'         => 43_000      ],
	[ '44M'         => 44_000_000  ],
	[ '45kibi'      => 45 * 1024   ],
	[ '46_000'      => 46000       ],
	[ '470_123_456' => 470_123_456 ],
	[ '470_123_456' => 470_123_456 ],
)
{   my ($token, $value) = @$_;

	my $i = MF::INTEGER->new($token);
	is $i->token, $token, "... $token";
	cmp_ok $i->value, '==', $value;
}

### CASTING

my $string = MF::INTEGER->new(42)->cast('MF::STRING');
ok defined $string, 'cast to string';
isa_ok $string, 'MF::STRING';
is $string->token, '"42"';

my $bool1 = MF::INTEGER->new(2)->cast('MF::BOOLEAN');
isa_ok $bool1, 'MF::BOOLEAN', 'cast to true';
is $bool1->value, 1;
is $bool1->token, 'true';

my $bool2 = MF::INTEGER->new(0)->cast('MF::BOOLEAN');
isa_ok $bool2, 'MF::BOOLEAN', 'cast to false';
is $bool2->value, 0;
is $bool2->token, 'false';

### PREFIX operators

$expr->_test('+4');
cmp_ok $expr->evaluate->value, '==', 4, 'prefix +';

$expr->_test('-4');
cmp_ok $expr->evaluate->value, '==', -4, 'prefix -';

$expr->_test('+-++--4');
cmp_ok $expr->evaluate->value, '==', -4, 'prefix list';

### INFIX operators

my @infix = (
	[ true  => 'MF::BOOLEAN' => '42 and true' ],
	[ true  => 'MF::BOOLEAN' => '43 or false' ],
	[ true  => 'MF::BOOLEAN' => '44 xor false' ],
	[ false => 'MF::BOOLEAN' => '45 xor true' ],

	[ 3 => 'MF::INTEGER' => '1 + 2' ],
	[ 4 => 'MF::INTEGER' => '7 - 3' ],
	[ 8 => 'MF::INTEGER' => '2 * 4' ],
	[ 3 => 'MF::INTEGER' => '203 % 10' ],

	[ '7.0' => 'MF::FLOAT' => '21 / 3' ],
	[ '3.0' => 'MF::FLOAT' => '1 + 2.0' ],
	[ '4.0' => 'MF::FLOAT' => '7 - 3.0' ],
	[ '8.0' => 'MF::FLOAT' => '2 * 4.0' ],
	[ '3.0' => 'MF::FLOAT' => '203 % 10.0' ],

	[ -1 => 'MF::INTEGER' => '1 <=> 2' ],
	[  0 => 'MF::INTEGER' => '2 <=> 2' ],
	[  1 => 'MF::INTEGER' => '3 <=> 2' ],

	[ -1 => 'MF::INTEGER' => '1 <=> 2.0' ],
	[  0 => 'MF::INTEGER' => '2 <=> 2.0' ],
	[  1 => 'MF::INTEGER' => '3 <=> 2.0' ],
);

### ATTRIBUTES

my @attrs = (
	[ 3 => 'MF::INTEGER' => '(-3).abs' ],
	[ 4 => 'MF::INTEGER' => '4.abs' ],
);

foreach (@infix, @attrs)
{	my ($result, $type, $rule) = @$_;

	$expr->_test($rule);
	my $eval = $expr->evaluate;
	is $eval->token, $result, "$rule -> $result";
	isa_ok $eval, $type;
}

done_testing;
