#!/usr/bin/perl
use strict;
use warnings;
use Geo::GoogleEarth::Pluggable;

=head1 NAME

Geo-GoogleEarth-Pluggable-MultiPoint.pl - Geo::GoogleEarth::Pluggable MultiPoint Example

=cut

my $type=shift || "kml";
my $document=Geo::GoogleEarth::Pluggable->new(name=>"My Document");

my @point=();
foreach my $lat (39000 .. 39005) {
  foreach my $lon (-77005 .. -77000) {
    push @point, {lat=>$lat/1000, lon=>$lon/1000};
  }
}

$document->MultiPoint(name=>"My Name", coordinates=>\@point);
if ($type eq "kmz") {
  print $document->archive;
} else {
  print $document->render;
}
