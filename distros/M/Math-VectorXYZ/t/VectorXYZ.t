#!perl -T
use 5.006;
use warnings;
use strict;
use Math::VectorXYZ;
use Test::More;

plan tests => 15;

my $v1 = Vec(1,2,3);
my $v2 = Math::VectorXYZ->new(4,5,6);

is( $v2 + $v1, Vec(5,7,9),      "Addition" );
is( $v2 - $v1, Vec(3,3,3),      "Subtraction" );

is( 2 * $v1, Vec(2,4,6),        "Scalar multiply 1" );
is( $v1 * 2, Vec(2,4,6),        "Scalar multiply 2" );

is( $v2 / 2, Vec(2,2.5,3),      "Scalar division" );

is( $v1.$v2, 32,                "Dot product" );
is( $v1 x $v2, Vec(-3,6,-3),    "Cross product" );


is( $v1->uvec->mag, 1,                              "Unit vec and mag");
is( sprintf( "%.4f", $v1->proj($v2) ), "3.6467",    "Project vector");
is( sprintf( "%.3f", $v1->angle($v2) ), "12.933",   "Angle between vectors");

is( "$v1", "<1,2,3>", "Vector print" );


is( $v1 += Vec(1,1,1), Vec(2,3,4),      "+= Addition" );
is( $v2 -= Vec(1,1,1), Vec(3,4,5),      "-= Subtraction" );

is( $v1 *= 2, Vec(4,6,8),               "*= Scalar Multiply" );
is( $v2 /= 2, Vec(1.5,2,2.5),           "/= Scalar Divide" );

