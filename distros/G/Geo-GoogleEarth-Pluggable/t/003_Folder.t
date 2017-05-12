# -*- perl -*-

use Test::More tests => 4;

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable' ); }

my $document=Geo::GoogleEarth::Pluggable->new;
isa_ok ($document, 'Geo::GoogleEarth::Pluggable');
$document->{"xmlns"}={};
my $point=$document->Folder(name=>"White House");
isa_ok($point, "Geo::GoogleEarth::Pluggable::Folder", '$document->Folder');

is($document->render, q{<?xml version="1.0" encoding="utf-8"?>
<kml><Document><Snippet maxLines="0"/><Folder><name>White House</name><Snippet maxLines="0"/></Folder></Document></kml>
}, '$document->render');

