#!/usr/bin/perl
use strict;
use warnings;
use Geo::GoogleEarth::Pluggable;

=head1 NAME

Geo-GoogleEarth-Pluggable-Point-StyleMapIcon.pl - Geo-GoogleEarth-Pluggable Icon StyleMap Example

=cut

my $type=shift || "kml";

my $document=Geo::GoogleEarth::Pluggable->new(name=>"StyleMap Example");

my $style1=$document->IconStyle(
               color   => {red=>0, green=>0, blue=>192},
               href    => "http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png",
                                );

my $style2=$document->IconStyle(
               color   => {red=>0, green=>192, blue=>0},
               href    => "http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png",
                                );

my $stylemap=$document->StyleMap(normal=>$style1, highlight=>$style2);

$document->Point(
             name  => "Style1 Point",
             lat   =>  38.893873,
             lon   => -77.037579,
             style => $style1,
           );

$document->Point(
             name  => "StyleMap Point",
             lat   =>  38.893873,
             lon   => -77.036579,
             style => $stylemap,
           );

$document->Point(
             name  => "Style2 Point",
             lat   =>  38.893873,
             lon   => -77.035579,
             style => $style2,
           );

if ($type eq "kmz") {
  print $document->archive;
} else {
  print $document->render;
}

