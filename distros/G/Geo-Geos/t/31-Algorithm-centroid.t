use 5.012;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Fatal;

use Geo::Geos::Coordinate;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Algorithm qw/centroid centroidArea centroidLine centroidPoint/;

subtest "Centroid" => sub {
    my $gf = Geo::Geos::GeometryFactory::create();
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);

    subtest "centroid()" => sub {
        my $c1 = Geo::Geos::Coordinate->new(1,1);
        my $c2 = Geo::Geos::Coordinate->new(9,1);

        my $l1 = $gf->createLineString([$c1, $c2], 2);
        my $cc1 = centroid($l1);
        ok $cc1;
        is $cc1, Geo::Geos::Coordinate->new(5,1);

        my $g_empty = $l1->difference($l1);
        my $cc2 = centroid($g_empty);
        ok !$cc2;
    };

    subtest "centroid_area()" => sub {
        my $c1 = Geo::Geos::Coordinate->new(1,2);
        my $c2 = Geo::Geos::Coordinate->new(5,2);
        my $c3 = Geo::Geos::Coordinate->new(5,0);
        my $c4 = Geo::Geos::Coordinate->new(1,0);

        my $lr = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);
        my $p = $gf->createPolygon($lr);

        my $cc2 = centroidArea([[$c1, $c2, $c3, $c4, $c1]]);
        ok $cc2;

        my $cc1 = centroidArea([$p]);
        ok $cc1;

        is $cc1, $cc2;
        is $cc1->toString, "3 1";

        is centroidArea([]), undef;
    };

    subtest "centroid_line()" => sub {
        my $c1 = Geo::Geos::Coordinate->new(1,2);
        my $c2 = Geo::Geos::Coordinate->new(5,2);

        my $l = $gf->createLineString([$c1, $c2], 2);

        my $cc1 = centroidLine([$l]);
        ok $cc1;

        is $cc1->toString, "3 2";

        is centroidLine([]), undef;
    };

    subtest "centroid_point()" => sub {
        my $c1 = Geo::Geos::Coordinate->new(1,2);
        my $c2 = Geo::Geos::Coordinate->new(5,2);

        my $p1 = $gf->createPoint($c1);
        my $p2 = $gf->createPoint($c2);

        my $cc1 = centroidPoint([$p1, $p2]);
        ok $cc1;
        like exception { centroidPoint([$p1, undef]); }, qr/invalid argumen/;


        is $cc1->toString, "3 2";

        is centroidPoint([]), undef;
    };
};

done_testing;
