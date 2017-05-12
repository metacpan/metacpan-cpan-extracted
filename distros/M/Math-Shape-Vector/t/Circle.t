use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Math::Shape::Circle' };

# new
ok my $circle1 = Math::Shape::Circle->new(1, 1, 54), 'constructor';
ok my $circle2 = Math::Shape::Circle->new(1, 1, 10), 'constructor';
ok my $circle3 = Math::Shape::Circle->new(1, 54, 20), 'constructor';
ok my $circle4 = Math::Shape::Circle->new(60, 100, 5), 'constructor';
is $circle1->{center}->{x}, 1;
is $circle1->{center}->{y}, 1;
is $circle1->{radius}, 54;

# collides circle
is $circle1->collides($circle2), 1;
is $circle1->collides($circle3), 1;
is $circle1->collides($circle4), 0;
is $circle2->collides($circle3), 0;
is $circle2->collides($circle4), 0;
is $circle3->collides($circle4), 0;

# collides vector
use Math::Shape::Vector;
my $vector1 = Math::Shape::Vector->new( 1, 30);
my $vector2 = Math::Shape::Vector->new(30,  1);
my $vector3 = Math::Shape::Vector->new( 1, 56);
is $circle1->collides($vector1), 1;
is $circle1->collides($vector2), 1;
is $circle1->collides($vector3), 0;

# collides line
use Math::Shape::Line;
my $line1 = Math::Shape::Line->new(1, 2, 1, 0);
my $line2 = Math::Shape::Line->new(0, 30, 1, 30);
my $line3 = Math::Shape::Line->new(1, 60, 0, 0);
is $circle1->collides($line1), 1;
is $circle1->collides($line2), 1;
is $circle1->collides($line3), 0;

# collides LineSegment
use Math::Shape::LineSegment;
my $ls1 = Math::Shape::LineSegment->new(1,1, 60, 1);
my $ls2 = Math::Shape::LineSegment->new(1,-80, 1, 80);
my $ls3 = Math::Shape::LineSegment->new(0,60, 60, 60);
is $circle1->collides($ls1), 1;
is $circle1->collides($ls2), 1;
is $circle1->collides($ls3), 0;

# collides rectangle
use Math::Shape::Rectangle;
my $r1 = Math::Shape::Rectangle->new(1, 1, 5, 10);
my $r2 = Math::Shape::Rectangle->new(-56, 1, 2, 2);
is $circle1->collides($r1), 1;
is $circle1->collides($r2), 0;

# collides OrientedRectangle
use Math::Shape::OrientedRectangle;
my $or1 = Math::Shape::OrientedRectangle->new(1, 5, 10, 8, 45);
my $or2 = Math::Shape::OrientedRectangle->new(60, 1, 2, 2, 90);
is $circle1->collides($or1), 1;
is $circle1->collides($or2), 0;

done_testing();

