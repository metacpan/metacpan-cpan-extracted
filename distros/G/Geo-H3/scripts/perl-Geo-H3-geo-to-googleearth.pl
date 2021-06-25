#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw{GetOptions};
use Geo::H3 0.04;
require #hide from rpmbuild
  Geo::GoogleEarth::Pluggable;
require #hide from rpmbuild
  Geo::GoogleEarth::Pluggable::Plugin::Styles;
require #hide from rpmbuild
 Path::Class;

my $lat            =  38.889480654699476;
my $lon            = -77.03523875953579;
my $resoultion     = 8;
my $output         = "output.kmz";
GetOptions(
           'lat=s'              => \$lat,
           'lon=s'              => \$lon,
           'resolution|res|r=s' => \$resoultion,
           'output|out=s'       => \$output,
           );

my $format = $output =~ m/\.kml\Z/i ? "kml" : "kmz";

my $gh3            = Geo::H3->new                    or die("Error: Geo::H3 object could not be constructed");
my $geo            = $gh3->geo(lat=>$lat, lon=>$lon) or die("Error: Geo object could not be constructed");
my $h3             = $geo->h3($resoultion)           or die("Error: H3 object could not be constructed");
my $center         = $h3->geo                        or die("Error: Centroid object could not be constructed");

printf "Lat: %s\n", $lat;
printf "Lon: %s\n", $lon;
printf "Resolution: %s\n", $resoultion;
printf "Output: %s\n", $output;
printf "Format: %s\n", $format;

my $document       = Geo::GoogleEarth::Pluggable->new(name=>"Geo::H3") or die("Error: Geo::GoogleEarth::Pluggable object could not be constructed");
my $style_index    = $document->Style(PolyStyle=>$document->AreaStyleBlue(alpha=>"20%") , LineStyle=>$document->LineStyleBlue(width=>4));
my $style_child    = $document->Style(PolyStyle=>$document->AreaStyleBlack(alpha=>"20%"), LineStyle=>$document->LineStyleBlack(width=>2));
my $style_parent   = $document->Style(PolyStyle=>$document->AreaStyleWhite(alpha=>"20%"), LineStyle=>$document->LineStyleWhite(width=>2));
my $style_hex_ring = $document->Style(PolyStyle=>$document->AreaStyleGreen(alpha=>"20%"), LineStyle=>$document->LineStyleGreen(width=>2));
$document->Point(name=>"Input" , lat=>$lat,         lon=>$lon);
$document->Point(name=>"Center", lat=>$center->lat, lon=>$center->lon);

if ($h3->resolution > 0) {
  my $folder = $document->Folder(name=>"Parent");
  my $parent = $h3->parent;
  $folder->LinearRing(name=>$parent->string, coordinates=>$parent->geoBoundary->coordinates, style=>$style_parent);
}

{
  my $folder = $document->Folder(name=>"Hex Ring");
  foreach my $hex (@{$h3->hexRing}) {
    $folder->LinearRing(name=>$hex->string, coordinates=>$hex->geoBoundary->coordinates, style=>$style_hex_ring);
  }
}

{
  my $folder = $document->Folder(name=>"Children");
  foreach my $child (@{$h3->children}) {
    $folder->LinearRing(name=>$child->string, coordinates=>$child->geoBoundary->coordinates, style=>$style_child);
  }
}

$document->LinearRing(name=>$h3->string, coordinates=>$h3->geoBoundary->coordinates, style=>$style_index);

my $outfile = Path::Class::file($output);
$outfile->spew($format eq "kml" ? $document->render : $document->archive);

__END__

=head1 NAME

perl-Geo-H3-geo-to-googleearth.pl - Creates a Google Earth document from Coordinates, H3, Parent, Children and Hex Ring.

=head1 EXAMPLES

Default creates output.kmz

  $ perl-Geo-H3-geo-to-googleearth.pl
  Lat: 38.8894806546995
  Lon: -77.0352387595358
  Resolution: 8
  Output: output.kmz
  Format: kmz

KMZ output with defaults specified

  $ perl-Geo-H3-geo-to-googleearth.pl --lat=38.889480654699476 --lon=-77.03523875953579 --resolution=8 --output=output.kmz
  Lat: 38.889480654699476
  Lon: -77.03523875953579
  Resolution: 8
  Output: output.kmz
  Format: kmz

KML output pass a file name with "kml" extension.

  $ perl-Geo-H3-geo-to-googleearth.pl --output=output.kml
  Lat: 38.8894806546995
  Lon: -77.0352387595358
  Resolution: 8
  Output: output.kml
  Format: kml

=head1 SEE ALSO

L<Geo::GoogleEarth::Pluggable>, L<Geo::GoogleEarth::Pluggable::Plugin::Styles>, L<Path::Class>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
