use strict;
use warnings;
use Test::More;
use Test::Exception;
use Math::Trig ':pi';

BEGIN { use_ok 'Math::Shape::Vector', 'import module' };

# new
ok my $v = Math::Shape::Vector->new(1,2),        'constructor';
ok my $v2 = Math::Shape::Vector->new(1,1),       'constructor';
dies_ok sub { Math::Shape::Vector->new(1) },     'constructor dies on too few args';
dies_ok sub { Math::Shape::Vector->new(1,2,3) }, 'constructor dies on too many args';

# add_vector
ok my $v0 = $v->add_vector($v2), 'add vector';
is $v0->{x}, 2,          'x is now 2';
is $v0->{y}, 3,          'y is now 3';
dies_ok sub { $v->add_vector(1,2) }, 'add vector wrong args';
dies_ok sub { $v->add_vector( {1,2,3,4} ) }, 'add vector wrong args';

# subtract_vector
ok my $v3 = Math::Shape::Vector->new(4,2),        'constructor';
ok my $v4 = Math::Shape::Vector->new(1,1),       'constructor';
ok $v0 = $v3->subtract_vector($v4),   'subtract vector';
is $v0->{x}, 3,                 'x is now 3';
is $v0->{y}, 1,                 'y is now 1';
dies_ok sub { $v3->subtract_vector(1,2) }, 'subtract vector wrong args';
dies_ok sub { $v4->subtract_vector({1, 2}) }, 'subtract vector wrong args';

# is_equal
ok my $v5 = Math::Shape::Vector->new(4,2);
ok my $v6 = Math::Shape::Vector->new(1,1);
ok my $v7 = Math::Shape::Vector->new(1,1);
is $v5->is_equal($v6), 0;
is $v5->is_equal($v7), 0;
is $v6->is_equal($v6), 1;
is $v6->is_equal($v7), 1;
is $v7->is_equal($v6), 1;
dies_ok sub { $v5->is_equal(1,2) }, 'is_equal wrong args';
dies_ok sub { $v5->subtract_vector( {1,2} ) }, 'is_equal wrong args';

# negate
ok my $v8 = Math::Shape::Vector->new(1, 1);
ok my $v9 = Math::Shape::Vector->new(-3,3);
ok $v0 = $v8->negate;
is $v0->{x}, -1, 'x is now -1';
is $v0->{y}, -1, 'y is now -1';
ok $v0 = $v9->negate;
is $v0->{x},  3, 'x is now 3';
is $v0->{y}, -3, 'y is now -3';

# multiply
ok my $v10 = Math::Shape::Vector->new(1, 1);
ok $v0 = $v10->multiply(9);
is $v0->{x}, 9, 'x is now 9';
is $v0->{y}, 9, 'y is now 9';
dies_ok sub { $v10->multiply(1,2,3) }, 'multiply wrong args';

# divide
ok my $v11 = Math::Shape::Vector->new(5, 5);
ok $v0 = $v11->divide(5);
is $v0->{x}, 1, 'x is now 1';
is $v0->{y}, 1, 'y is now 1';
dies_ok sub { $v11->divide(1,3) }, 'divide wrong args';

# length
ok my $v12 = Math::Shape::Vector->new(5, 5);
ok my $v13 = Math::Shape::Vector->new(7, 3);
ok my $v14 = Math::Shape::Vector->new(0, 0);
is sprintf( "%.3f", $v12->length), 7.071;
is sprintf( "%.3f", $v13->length), 7.616;
is $v14->length, 0, 'null vector length is zero';

# convert to unit vector
ok my $v15 = Math::Shape::Vector->new(5, 5);
ok my $v16 = Math::Shape::Vector->new(7, 3);
ok my $v17 = Math::Shape::Vector->new(0, 0);
ok $v0 = $v15->convert_to_unit_vector;
is $v0->length, 1;
ok $v0 = $v16->convert_to_unit_vector;
is $v0->length, 1;
ok $v0 = $v17->convert_to_unit_vector;
is $v0->length, 0;

# rotate
ok my $v18 = Math::Shape::Vector->new(5, 5);
ok my $v19 = Math::Shape::Vector->new(7, 3);
ok my $v20 = Math::Shape::Vector->new(0, 0);
ok $v0 = $v18->rotate(pi);
is $v0->{x}, -5;
ok $v0 = $v19->rotate(pi2);
is $v0->{x}, 7;
ok $v0 = $v20->rotate(0);
is $v0->{x}, 0;

# dot_product
ok my $v21 = Math::Shape::Vector->new(8, 2);
ok my $v22 = Math::Shape::Vector->new(-2, 8);
ok my $v23 = Math::Shape::Vector->new(-5, 5);
   # this is the dot product formula
is $v21->{x} * $v22->{x} + $v21->{y} * $v22->{y}, $v21->dot_product($v22);
is $v22->{x} * $v23->{x} + $v22->{y} * $v23->{y}, $v22->dot_product($v23);
is $v23->{x} * $v21->{x} + $v23->{y} * $v21->{y}, $v23->dot_product($v21);

# project
ok my $v24 = Math::Shape::Vector->new(8, 2);
ok my $v25 = Math::Shape::Vector->new(-2, 8);
ok my $v26 = Math::Shape::Vector->new(-2, 8);
is $v24->project($v25)->{x}, 0;
is $v25->project($v26)->{x}, -2;

# rotate_90
ok my $v30 = Math::Shape::Vector->new(3, 8);
ok $v0 = $v30->rotate_90;
is $v0->{x}, -8;
is $v0->{y}, 3;

# collides vector
ok my $v27 = Math::Shape::Vector->new(8, 2);
ok my $v28 = Math::Shape::Vector->new(-2, 8);
ok my $v29 = Math::Shape::Vector->new(-2, 8);
is $v27->collides($v28), 0;
is $v28->collides($v29), 1;
is $v29->collides($v27), 0;

# collides LineSegment
use Math::Shape::LineSegment;
my $ls1 = Math::Shape::LineSegment->new(8, 2, 20, 4);
my $ls2 = Math::Shape::LineSegment->new(2, 2, 8, 3);
is $v27->collides($ls1), 1;
is $v27->collides($ls2), 0;

# collides OrientedRectangle
use Math::Shape::OrientedRectangle;
my $or1 = Math::Shape::OrientedRectangle->new(5, 2, 4, 4, 0);
my $or2 = Math::Shape::OrientedRectangle->new(5, 2, 2, 4, 0);
is $v27->collides($or1), 1;
is $v27->collides($or2), 0;

# distance
is  $v->distance($v6), 1;
is $v6->distance($v7), 0;
is $v7->distance($v6), 0;

use Math::Shape::Circle;
my $c = Math::Shape::Circle->new(1, 10, 3);
is $v6->distance($c), 6;

# enclosed angle
my $v31 = Math::Shape::Vector->new(8, 2);
my $v32 = Math::Shape::Vector->new(-2,8);
my $v33 = Math::Shape::Vector->new(-8,-2);
my $v34 = Math::Shape::Vector->new(2,-8);
is $v31->enclosed_angle($v32), pip2;
is $v31->enclosed_angle($v33), pi;
is $v31->enclosed_angle($v34), pip2;
is $v31->enclosed_angle($v34), pip2;

# radians
my $v35 = Math::Shape::Vector->new(0,0);
my $v36 = Math::Shape::Vector->new(1,1);
my $v37 = Math::Shape::Vector->new(1,0);
my $v38 = Math::Shape::Vector->new(0,-1);
my $v39 = Math::Shape::Vector->new(-1,-1);
my $v40 = Math::Shape::Vector->new(-1,0);
is $v35->radians, 0;
is $v36->radians, pip4;
is $v37->radians, pip2;
is $v38->radians, pi;
is $v39->radians, pi + pip4;
is $v40->radians, pi + pip2;

# header_vector
my $v41 = Math::Shape::Vector->new(0,0);
my $v42 = Math::Shape::Vector->new(10,0);
my $v43 = Math::Shape::Vector->new(-2,-2);
my $v44 = Math::Shape::Vector->new(0,-3);
my $v45 = Math::Shape::Vector->new(-100,-200);
is $v41->header_vector($v42)->{x}, 1;
cmp_ok sprintf("%.10f", $v41->header_vector($v43)->{y}),
  '==', -0.7071067812;
is $v41->header_vector($v44)->{x}, 0;
cmp_ok sprintf("%.10f", $v41->header_vector($v45)->{y}),
  '==', -0.8944271910;

# stringify, method and context
my $v46 = Math::Shape::Vector->new(0,0);
my $v47 = Math::Shape::Vector->new(-1,750);
is $v46->stringify, 'Vector x: 0, y: 0';
is sprintf('%s', $v47), 'Vector x: -1, y: 750';


done_testing();
