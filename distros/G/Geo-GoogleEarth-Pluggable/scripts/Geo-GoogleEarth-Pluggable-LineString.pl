#!/usr/bin/perl
use strict;
use warnings;
use Geo::GoogleEarth::Pluggable;

=head1 NAME

Geo-GoogleEarth-Pluggable-LineString.pl - Geo::GoogleEarth::Pluggable LineString Example

=cut

my $type=shift || "kml";
my $document=Geo::GoogleEarth::Pluggable->new(name=>"My Document");
my @pt=(
         {lat=>38.1, lon=>-77.1},
         {lat=>38.2, lon=>-77.2},
         {lat=>38.3, lon=>-77.2},
         {lat=>38.4, lon=>-77.1},
       );

$document->LineString(name=>"My LineString", coordinates=>\@pt);
#use Data::Dumper qw{Dumper};
#print Dumper($document->structure);
if ($type eq "kmz") {
  print $document->archive;
} else {
  print $document->render;
}
