#!perl -wT

use strict;

use Test::Most tests => 1;

use Geo::Coder::CA;

isa_ok(Geo::Coder::CA->new(), 'Geo::Coder::CA', 'Creating Geo::Coder::CA object');
