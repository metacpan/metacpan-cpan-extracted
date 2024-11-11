#!/usr/bin/perl
use strict;
use warnings;
use Geo::Leaflet;

my $map = Geo::Leaflet->new(center=>[51.505, -0.09], zoom=>13);

$map->marker(  lat         => 51.5,
               lon         => -0.09,
               popup       => 'marker popup', 
               tooltip     => "marker tooltip");

$map->circle(  lat         => 51.508,
               lon         => -0.11,
               radius      => 500,
               options     => {color=>'red', fillColor=>'#f03', fillOpacity=>0.5},
               popup       => 'circle popup',
               tooltip     => 'circle tooltip');

$map->polygon( coordinates => [[51.509, -0.08], [51.503, -0.06], [51.51, -0.047]],
               options     => {color=>"blue"},
               popup       => 'polygon popup',
               tooltip     => 'polygon tooltip');

$map->polyline(coordinates => [[51.508, -0.08], [51.502, -0.06], [51.50, -0.047]],
               options     => {color=>"green"},
               popup       => 'polyline popup',
               tooltip     => 'polyline tooltip');

$map->rectangle(llat       => 51.496,
                llon       => -0.08,
                ulat       => 51.500,
                ulon       => -0.047,
                options    => {color=>"orange"},
                popup      => 'rectangle popup',
                tooltip    => 'rectangle tooltip');

my $icon = $map->icon(
                      name    => "paddle_1",
                      options => {
                                  iconUrl       => 'https://maps.google.com/mapfiles/kml/paddle/1.png',
                                  iconSize      => [64, 64],
                                  iconAnchor    => [32, 64],
                                  popupAnchor   => [0, -48],
                                  tooltipAnchor => [0,-48],
                                 },
                     );

$map->marker(  lat         => 51.498,
               lon         => -0.10,
               popup       => 'marker icon popup', 
               tooltip     => "marker icon tooltip",
               options     => {
                               icon => $icon->name,
                              },
               );


print $map->html;
