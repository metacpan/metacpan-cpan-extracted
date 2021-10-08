# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable' ); }

my $document=Geo::GoogleEarth::Pluggable->new;
isa_ok ($document, 'Geo::GoogleEarth::Pluggable');
ok(!$document->can("Polygon"), 'Geo::GoogleEarth::Pluggable->cannot("Polygon")');
my $poly=$document->Polygon(
                            name        => "My Polygon",
                            coordinates => [
                                             [
                                               [ -77.05850989868624,38.87005419296352,0 ],
                                               [ -77.05556478330676,38.86887203313995,0 ],
                                               [ -77.05324817642971,38.87060535534778,0 ],
                                               [ -77.05467928811530,38.87289088304318,0 ],
                                               [ -77.05788754338148,38.87255166603090,0 ],
                                               [ -77.05850989868624,38.87005419296352,0 ],
                                             ],
                                             [
                                               [ -77.05672359788534,38.87161350448313,0 ],
                                               [ -77.05690397766423,38.87065618430430,0 ],
                                               [ -77.05580255797341,38.87019457781144,0 ],
                                               [ -77.05492001633019,38.87088147519474,0 ],
                                               [ -77.05548840804771,38.87175348954395,0 ],
                                               [ -77.05672359788534,38.87161350448313,0 ],
                                             ]
                                           ],
                           );
can_ok($document, "Polygon");
isa_ok($poly, "Geo::GoogleEarth::Pluggable::Contrib::Polygon", '$document->Polygon');

my $xml=$document->render;
diag($xml);

like($xml, qr{<Polygon>}, 'xml has Polygon element');
