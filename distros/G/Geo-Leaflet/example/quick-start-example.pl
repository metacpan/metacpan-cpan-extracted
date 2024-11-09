#!/usr/bin/perl
use strict;
use warnings;
use Geo::Leaflet;

my $map = Geo::Leaflet->new(center=>[51.505, -0.09], zoom=>13);
$map->marker(lat=>51.5, lon=>-0.09, popup=>'marker');
$map->circle(lat=>51.508, lon=>-0.11, radius=>500, properties=>{color=>'red', fillColor=>'#f03', fillOpacity=>0.5}, popup=>'circle');
$map->polygon(coordinates => [[51.509, -0.08], [51.503, -0.06], [51.51, -0.047]], properties=>{}, popup=>'polygon');
print $map->html;
