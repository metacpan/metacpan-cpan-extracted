use strict;
use warnings;
use Test::More tests => 11;
BEGIN { use_ok('Geo::Leaflet') };
BEGIN { use_ok('Geo::Leaflet::TileLayer') };

my $map = Geo::Leaflet->new;
isa_ok($map, 'Geo::Leaflet');
can_ok($map, 'center');
is($map->center->[0],  38.2, 'center lat');
is($map->center->[1], -97.2, 'center lon');

can_ok($map, 'zoom');
is($map->zoom, 4.5, 'zoom');

can_ok($map, 'setView');
isa_ok($map->setView, 'Geo::Leaflet');

isa_ok($map->tileLayer, 'Geo::Leaflet::TileLayer');
