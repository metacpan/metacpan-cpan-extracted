#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

my $expr = Math::Formula->new(test => 1);

### TOKENIZING

my $p = MF::FLOAT->_match;
foreach my $token ( qw/0.0 0e+0 1.345 7e+10 12.231e-10/ )
{	ok $token =~ qr/$p/xo, $token;
	is_deeply $expr->_tokenize($token),    [ MF::FLOAT->new($token) ];
}

### VALUE

# Comparisons with floats are always a bit painfull
foreach (
	[ '7.0' => 7.0 ],
)
{   my ($token, $value) = @$_;

	my $i = MF::FLOAT->new($token);
	is $i->token, $token, "... $token";
	cmp_ok $i->value, '==', $value;
}

### CASTing

my $string = MF::FLOAT->new('12.3')->cast('MF::STRING');
ok defined $string, 'cast to string';
isa_ok $string, 'MF::STRING';
is $string->token, '"12.3"';

my $int = MF::FLOAT->new('42.12')->cast('MF::INTEGER');
ok defined $int, 'cast to integer';
isa_ok $int, 'MF::INTEGER';
is $int->token, '42';
cmp_ok $int->value, '==', 42;


### PREFIX operators

my @prefix = (
	# prefix - will parse the floats, where + doesn't
	[  '4.0' => 'MF::FLOAT' => '+4.0'      ],
	[ '-4.0' => 'MF::FLOAT' => '-4.0'      ],
	[ '-4.0' => 'MF::FLOAT' => '+-++--4.0' ],
	[  '0.0' => 'MF::FLOAT' => '-0.0e+3'   ],
);

foreach (@prefix)
{	my ($result, $type, $rule) = @$_;

	$expr->_test($rule);
	my $eval = $expr->evaluate;
	is $eval->token, $result, "$rule -> $result";
	isa_ok $eval, $type;
}

### INFIX operators

my @infix = (
	[ '3.0' => 'MF::FLOAT' => '1.0 + 2.0' ],
	[ '4.0' => 'MF::FLOAT' => '7.0 - 3.0' ],
	[ '8.0' => 'MF::FLOAT' => '2.0 * 4.0' ],
	[ '3.0' => 'MF::FLOAT' => '203.0 % 10.0' ],
	[ '3.0' => 'MF::FLOAT' => '21.0 / 7.0' ],

	# With cast from INTEGER
	[ '3.0' => 'MF::FLOAT' => '1.0 + 2' ],
	[ '4.0' => 'MF::FLOAT' => '7.0 - 3' ],
	[ '8.0' => 'MF::FLOAT' => '2.0 * 4' ],
	[ '3.0' => 'MF::FLOAT' => '203.0 % 10' ],
	[ '3.0' => 'MF::FLOAT' => '21.0 / 7' ],

	[ -1 => 'MF::INTEGER' => '1.0 <=> 2' ],
	[  0 => 'MF::INTEGER' => '2.0 <=> 2' ],
	[  1 => 'MF::INTEGER' => '3.0 <=> 2' ],

	[ -1 => 'MF::INTEGER' => '1.0 <=> 2.0' ],
	[  0 => 'MF::INTEGER' => '2.0 <=> 2.0' ],
	[  1 => 'MF::INTEGER' => '3.0 <=> 2.0' ],

	[ 3.14 => 'MF::FLOAT' => 3.14 ],
);

foreach (@infix)
{	my ($result, $type, $rule) = @$_;

	$expr->_test($rule);
	my $eval = $expr->evaluate;
	is $eval->token, $result, "$rule -> $result";
	isa_ok $eval, $type;
}

done_testing;
