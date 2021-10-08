#~ perl

use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok('Geo::GoogleEarth::Pluggable') };
BEGIN { use_ok('Geo::GoogleEarth::Pluggable::Plugin::AsGeoJSON') };

my $json=q[
  {
   "type" : "Point",
   "coordinates" : [ -95.74828, 29.62197 ]
  }
];

diag($json);

my $document=Geo::GoogleEarth::Pluggable->new();
my $object = $document->AsGeoJSON(name=>"point", json=>$json);
my $kml = $document->render;
diag($kml);
like($kml, qr{<Document>}, "Document");
like($kml, qr{<Placemark>}, "Placemark");
like($kml, qr{<name>point</name>}, "name");
like($kml, qr{<coordinates>-95.74828,29.62197,0</coordinates>}, "coordinates");

__END__

<?xml version="1.0" encoding="utf-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:atom="http://www.w3.org/2005/Atom"><Document><Snippet maxLines="0"/><Placemark><name>point</name><Snippet maxLines="0"/><Point><coordinates>-95.74828,29.62197,0</coordinates></Point></Placemark></Document></kml>
