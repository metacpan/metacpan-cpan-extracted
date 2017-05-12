# -*- perl -*-

use Test::More tests => 11;

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable' ); }

my $document=Geo::GoogleEarth::Pluggable->new;
isa_ok ($document, 'Geo::GoogleEarth::Pluggable');
$document->{"xmlns"}={};
my $point=$document->Point(lat=>38.89767,
                           lon=>-77.03655,
                           Snippet=>["1600 Pennsylvania Avenue NW", "Washington, DC 20500"],
                           name=>"White House");
isa_ok($point, "Geo::GoogleEarth::Pluggable::Contrib::Point", '$document->Point');
isa_ok($point->Snippet, "ARRAY");
is(scalar(@{$point->Snippet}), "2", 'maxLines');

is($document->render, q{<?xml version="1.0" encoding="utf-8"?>
<kml><Document><Snippet maxLines="0"/><Placemark><name>White House</name><Snippet maxLines="2">1600 Pennsylvania Avenue NW
Washington, DC 20500</Snippet><Point><coordinates>-77.03655,38.89767,0</coordinates></Point></Placemark></Document></kml>
}, '$document->render');

isa_ok($point->Snippet("New"), "ARRAY");
isa_ok($point->Snippet, "ARRAY");
is(scalar(@{$point->Snippet}), "1", 'maxLines');
is($point->Snippet->[0], "New", "Value");

is($document->render, q{<?xml version="1.0" encoding="utf-8"?>
<kml><Document><Snippet maxLines="0"/><Placemark><name>White House</name><Snippet maxLines="1">New</Snippet><Point><coordinates>-77.03655,38.89767,0</coordinates></Point></Placemark></Document></kml>
}, '$document->render');

