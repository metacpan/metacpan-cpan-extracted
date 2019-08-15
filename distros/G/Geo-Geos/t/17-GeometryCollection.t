use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::GeometryFactory;
use Geo::Geos::Dimension;
use Geo::Geos::Geometry qw/TYPE_GEOS_GEOMETRYCOLLECTION/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "empty" => sub {
    my $obj = $gf->createGeometryCollection;
    ok $obj;
    is $obj->getNumPoints, 0;
    is $obj->getDimension, TYPE_False;
    is $obj->getCoordinateDimension, 2;
    is $obj->getBoundaryDimension, -1;
    is $obj->getCoordinate, undef;
    is $obj->getGeometryType, "GeometryCollection";
    is $obj->getGeometryTypeId, TYPE_GEOS_GEOMETRYCOLLECTION;
    ok $obj->isa('Geo::Geos::Geometry');
    ok $obj->isa('Geo::Geos::GeometryCollection');
    ok $obj->isEmpty;
};

done_testing;
