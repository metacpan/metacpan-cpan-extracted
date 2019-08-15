use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Triangle qw/isInCircleNonRobust isInCircleNormalized isInCircleRobust/;

my $c1 = Geo::Geos::Coordinate->new(0, 0);
my $c2 = Geo::Geos::Coordinate->new(0, 2);
my $c3 = Geo::Geos::Coordinate->new(1, 1);
my $c4 = Geo::Geos::Coordinate->new(0.5, 0.5);

subtest "Triangle" => sub {
    my $t = Geo::Geos::Triangle->new($c1, $c2, $c3);
    ok $t;
    is $t->p0, $c1;
    is $t->p1, $c2;
    is $t->p2, $c3;

    is $t->inCentre->toString, '0.41421356237309509 1';
    is $t->circumcentre->toString, '0 1';
};

subtest "TrianglePredicate" => sub {
    ok !isInCircleNonRobust($c1, $c2, $c3, $c4);
    ok !isInCircleNormalized($c1, $c2, $c3, $c4);
    ok !isInCircleRobust($c1, $c2, $c3, $c4);
};

done_testing;

