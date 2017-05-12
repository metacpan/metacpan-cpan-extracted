# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Plugin::GreatCircle' ); }

ok(Geo::GoogleEarth::Pluggable::Plugin::GreatCircle->can("GreatCircleArcSegment"), 'GreatCircleArcSegment');

