#!/usr/bin/perl
use strict;
use warnings;
use Geo::Leaflet;

my $map = Geo::Leaflet->new(center=>[51.505, -0.09], zoom=>13, width=>'100%', height=>'100%');

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

my $divIcon = $map->divIcon(
               icon_name => "bicycle", #defaults icon_set = fa, icon_size = 48, iconAnchor ~ [middle]
               );

$map->marker(  lat         => 51.498,
               lon         => -0.12,
               popup       => 'marker divIcon popup', 
               tooltip     => "marker divIcon tooltip",
               options     => {
                               icon => $divIcon->name,
                              },
               );

my $icon_map_marker = $map->divIcon(
               icon_name      => "map-marker", #defaults icon_set = fa, icon_size = 48, iconAnchor ~ [middle]
               icon_font_size => 48,
               options        => { 
                                  iconAnchor => [13,44], #bottom center (I'm not sure "why" it is not 24/48)
                                 },
               );

$map->marker(  lat         => 51.498,
               lon         => -0.105,
               popup       => 'icon_map_marker',
               tooltip     => "icon_map_marker",
               options     => {
                               icon => $icon_map_marker->name,
                              },
               );

my $icon_dot_circle = $map->divIcon(
               icon_name      => "dot-circle-o",
               icon_font_size => 28,
               options        => {
                                  iconAnchor => [12,14], #center (I'm not sure "why" it is not half)
                                 },
               );

$map->marker(  lat         => 51.498,
               lon         => -0.11,
               popup       => 'icon_dot_circle',
               tooltip     => "icon_dot_circle",
               options     => {
                               icon => $icon_dot_circle->name,
                              },
               );

my $icon_fa_defaults = $map->divIcon(icon_name => "bicycle");


$map->marker(  lat         => 51.49,
               lon         => -0.11,
               tooltip     => "icon_fa_defaults",
               options     => {
                               icon => $icon_fa_defaults->name,
                              },
               );


my $icon_fa_tweaked = $map->divIcon(
                           icon_name      => "bicycle",
                           icon_font_size => 22,
                           options => {
                                       iconAnchor => [11,11],
                                      },
                          );

$map->marker(  lat         => 51.49,
               lon         => -0.10,
               tooltip     => "icon_fa_tweaked",
               options     => {
                               icon => $icon_fa_tweaked->name,
                              },
               );


my $icon_options_html = $map->divIcon(
                        options => {
                                    html  => '<i class="fa fa-map-marker", style="font-size:48px"></i>',
                                    iconAnchor => [13, 44],
                                   }
                       );


$map->marker(  lat         => 51.49,
               lon         => -0.09,
               tooltip     => "icon_options_html",
               options     => {
                               icon => $icon_options_html->name,
                              },
               );


print $map->html;
