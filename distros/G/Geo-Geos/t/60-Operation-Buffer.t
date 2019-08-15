use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Geometry qw/TYPE_CAP_ROUND/;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Operation qw/buffer/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "BufferOp::bufferOp" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);

    my $in = $gf->createMultiPoint([$c1, $c2], 2);
    my $out = buffer($in, 1);
    like $out->toString, qr/MULTIPOLYGON/;

    buffer($in, 1, 1)->toString, qr/MULTIPOLYGON/;
    buffer($in, 1, 1, TYPE_CAP_ROUND)->toString, qr/MULTIPOLYGON/;
};

done_testing;
