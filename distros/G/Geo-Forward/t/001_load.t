# -*- perl -*-

use Test::More tests => 6;

BEGIN { use_ok( 'Geo::Forward' ); }

my $gf = Geo::Forward->new;

isa_ok($gf, 'Geo::Forward');

can_ok($gf, qw{new initialize});

can_ok($gf, qw{ellipsoid forward});

isa_ok($gf->ellipsoid, 'Geo::Ellipsoids');

is($gf->ellipsoid->shortname, 'WGS84', 'Default ellipsoid is WGS84');
