#!perl -wT

use strict;
use warnings;

use Test::Most tests => 2;

use Geo::Coder::XYZ;

isa_ok(Geo::Coder::XYZ->new(), 'Geo::Coder::XYZ', 'Creating Geo::Coder::XYZ object');
ok(!defined(Geo::Coder::XYZ::new()));
