#!/usr/bin/perl
use strict;
use warnings;
use Geo::GoogleEarth::Pluggable;

=head1 NAME

Geo-GoogleEarth-Pluggable-Folder.pl - Geo-GoogleEarth-Pluggable Folder Example

=cut

my $type=shift || "kml";
my $document=Geo::GoogleEarth::Pluggable->new(name=>"My Document", Snippet=>"The KMZ version is more interesting.");
$document->NetworkLink(name=>"My NetworkLink", url=>"doc.kml", Snippet=>"My Snippet");
#use Data::Dumper qw{Dumper};
#print Dumper($document->structure);

if ($type eq "kmz") {
  print $document->archive;
} else {
  print $document->render;
}
