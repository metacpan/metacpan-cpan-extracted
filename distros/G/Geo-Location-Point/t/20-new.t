#!perl -wT

use strict;

# use lib 'lib';
use Test::Most tests => 3;

use_ok('Geo::Location::Point');

isa_ok(Geo::Location::Point->new({ lat => 0, long => 0 }), 'Geo::Location::Point', 'Creating Geo::Location::Point object');
ok(!defined(Geo::Location::Point::new()));
