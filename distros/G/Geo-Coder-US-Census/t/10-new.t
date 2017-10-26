#!perl -wT

use strict;

use Test::Most tests => 1;

use Geo::Coder::US::Census;

isa_ok(Geo::Coder::US::Census->new(), 'Geo::Coder::US::Census', 'Creating Geo::Coder::US::Census object');
