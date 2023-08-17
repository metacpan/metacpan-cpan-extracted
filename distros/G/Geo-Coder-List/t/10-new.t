#!perl -wT

use strict;

use Test::Most tests => 4;

use_ok('Geo::Coder::List');

isa_ok(Geo::Coder::List->new(), 'Geo::Coder::List', 'Creating Geo::Coder::List object');
isa_ok(Geo::Coder::List::new(), 'Geo::Coder::List', 'Creating Geo::Coder::List object');
isa_ok(Geo::Coder::List->new()->new(), 'Geo::Coder::List', 'Cloning Geo::Coder::List object');
# ok(!defined(Geo::Coder::List::new()));
