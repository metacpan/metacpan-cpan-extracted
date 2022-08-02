#!perl -w

use warnings;
use strict;

use lib 'lib';
use Test::Most tests => 4;

BEGIN {
	use_ok('Geo::Coder::Abbreviations');
}

isa_ok(Geo::Coder::Abbreviations->new(), 'Geo::Coder::Abbreviations', 'Creating Geo::Coder::Abbreviations object');
ok(!defined(Geo::Coder::Abbreviations::new()));
require_ok('Geo::Coder::Abbreviations');
