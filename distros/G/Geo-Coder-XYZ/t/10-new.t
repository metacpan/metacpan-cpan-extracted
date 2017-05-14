#!perl -wT

use strict;

use Test::Most tests => 1;

use Geo::Coder::XYZ;

isa_ok(Geo::Coder::XYZ->new(), 'Geo::Coder::XYZ', 'Creating Geo::Coder::XYZ object');
