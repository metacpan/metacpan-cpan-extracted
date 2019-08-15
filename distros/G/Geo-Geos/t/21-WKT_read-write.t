use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Geometry;
use Geo::Geos::Coordinate;
use Geo::Geos::GeometryFactory;
use Geo::Geos::PrecisionModel qw/TYPE_FLOATING/;
use Geo::Geos::WKTReader;
use Geo::Geos::WKTWriter;

my $pm = Geo::Geos::PrecisionModel->new(TYPE_FLOATING);
my $gf = Geo::Geos::GeometryFactory::create($pm, 3857);

my $c1 = Geo::Geos::Coordinate->new(1,2);
my $c2 = Geo::Geos::Coordinate->new(5,2);
my $c3 = Geo::Geos::Coordinate->new(5,0);
my $c4 = Geo::Geos::Coordinate->new(1,0);

my $lr = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);

my $o = $gf->createPolygon($lr);

subtest "with factory, defaults" => sub {
    my $s1 = Geo::Geos::WKTWriter->new->write($o);
    ok $s1;
    my $g1 = Geo::Geos::WKTReader::read($s1, $gf);
    ok $g1;
    is $g1, $o;
    is $g1->getSRID, $gf->getSRID;
};

subtest "without factory, defaults" => sub {
    my $s1 = Geo::Geos::WKTWriter->new->write($o);
    ok $s1;
    my $g1 = Geo::Geos::WKTReader::read($s1);
    ok $g1;
    is $g1, $o;
    is $g1->getSRID, 0;
};

done_testing;
