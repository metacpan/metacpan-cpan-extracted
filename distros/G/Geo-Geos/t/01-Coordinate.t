use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;

subtest "3D-coordinate" => sub {
    my $c = Geo::Geos::Coordinate->new(1,2,3);
    is $c->x, 1;
    is $c->y, 2;
    is $c->z, 3;
    ok !$c->isNull();

    my $c2 = Geo::Geos::Coordinate->new(1,2,3);
    ok $c2->equals($c2);
    ok $c2 eq $c2;
    ok $c2->equals($c);
    ok $c2->equals2D($c);
    ok $c2->equals3D($c);
    ok $c->equals($c2);

    is $c->compareTo($c), 0;
    is $c->distance($c), 0;
    is $c->toString, "1 2 3";

    my $c3 = Geo::Geos::Coordinate->new(1,3,3);
    ok !$c3->equals($c2);
    ok !$c3->equals2D($c2);
    ok !$c3->equals3D($c2);

    ok !$c2->equals($c3);
    ok !$c2->equals2D($c3);
    ok !$c2->equals3D($c3);

    is $c2->compareTo($c3), -1;
    is $c3->compareTo($c2), 1;
    is $c2->distance($c3), 1;
    is $c3->distance($c2), 1;
};

subtest "2D-coordinate" => sub {
    my $c = Geo::Geos::Coordinate->new(1,2);
    is $c->x, 1;
    is $c->y, 2;
    like $c->z, qr/NaN/i;
    ok !$c->isNull();

    my $c2 = Geo::Geos::Coordinate->new(1,2);
    ok $c2->equals($c2);
    ok $c2->equals($c);
    ok $c2->equals2D($c);
    ok $c2->equals3D($c);
    ok $c->equals($c2);

    is $c->compareTo($c), 0;
    is $c->distance($c), 0;
    is $c->toString, "1 2";

    my $c3 = Geo::Geos::Coordinate->new(1,3);
    ok !$c3->equals($c2);
    ok !$c3->equals2D($c2);
    ok !$c3->equals3D($c2);

    ok !$c2->equals($c3);
    ok !$c2->equals2D($c3);
    ok !$c2->equals3D($c3);

    is $c2->compareTo($c3), -1;
    is $c3->compareTo($c2), 1;
    is $c2->distance($c3), 1;
    is $c3->distance($c2), 1;
};

done_testing;
