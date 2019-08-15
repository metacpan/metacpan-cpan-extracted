use 5.012;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Fatal;

use Geo::Geos::Coordinate;
use Geo::Geos::Envelope;

subtest "null ctor" => sub {
    my $e = Geo::Geos::Envelope->new;
    ok $e;
    ok $e->isNull;
};

subtest "4-doubles ctor, toString, eq" => sub {
    my $e = Geo::Geos::Envelope->new(1, 2, 3, 4);
    ok $e;
    ok !$e->isNull;
    is $e->toString, "Env[1:2,3:4]";
    is $e, Geo::Geos::Envelope->new(1, 2, 3, 4);
    isnt $e, Geo::Geos::Envelope->new(1, 2, 3, 5);
};

subtest "2-coordinates ctor, hashCode, string c-tor" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,3);
    my $c2 = Geo::Geos::Coordinate->new(2,4);
    my $e = Geo::Geos::Envelope->new($c1, $c2);
    ok $e;
    ok !$e->isNull;
    isnt $e->hashCode, 0;

    my $e2 = Geo::Geos::Envelope->new($e->toString);
    is $e, $e2;
    like exception { Geo::Geos::Envelope->new($c1, undef) }, qr/undef not allowed/;

};

subtest "1-coordinate ctor" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,3);
    my $e = Geo::Geos::Envelope->new($c1);
    ok $e;
    ok !$e->isNull;
    is $e->getArea(), 0;
    is $e->centre, $c1;
};



subtest "init, setToNull" => sub {
    my $e = Geo::Geos::Envelope->new(1, 2, 3, 4);
    my $c1 = Geo::Geos::Coordinate->new(2,3);
    my $c2 = Geo::Geos::Coordinate->new(3,4);

    $e->init;

    ok $e->isNull;
    $e->init($c1, $c2);
    ok !$e->isNull;

    $e->init;
    $e->init(1, 2, 3, 4);
    ok !$e->isNull;

    $e->init;
    $e->init($c1);
    ok !$e->isNull;

    $e->setToNull;
    ok $e->isNull;
};

subtest "get*" => sub {
    my $e = Geo::Geos::Envelope->new(1, 2, 5, 10);
    is $e->getArea(), 1 * 5;
    is $e->getMinX, 1;
    is $e->getMinY, 5;
    is $e->getMaxX, 2;
    is $e->getMaxY, 10;
    is $e->getWidth, 1;
    is $e->getHeight, 5;
};

subtest "contains, covers, intersects, distance" => sub {
    my $e1 = Geo::Geos::Envelope->new(0, 6, 0, 6);
    my $e2 = Geo::Geos::Envelope->new(1, 2, 1, 2);
    my $e3 = Geo::Geos::Envelope->new(0, 6, 7, 9);
    my $c1 = Geo::Geos::Coordinate->new(1,3);

    is $e1->distance($e3), 1;

    subtest "contains" => sub {
        ok $e1->contains($e1);

        ok $e1->contains($e2);
        ok !$e2->contains($e1);

        ok $e1->contains($c1);
        ok !$e2->contains($c1);

        ok $e1->contains(1, 3);
        ok !$e2->contains(1, 3);
    };

    subtest "covers" => sub {
        ok $e1->covers($e1);

        ok $e1->covers($e2);
        ok !$e2->covers($e1);

        ok $e1->covers($c1);
        ok !$e2->covers($c1);

        ok $e1->covers(1, 3);
        ok !$e2->covers(1, 3);
    };

    subtest "intersects (object method)" => sub {
        ok $e1->intersects($e1);

        ok $e1->intersects($e2);
        ok $e2->intersects($e1);

        ok $e1->intersects($c1);
        ok !$e2->intersects($c1);

        ok $e1->intersects(1, 3);
        ok !$e2->intersects(1, 3);
    };

    subtest "intersects (class method)" => sub {
        my $c1 = Geo::Geos::Coordinate->new(0,0);
        my $c2 = Geo::Geos::Coordinate->new(3,3);

        my $q1 = Geo::Geos::Coordinate->new(1,1);
        my $q2 = Geo::Geos::Coordinate->new(5,5);
        my $q3 = Geo::Geos::Coordinate->new(6,6);

        ok Geo::Geos::Envelope::intersects($c1, $c2, $q1);
        ok !Geo::Geos::Envelope::intersects($c1, $c2, $q2);

        ok Geo::Geos::Envelope::intersects($c1, $c2, $q1, $q2);
        ok !Geo::Geos::Envelope::intersects($c1, $c2, $q2, $q3);
    };
};

subtest "translate, expandBy" => sub {
    my $e1 = Geo::Geos::Envelope->new(0, 1, 0, 1);
    my $e2 = Geo::Geos::Envelope->new(1, 2, 1, 2);
    my $e3 = Geo::Geos::Envelope->new(0, 3, 0, 3);

    $e1->translate(1,1);
    is $e1, $e2;

    $e1->expandBy(1,1);
    is $e1, $e3;
};

subtest "expandToInclude" => sub {
    my $e1 = Geo::Geos::Envelope->new(0, 1, 0, 1);
    my $e2 = Geo::Geos::Envelope->new(0, 2, 0, 2);
    my $e3 = Geo::Geos::Envelope->new(0, 3, 0, 3);
    my $e4 = Geo::Geos::Envelope->new(3, 4, 3, 4);
    my $e5 = Geo::Geos::Envelope->new(0, 4, 0, 4);
    my $c1 = Geo::Geos::Coordinate->new(3,3);

    $e1->expandToInclude(2,2);
    is $e1, $e2;

    $e1->expandToInclude($c1);
    is $e1, $e3;

    $e1->expandToInclude($e4);
    is $e1, $e5;
};

subtest "intersection" => sub {
    my $e1 = Geo::Geos::Envelope->new(0, 2, 0, 2);
    my $e2 = Geo::Geos::Envelope->new(1, 3, 1, 3);
    my $e3 = Geo::Geos::Envelope->new(1, 2, 1, 2);
    my $e4 = $e1->intersection($e2);
    is $e4, $e3;
};

done_testing;
