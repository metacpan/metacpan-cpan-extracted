#~ perl

use strict;
use warnings;
use Test::More tests => 5;
BEGIN { use_ok('Geo::GoogleEarth::Pluggable') };
BEGIN { use_ok('Geo::GoogleEarth::Pluggable::Plugin::AsGeoJSON') };

my $document=Geo::GoogleEarth::Pluggable->new();
isa_ok($document, "Geo::GoogleEarth::Pluggable");
ok(!$document->can("AsGeoJSON"), 'Geo::GoogleEarth::Pluggable->cannot("AsGeoJSON") yet');
my $object=eval{$document->AsGeoJSON}; #loads AsGeoJSON method into Geo::GoogleEarth::Pluggable object but it does error out
can_ok($document, "AsGeoJSON");
