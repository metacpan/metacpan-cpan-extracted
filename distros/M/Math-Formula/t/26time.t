#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Math::Formula::Context ();
use Test::More;

use DateTime;

my $expr    = Math::Formula->new(test => 1);
my $context = Math::Formula::Context->new(name => 'test');

### PARSING

foreach my $token (
	"01:28:12",
	"01:28:12.345",
) {
	my $node = MF::TIME->new($token);
	is_deeply $expr->_tokenize($token), [$node], $token;

	my $dt = $node->value;
	isa_ok $dt, 'HASH';
}

### FORMATTING

my $node2 = MF::TIME->new(undef, { hour => 7, minute => 12, second => 8 });
is $node2->token, '07:12:08', 'formatting without frac';

my $node = MF::TIME->new(undef, { hour => 3, minute => 20, second => 4, ns => 1_023_000 });
is $node->token, '03:20:04.001023', 'formatting with frac';

### CASTING

### PREFIX OPERATORS

### INFIX OPERATORS

my @infix = (
	[ '12:30:34', 'MF::TIME', '12:00:34 + PT30M' ],
	[ '11:45:34', 'MF::TIME', '12:00:34 - PT15M' ],
	[ '06:40:00', 'MF::TIME', '23:40:00 + PT7H'  ],

	[ 'PT2H30M12S',    'MF::DURATION', '23:40:00 - 21:09:48' ],
	[ 'PT2H30M12.13S', 'MF::DURATION', '23:40:00.35 - 21:09:48.22' ],
	[ 'PT2H30M11.63S', 'MF::DURATION', '23:40:00.35 - 21:09:48.72' ],
);

### ATTRIBUTES

my $time  = '02:03:04.5678';
my $node3 = MF::TIME->new($time);
is_deeply $node3->attribute('hour')->($node3),    MF::INTEGER->new(undef, 2), 'hour';
is_deeply $node3->attribute('minute')->($node3),  MF::INTEGER->new(undef, 3), 'minute';
is_deeply $node3->attribute('second')->($node3),  MF::INTEGER->new(undef, 4), 'second';
is_deeply $node3->attribute('fracsec')->($node3), MF::FLOAT  ->new(undef, 4.5678), 'fracsec';

my @attrs = (
	[ 2,      'MF::INTEGER', "$time.hour"    ],
	[ 3,      'MF::INTEGER', "$time.minute"  ],
	[ 4,      'MF::INTEGER', "$time.second"  ],
	[ 4.5678, 'MF::FLOAT',   "$time.fracsec" ],
);

foreach (@infix, @attrs)
{	my ($result, $type, $rule) = @$_;

	$expr->_test($rule);
	my $eval = $expr->evaluate($context);
	is $eval->token, $result, "$rule -> $result";
	isa_ok $eval, $type;
}

done_testing;
