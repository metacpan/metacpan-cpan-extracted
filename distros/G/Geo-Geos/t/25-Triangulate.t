use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Triangulate::DelaunayTriangulationBuilder;
use Geo::Geos::Triangulate::VoronoiDiagramBuilder;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "delaunay / poly" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);

    my $lr = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);
    my $p  = $gf->createPolygon($lr);

    my $delaunay = Geo::Geos::Triangulate::DelaunayTriangulationBuilder->new($gf, $p);
    ok $delaunay;

    my $edges = $delaunay->getEdges;
    ok $edges;
    like $edges->toString, qr/MULTILINESTRING/;

    my $coll = $delaunay->getTriangles;
    is $coll->getNumGeometries, 2;
    like $coll->getGeometryN(0)->toString, qr/POLYGON/;
    like $coll->getGeometryN(1)->toString, qr/POLYGON/;
};

subtest "delaunay / coords" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);

    my $coords = [$c1, $c2, $c3, $c4, $c1];

    my $delaunay = Geo::Geos::Triangulate::DelaunayTriangulationBuilder->new($gf, $coords, 0);
    ok $delaunay;

    my $edges = $delaunay->getEdges;
    ok $edges;
    like $edges->toString, qr/MULTILINESTRING/;

    my $coll = $delaunay->getTriangles;
    is $coll->getNumGeometries, 2;
    like $coll->getGeometryN(0)->toString, qr/POLYGON/;
    like $coll->getGeometryN(1)->toString, qr/POLYGON/;
};

subtest "voronoj / coords" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);

    my $coords = [$c1, $c2, $c3, $c4, $c1];

    my $env = Geo::Geos::Envelope->new(
        Geo::Geos::Coordinate->new(0,0),
        Geo::Geos::Coordinate->new(6,6),
    );

    my $voronoj = Geo::Geos::Triangulate::VoronoiDiagramBuilder->new($gf, $coords, 0, $env);
    ok $voronoj;

    like $voronoj->getDiagramEdges->toString, qr/MULTILINESTRING/;
    like $voronoj->getDiagram->toString, qr/GEOMETRYCOLLECTION/;
};

done_testing;
