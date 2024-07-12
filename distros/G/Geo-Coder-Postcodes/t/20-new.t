#!perl -wT

use strict;

use Test::Most tests => 4;

use_ok('Geo::Coder::Postcodes');

isa_ok(Geo::Coder::Postcodes->new(), 'Geo::Coder::Postcodes', 'Creating Geo::Coder::Postcodes object');
isa_ok(Geo::Coder::Postcodes::new(), 'Geo::Coder::Postcodes', 'Creating Geo::Coder::Postcodes object');
isa_ok(Geo::Coder::Postcodes->new()->new(), 'Geo::Coder::Postcodes', 'Cloning Geo::Coder::Postcodes object');
