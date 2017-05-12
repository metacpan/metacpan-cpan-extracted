use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Math::Shape::OrientedRectangle' };

# new
ok my $rect1 = Math::Shape::OrientedRectangle->new(1, 1, 2, 4, 3.14), 'constructor';
is $rect1->{center}->{x}, 1;
is $rect1->{center}->{y}, 1;
is $rect1->{half_extend}->{x}, 2;
is $rect1->{half_extend}->{y}, 4;
is $rect1->{rotation}, 3.14;

ok my $rect2 = Math::Shape::OrientedRectangle->new(3, 5, 1, 3, 15), 'constructor';
ok my $rect3 = Math::Shape::OrientedRectangle->new(10, 5, 2, 2, -15), 'constructor';
ok my $rect4 = Math::Shape::OrientedRectangle->new(9, 4, 10, 8, -15), 'constructor';

# get_edge
ok $rect1->get_edge(0);
ok $rect1->get_edge(1);
ok $rect1->get_edge(2);
ok my $edge = $rect1->get_edge(3);
ok $edge->isa('Math::Shape::LineSegment');

# collides
is $rect1->collides($rect2), 1;
is $rect2->collides($rect3), 0;
is $rect3->collides($rect4), 1;

# collides LineSegment
use Math::Shape::LineSegment;
my $ls1 = Math::Shape::LineSegment->new(0, 0, 10, 10);
my $ls2 = Math::Shape::LineSegment->new(7, 1, 5, 13);
is $rect1->collides($ls1), 1;
is $rect1->collides($ls2), 0;

# get circle hull
ok my $circle = $rect1->circle_hull;
is $rect1->{center}->{x}, $circle->{center}->{x};
is $rect1->{center}->{y}, $circle->{center}->{y};

done_testing();

