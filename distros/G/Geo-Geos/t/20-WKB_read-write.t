use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Geometry;
use Geo::Geos::Coordinate;
use Geo::Geos::GeometryFactory;
use Geo::Geos::PrecisionModel qw/TYPE_FLOATING/;
use Geo::Geos::WKBReader;
use Geo::Geos::WKBWriter;
use Geo::Geos::WKBConstants;

my $pm = Geo::Geos::PrecisionModel->new(TYPE_FLOATING);
my $gf = Geo::Geos::GeometryFactory::create($pm, 3857);

my $c1 = Geo::Geos::Coordinate->new(1,2);
my $c2 = Geo::Geos::Coordinate->new(5,2);
my $c3 = Geo::Geos::Coordinate->new(5,0);
my $c4 = Geo::Geos::Coordinate->new(1,0);

my $lr = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);

my $o = $gf->createPolygon($lr);

subtest "BigEndian byte order, include srid" => sub {
    my $s1 = Geo::Geos::WKBWriter->new(2, TYPE_BYTEORDER_BE, 1)->write($o);
    ok $s1;
    my $g1 = Geo::Geos::WKBReader::read($s1, $gf);
    ok $g1;
    is $g1, $o;
    is $g1->getSRID, $gf->getSRID;
    isa_ok $g1, 'Geo::Geos::Polygon';

    my $s2 = Geo::Geos::WKBWriter->new(2, TYPE_BYTEORDER_BE, 1)->writeHEX($o);
    ok $s2;
    my $g2 = Geo::Geos::WKBReader::readHEX($s2, $gf);
    ok $g2;
    is $g2, $o;
    is $g2->getSRID, $gf->getSRID;
};


subtest "LittleEndian byte order, w/o srid" => sub {
    my $s1 = Geo::Geos::WKBWriter->new(2, TYPE_BYTEORDER_LE, 0)->write($o);
    ok $s1;
    my $g1 = Geo::Geos::WKBReader::read($s1, $gf);
    ok $g1;
    is $g1, $o;
    is $g1->getSRID, 0;

    my $s2 = Geo::Geos::WKBWriter->new(2, TYPE_BYTEORDER_LE, 0)->writeHEX($o);
    ok $s2;
    my $g2 = Geo::Geos::WKBReader::readHEX($s2, $gf);
    ok $g2;
    is $g2, $o;
    is $g2->getSRID, 0;
};

subtest "default GF, default byte order" => sub {
    my $s1 = Geo::Geos::WKBWriter->new(2)->write($o);
    ok $s1;
    my $g1 = Geo::Geos::WKBReader::read($s1);
    ok $g1;
    is $g1, $o;
    is $g1->getSRID, 0;

    my $s2 = Geo::Geos::WKBWriter->new(2)->writeHEX($o);
    ok $s2;
    my $g2 = Geo::Geos::WKBReader::readHEX($s2);
    ok $g2;
    is $g2, $o;
    is $g2->getSRID, 0;
};

ok defined TYPE_WKB_POINT;
ok TYPE_WKB_POINT != TYPE_WKB_POLYGON;

done_testing;
