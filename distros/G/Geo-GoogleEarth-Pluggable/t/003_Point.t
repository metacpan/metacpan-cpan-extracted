# -*- perl -*-

use Test::More tests => 4;

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable' ); }

my $document=Geo::GoogleEarth::Pluggable->new;
isa_ok ($document, 'Geo::GoogleEarth::Pluggable');
$document->{"xmlns"}={};
my $point=$document->Point(lat=> " 38.89767 ",
                           lon=> " -77.03655 ",
                           name=>"White House");
isa_ok($point, "Geo::GoogleEarth::Pluggable::Contrib::Point", '$document->Point');

is($document->render, q{<?xml version="1.0" encoding="utf-8"?>
<kml><Document><Snippet maxLines="0"/><Placemark><name>White House</name><Snippet maxLines="0"/><Point><coordinates>-77.03655,38.89767,0</coordinates></Point></Placemark></Document></kml>
}, '$document->render');
