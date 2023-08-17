#!perl -w

use warnings;
use strict;

use lib 'lib';
use Test::Most tests => 5;

BEGIN {
	use_ok('Geo::Coder::Abbreviations');
}

isa_ok(Geo::Coder::Abbreviations->new(), 'Geo::Coder::Abbreviations', 'Creating Geo::Coder::Abbreviations object');
isa_ok(Geo::Coder::Abbreviations::new(), 'Geo::Coder::Abbreviations', 'Creating Geo::Coder::Abbreviations object');
isa_ok(Geo::Coder::Abbreviations->new()->new(), 'Geo::Coder::Abbreviations', 'Cloning Geo::Coder::Abbreviations object');
require_ok('Geo::Coder::Abbreviations');
