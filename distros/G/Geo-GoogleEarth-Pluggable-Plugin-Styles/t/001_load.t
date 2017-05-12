# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 5;

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Plugin::Styles' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable' ); }

my $document=Geo::GoogleEarth::Pluggable->new;
isa_ok($document, 'Geo::GoogleEarth::Pluggable');
isa_ok($document->IconStyleRed, "Geo::GoogleEarth::Pluggable::Style");
isa_ok($document->IconStyleRedDot, "Geo::GoogleEarth::Pluggable::Style");
