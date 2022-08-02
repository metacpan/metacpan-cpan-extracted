#!perl -w

use strict;
use warnings;
use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	# eval 'use warnings::unused -global';
	eval 'use warnings::unused';

	if($@ || ($warnings::unused::VERSION < 0.04)) {
		plan(skip_all => 'warnings::unused >= 0.04 needed for testing');
	} else {
		use_ok('Geo::Coder::Abbreviations');
		new_ok('Geo::Coder::Abbreviations');
		plan tests => 2;
	}
} else {
	plan(skip_all => 'Author tests not required for installation');
}
