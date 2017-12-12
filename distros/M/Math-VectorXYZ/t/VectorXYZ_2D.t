#!perl -T
use 5.006;
use warnings;
use strict;
use Math::VectorXYZ::2D;
use Test::More;

plan tests => 15;

my $v1 = Vec(1,2);
my $v2 = Math::VectorXYZ::2D->new(4,5);

is( $v2 + $v1, Vec(5,7),      "Addition" );
is( $v2 - $v1, Vec(3,3),      "Subtraction" );

is( 2 * $v1, Vec(2,4),        "Scalar multiply 1" );
is( $v1 * 2, Vec(2,4),        "Scalar multiply 2" );

is( $v2 / 2, Vec(2,2.5),      "Scalar division" );

is( $v1.$v2, 14,                "Dot product" );
is( $v1 x $v2, (bless [0,0,-3], 'Math::VectorXYZ'), "Cross product" );


is( $v1->uvec->mag, 1,                              "Unit vec and mag");
is( sprintf( "%.4f", $v1->proj($v2) ), "2.1864",    "Project vector");
is( sprintf( "%.3f", $v1->angle($v2) ), "12.095",   "Angle between vectors");

is( "$v1", "<1,2>", "Vector print" );


is( $v1 += Vec(1,1), Vec(2,3),      "+= Addition" );
is( $v2 -= Vec(1,1), Vec(3,4),      "-= Subtraction" );

is( $v1 *= 2, Vec(4,6),             "*= Scalar Multiply" );
is( $v2 /= 2, Vec(1.5,2),           "/= Scalar Divide" );

