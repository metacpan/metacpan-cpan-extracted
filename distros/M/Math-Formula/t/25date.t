#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

use DateTime;
use DateTime::TimeZone::OffsetOnly ();

my $expr = Math::Formula->new(test => '2006-11-21');
my $context = {};

### PARSING

foreach my $token (
	"2023-02-18",
	"2023-02-18+0300",
) {
	my $node = MF::DATE->new($token);
	is_deeply $expr->_tokenize($token), [$node], $token;

	my $dt = $node->value;
	isa_ok $dt, 'DateTime';
}

### FORMATTING

my $random = DateTime->new(year => 2023, month => 2, day => 20,
	time_zone => DateTime::TimeZone::OffsetOnly->new(offset => '+0100')
);
my $node1a = MF::DATE->new(undef, $random);
is $node1a->token, '2023-02-20+0100', 'format';

### CASTING

my $node2 = MF::DATE->new('2023-01-01+0200')->cast('MF::DATETIME');
isa_ok $node2, 'MF::DATETIME', 'cast datetime';
is $node2->token, '2023-01-01T00:00:00+0200';

my $value1 = $expr->evaluate($context, expect => 'MF::DATE');
isa_ok $value1, 'MF::DATE', 'not converted';

my $node3 = MF::DATE->new('2023-01-01')->cast('MF::INTEGER');
isa_ok $node3, 'MF::INTEGER', 'cast integer to correct';
is $node3->token, '2021';

my $value2 = $expr->evaluate($context, expect => 'MF::INTEGER');
isa_ok $value2, 'MF::INTEGER', 'converted to int';
cmp_ok $value2->value, '==', 2006 -11 -21;

### PREFIX OPERATORS

### INFIX OPERATORS

my @infix = (
	[ '2023-02-18+0200', 'MF::DATE', '2023-02-21+0200 - P3D' ],
	[ '2023-02-24+0200', 'MF::DATE', '2023-02-21+0200 + P3DT0H' ],

	[ '2012-03-08T06:07:08+0100', 'MF::DATETIME', '2012-03-08+0100 + 06:07:08' ],

	[ 'P1M6D', 'MF::DURATION', '2023-02-26 - 2023-01-20' ],

	[ -1, 'MF::INTEGER', '2021-12-23 <=> 2022-03-05' ],
	[  0, 'MF::INTEGER', '2022-03-05 <=> 2022-03-05' ],
	[  1, 'MF::INTEGER', '2023-11-21 <=> 2022-03-05' ],

	# Casts a warning
	[  0, 'MF::INTEGER', '2022-03-05+0200 <=> 2022-03-05+0300' ],
);

### ATTRIBUTES

my $date  = "2006-11-21+0700";
my @attrs = (
	[ 2006,      'MF::INTEGER', "$date.year"  ],
	[ 11,        'MF::INTEGER', "$date.month" ],
	[ 21,        'MF::INTEGER', "$date.day"   ],
	[ '"+0700"', 'MF::STRING',  "$date.tz"    ],
);

foreach (@infix, @attrs)
{	my ($result, $type, $rule) = @$_;

	$expr->_test($rule);
	my $eval = $expr->evaluate;
	is $eval->token, $result, "$rule -> $result";
	isa_ok $eval, $type;
}

done_testing;
