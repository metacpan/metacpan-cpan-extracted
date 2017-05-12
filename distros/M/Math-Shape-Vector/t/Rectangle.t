use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Math::Shape::Rectangle' };

# new
ok my $rect1 = Math::Shape::Rectangle->new(1, 1, 2, 4);
ok my $rect2 = Math::Shape::Rectangle->new(1, 1, 10, 10);
ok my $rect3 = Math::Shape::Rectangle->new(1, 4, 1, 1);
ok my $rect4 = Math::Shape::Rectangle->new(5, 100, 10, 10);
is $rect1->{origin}->{x}, 1;
is $rect1->{origin}->{y}, 1;
is $rect1->{size}->{x}, 2;
is $rect1->{size}->{y}, 4;

# collides
is $rect1->collides($rect2), 1;
is $rect1->collides($rect3), 1;
is $rect1->collides($rect4), 0;
is $rect2->collides($rect3), 1;
is $rect2->collides($rect4), 0;
is $rect3->collides($rect4), 0;

# collides vector
use Math::Shape::Vector;
my $v1 = Math::Shape::Vector->new(1, 1);
my $v2 = Math::Shape::Vector->new(1, 6);
is $rect1->collides($v1), 1;
is $rect1->collides($v2), 0;

# collides line
use Math::Shape::Line;
my $l1 = Math::Shape::Line->new(2, 2, 0, 1);
my $l2 = Math::Shape::Line->new(0, 6, 1, 0);
is $rect1->collides($l1), 1;
is $rect1->collides($l2), 0;

# collides LineSegment
use Math::Shape::LineSegment;
my $ls1 = Math::Shape::LineSegment->new(0, 0, 5, 5);
my $ls2 = Math::Shape::LineSegment->new(0, 0, -5, 5);
is $rect1->collides($ls1), 1;
is $rect1->collides($ls2), 0;

# collides OrientedRectangle
use Math::Shape::OrientedRectangle;
my $or1 = Math::Shape::OrientedRectangle->new(2, 2, 1, 2, 90);
my $or2 = Math::Shape::OrientedRectangle->new(4, 0, 8, 1, -90);
is $rect1->collides($or1), 1;
is $rect1->collides($or2), 0;

done_testing();

