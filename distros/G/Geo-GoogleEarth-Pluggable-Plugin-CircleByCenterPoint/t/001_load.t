# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Plugin::CircleByCenterPoint' ); }

ok(Geo::GoogleEarth::Pluggable::Plugin::CircleByCenterPoint->can("CircleByCenterPoint"));
ok(Geo::GoogleEarth::Pluggable::Plugin::CircleByCenterPoint->can("ArcByCenterPoint"));
