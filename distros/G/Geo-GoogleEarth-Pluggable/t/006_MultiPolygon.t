# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable' ); }

my $document=Geo::GoogleEarth::Pluggable->new;
isa_ok ($document, 'Geo::GoogleEarth::Pluggable');
ok(!$document->can("MultiPolygon"), 'Geo::GoogleEarth::Pluggable->cannot("MultiPolygon")');
my $poly=$document->MultiPolygon(
                            name        => "My MultiPolygon",
                            coordinates => [
                                             [
                                               [
                                                 [ -77.03653748373459,38.89168486168970,0 ],
                                                 [ -77.03576261856583,38.89048265593675,0 ],
                                                 [ -77.03441830249675,38.89048262486622,0 ],
                                                 [ -77.03382066054579,38.89099860676128,0 ],
                                                 [ -77.03382049686830,38.89103420260221,0 ],
                                                 [ -77.03393181272598,38.89181802380578,0 ],
                                                 [ -77.03653748373459,38.89168486168907,0 ],
                                               ],
                                             ],
                                             [
                                               [
                                                 [ -77.03681005187295,38.88992462567244,0 ],
                                                 [ -77.03931402803416,38.88987985612900,0 ],
                                                 [ -77.03928168426064,38.88893661754751,0 ],
                                                 [ -77.03668516494257,38.88897638063194,0 ],
                                                 [ -77.03681005187295,38.88992462567244,0 ],
                                               ],
                                             ],
                                           ],
                           );
can_ok($document, "MultiPolygon");
isa_ok($poly, "Geo::GoogleEarth::Pluggable::Contrib::MultiPolygon", '$document->MultiPolygon');

my $xml=$document->render;
diag($xml);

like($xml, qr{<MultiGeometry>}, 'xml has MultiGeometry element');
