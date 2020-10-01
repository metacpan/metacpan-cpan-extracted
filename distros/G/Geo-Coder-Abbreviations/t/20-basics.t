#!perl -wT

use strict;
use warnings;
use Test::Most tests => 4;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Coder::Abbreviations');
}

NEW: {
	my $abbr = new_ok('Geo::Coder::Abbreviations');

	ok($abbr->abbreviate('Road') eq 'RD');
}
