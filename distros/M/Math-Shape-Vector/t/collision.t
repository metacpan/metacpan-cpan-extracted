use strict;
use warnings;
use Math::Shape::Vector;
use Math::Shape::Line;
use Math::Shape::LineSegment;
use Math::Shape::Circle;
use Math::Shape::Rectangle;
use Math::Shape::OrientedRectangle;
use Test::More;

my $v  = Math::Shape::Vector->new(1, 1);
my $l  = Math::Shape::Line->new(1, 1, 0, 0);
my $ls = Math::Shape::LineSegment->new(1, 1, 4, 1);
my $c  = Math::Shape::Circle->new(1, 1, 5);
my $r  = Math::Shape::Rectangle->new(1, 1, 5, 5);
my $or = Math::Shape::OrientedRectangle->new(1, 1, 3, 3, 0);

is $v->collides($v), 1;
is $v->collides($l), 1;
is $v->collides($ls), 1;
is $v->collides($c), 1;
is $v->collides($r), 1;
is $v->collides($or), 1;

is $l->collides($v), 1;
is $l->collides($l), 1;
is $l->collides($ls), 1;
is $l->collides($c), 1;
is $l->collides($r), 1;
is $l->collides($or), 1;

is $ls->collides($v), 1;
is $ls->collides($l), 1;
is $ls->collides($ls), 1;
is $ls->collides($c), 1;
is $ls->collides($r), 1;
is $ls->collides($or), 1;

is $c->collides($v), 1;
is $c->collides($l), 1;
is $c->collides($ls), 1;
is $c->collides($c), 1;
is $c->collides($r), 1;
is $c->collides($or), 1;

is $r->collides($v), 1;
is $r->collides($l), 1;
is $r->collides($ls), 1;
is $r->collides($c), 1;
is $r->collides($r), 1;
is $r->collides($or), 1;

is $or->collides($v), 1;
is $or->collides($l), 1;
is $or->collides($ls), 1;
is $or->collides($c), 1;
is $or->collides($r), 1;
is $or->collides($or), 1;


# test non-collision
$v  = Math::Shape::Vector->new(0, 0);
$l  = Math::Shape::Line->new(0, 1, 1, 0);
$ls = Math::Shape::LineSegment->new(0, 2, 2, 2);
$c  = Math::Shape::Circle->new(0, 5, 2);
$r  = Math::Shape::Rectangle->new(0, 10, 4, 2);
$or = Math::Shape::OrientedRectangle->new(0, 15, 1, 10, 1.57);

is $v->collides($v), 1;
is $v->collides($l), 0;
is $v->collides($ls), 0;
is $v->collides($c), 0;
is $v->collides($r), 0;
is $v->collides($or), 0;

is $l->collides($v), 0;
is $l->collides($l), 1;
is $l->collides($ls), 0;
is $l->collides($c), 0;
is $l->collides($r), 0;
is $l->collides($or), 0;

is $ls->collides($v), 0;
is $ls->collides($l), 0;
is $ls->collides($ls), 1;
is $ls->collides($c), 0;
is $ls->collides($r), 0;
is $ls->collides($or), 0;

is $c->collides($v), 0;
is $c->collides($l), 0;
is $c->collides($ls), 0;
is $c->collides($c), 1;
is $c->collides($r), 0;
is $c->collides($or), 0;

is $r->collides($v), 0;
is $r->collides($l), 0;
is $r->collides($ls), 0;
is $r->collides($c), 0;
is $r->collides($r), 1;
is $r->collides($or), 0;

is $or->collides($v), 0;
is $or->collides($l), 0;
is $or->collides($ls), 0;
is $or->collides($c), 0;
is $or->collides($r), 0;
is $or->collides($or), 1;

done_testing();
