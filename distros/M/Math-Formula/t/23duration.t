#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

my $expr = Math::Formula->new(test => 1);

### TOKENIZING

is_deeply $expr->_tokenize('P1Y'),    [MF::DURATION->new('P1Y')];

my $tok = $expr->_tokenize('-P1Y');
is_deeply $tok, [ MF::DURATION->new('-P1Y') ], 'negative';
my $dur = $tok->[0];
isa_ok $dur, 'MF::DURATION';
my $val = $dur->value;
isa_ok $val, 'DateTime::Duration';
ok $val->is_negative;
is $dur->_token($val), '-P1Y', 'recompute token';

my $long_duration = 'P2Y5M12DT11H45M12.345S';
is_deeply $expr->_tokenize($long_duration), [MF::DURATION->new($long_duration )];

### PARSING

my $dur1 = MF::DURATION->new('P1Y')->value;
ok defined $dur1, 'simple parsing';
isa_ok $dur1, 'DateTime::Duration';
cmp_ok $dur1->in_units('months'), '==', 12;  # only limited conversion support by D::D

my $dur2 = MF::DURATION->new('P20DT10H15S')->value;
ok defined $dur2, 'complex parsing';
isa_ok $dur2, 'DateTime::Duration';
is $dur2->in_units('days'), 20;    # ->days must be used icw weeks: 6 days + 2 weeks :-(
is $dur2->hours,   10;
is $dur2->seconds, 15;

my $dur3 = MF::DURATION->new(undef, DateTime::Duration->new);
is $dur3->token, 'PT0H0M0S', 'no duration';

### PREFIX OPERATORS

my $dur4 = MF::DURATION->new('P1Y');
is $dur4->prefix('+')->token, 'P1Y', 'prefix +';

my $dur5 = $dur4->prefix('-');
is $dur5->token, '-P1Y', 'prefix -';
ok $dur5->value->is_negative;

### INFIX OPERATORS

my @infix = (
	[ 'P4Y2MT3M5S', 'MF::DURATION', 'P3Y2M + P1YT3M5S' ],
	[ '-P2Y6MT2H8M14S', 'MF::DURATION', 'P1Y2MT3H5M - P3Y8MT5H13M14S' ],
	[ 'P4DT8H', 'MF::DURATION', 'P1DT2H * 4' ],
	[ 'P4DT8H', 'MF::DURATION', '4 * P1DT2H' ],

	[ -1, 'MF::INTEGER', "P10M <=> P11M" ],
	[  0, 'MF::INTEGER', "P11M <=> P11M" ],
	[  1, 'MF::INTEGER', "P12M <=> P11M" ],
);

foreach (@infix)
{	my ($result, $type, $rule) = @$_;

	$expr->_test($rule);
	my $eval = $expr->evaluate;
	is $eval->token, $result, "$rule -> $result";
	isa_ok $eval, $type;
}

done_testing;
