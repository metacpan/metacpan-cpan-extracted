#!perl -w

use strict;
use warnings;
use Test::Most tests => 5;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Coder::Abbreviations');
}

my $abbr = new_ok('Geo::Coder::Abbreviations');
cmp_ok($abbr->normalize('1600 Pennsylvania Avenue NW'), 'eq', '1600 PENNSYLVANIA AV NW', 'Basic normalize test');
cmp_ok(Geo::Coder::Abbreviations::normalize('street' => '10 Downing Street'), 'eq', '10 DOWNING ST', 'Verify class method');
