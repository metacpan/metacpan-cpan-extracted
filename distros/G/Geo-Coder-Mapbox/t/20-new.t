#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 2;
use Geo::Coder::Mapbox;

isa_ok(Geo::Coder::Mapbox->new(), 'Geo::Coder::Mapbox', 'Creating Geo::Coder::Mapbox object');
ok(!defined(Geo::Coder::Mapbox::new()));
