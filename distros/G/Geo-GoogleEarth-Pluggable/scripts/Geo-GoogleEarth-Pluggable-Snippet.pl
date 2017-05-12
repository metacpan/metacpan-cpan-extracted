#!/usr/bin/perl
use strict;
use warnings;
use Geo::GoogleEarth::Pluggable;

=head1 NAME

Geo-GoogleEarth-Pluggable-Snippet.pl - Geo-GoogleEarth-Pluggable Snippet Example

=cut

my $type=shift || "kml";
my $document=Geo::GoogleEarth::Pluggable->new(name=>"My Document Name", Snippet=>"My Document Snippet");
my $folder=$document->Folder(name=>"My Folder Name", Snippet=>"My Folder Snippet");
my $point=$folder->Point(
                         lat     => 38.89767,
                         lon     => -77.03655,
                         name    => "White House",
                         Snippet => ["1600 Pennsylvania Avenue NW", "Washington, DC 20500"],
                        );

if ($type eq "kmz") {
  print $document->archive;
} else {
  print $document->render;
}
