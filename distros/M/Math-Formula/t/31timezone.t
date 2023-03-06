#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

my $expr = Math::Formula->new(test => 1);

is_deeply $expr->_tokenize('+0100'), [ MF::TIMEZONE->new('+0100') ];
is_deeply $expr->_tokenize('-0315'), [ MF::TIMEZONE->new('-0315') ];

### PARSING

foreach (
	[ '+0000'       => 0    ],
	[ '+0005'       => 5    ],
	[ '+0010'       => 10   ],
	[ '+0200'       => 120  ],
	[ '+0215'       => 135  ],
	[ '-0215'       => -135 ],
)
{   my ($token, $value) = @$_;

	my $i = MF::TIMEZONE->new($token);
	is $i->token, $token, "... $token";
	cmp_ok $i->value, '==', $value;
}

### CASTING

my $string = MF::TIMEZONE->new('+0445')->cast('MF::STRING');
ok defined $string, 'cast to string';
isa_ok $string, 'MF::STRING';
is $string->token, '"+0445"';

# mis-parsing tz, was integer

my $string2 = MF::TIMEZONE->new('+0445')->cast('MF::INTEGER');
ok defined $string2, 'fix to integer';
isa_ok $string2, 'MF::INTEGER';
is $string2->token, '445';

### PREFIX operators

$expr->_test('+ +0445');
is $expr->evaluate->token, '+0445', 'prefix +';

$expr->_test('- +0445');
is $expr->evaluate->token, '-0445', 'prefix -';

### INFIX operators

my @infix = (
	[ '+0115' => 'MF::TIMEZONE' => '+0100 + PT15M' ],
	[ '+0045' => 'MF::TIMEZONE' => '+0100 - PT15M' ],
	[ '-0215' => 'MF::TIMEZONE' => '+0100 - PT3H15M' ],
);

### ATTRIBUTES

my $tz = '-1236';
my @attrs = (
	[ -756,   'MF::INTEGER', "$tz.in_minutes" ],
	[ -45360, 'MF::INTEGER', "$tz.in_seconds" ],
);

### CHECK FIXING PARSER ISSUE

my @issues = (
	[ 8000,     'MF::INTEGER', '8 * +1000' ],
	[ '7500.0', 'MF::FLOAT',   '7.5 * +1000' ],
	[ 1008,     'MF::INTEGER', '5 +1000 + 3' ],
	[ -992,     'MF::INTEGER', '5 -1000 + 3' ],
);

foreach (@infix, @attrs, @issues)
{	my ($result, $type, $rule) = @$_;

	$expr->_test($rule);
	my $eval = $expr->evaluate;
	is $eval->token, $result, "$rule -> $result";
	isa_ok $eval, $type;
}

done_testing;
