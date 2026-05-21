use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 9;
BEGIN { use_ok('Geo::Leaflet') };

my $map = Geo::Leaflet->new(center=>[51.505, -0.09], zoom=>13);
isa_ok($map, 'Geo::Leaflet');

my $tile = $map->tileLayer;
isa_ok($tile, 'Geo::Leaflet::TileLayer');

my $marker = $map->marker(lat=>51.5, lon=>-0.09, popup=>'marker');
diag(Dumper $marker);
isa_ok($marker, 'Geo::Leaflet::Marker');
is(scalar(@{$map->map_objects}), 1, 'sizeof objects');

my $circle = $map->circle(lat=>51.508, lon=>-0.11, radius=>500, options=>{color=>'red', fillColor=>'#f03', fillOpacity=>0.5}, popup=>'circle');
isa_ok($circle, 'Geo::Leaflet::Circle');
is(scalar(@{$map->map_objects}), 2, 'sizeof objects');

my $polygon = $map->polygon(coordinates => [[51.509, -0.08], [51.503, -0.06], [51.51, -0.047]], options=>{}, popup=>'polygon');
isa_ok($polygon, 'Geo::Leaflet::Polygon');
is(scalar(@{$map->map_objects}), 3, 'sizeof objects');

diag(Dumper($map->map_objects));

my $html = $map->html;
diag($html);

#print "\n\n####\n\n";
#print $html;
#print "\n\n####\n\n";
