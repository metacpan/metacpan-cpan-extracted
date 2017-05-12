# -*- perl -*-

use Test::More tests => 3;

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable' ); }

my $document=Geo::GoogleEarth::Pluggable->new;
isa_ok ($document, 'Geo::GoogleEarth::Pluggable');
$document->{"xmlns"}={};
is($document->render, q{<?xml version="1.0" encoding="utf-8"?>
<kml><Document><Snippet maxLines="0"/></Document></kml>
}, '$document->render');
