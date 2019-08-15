use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Envelope;
use Geo::Geos::PrecisionModel qw/TYPE_FLOATING_SINGLE/;
use Geo::Geos::GeometryFactory qw/create/;

my $gf1 = create();
ok $gf1;

my $pm = Geo::Geos::PrecisionModel->new(TYPE_FLOATING_SINGLE);
my $gf2 = create($pm);
ok $gf2;
is $gf2->getPrecisionModel->getType, TYPE_FLOATING_SINGLE;

my $gf3 = create($pm, 3857);
ok $gf3;
is $gf3->getSRID, 3857;

my $e = Geo::Geos::Envelope->new(1, 2, 3, 4);
my $g = $gf1->toGeometry($e);
ok $g;
is $g->toString, 'POLYGON ((1.0000000000000000 3.0000000000000000, 2.0000000000000000 3.0000000000000000, 2.0000000000000000 4.0000000000000000, 1.0000000000000000 4.0000000000000000, 1.0000000000000000 3.0000000000000000))';

my $g2 = $gf1->createEmptyGeometry;
ok $g2;
is $g2->toString, "GEOMETRYCOLLECTION EMPTY";

done_testing;
