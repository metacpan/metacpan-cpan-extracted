use warnings;
use strict;

use Test::More 'no_plan';

use Carp;

$SIG{__WARN__} = \&Carp::confess;

use Math::CPWLF;

{

my $f = Math::CPWLF->new;

eval { $f->(1) };
like( $@, qr/\QError: cannot interpolate with no knots/, 'no knots' );

}

{

my $f = Math::CPWLF->new;

$f->knot( 1, 1 );
eval { $f->(2) };
like( $@, qr/\QError: given X (2) was out of bounds of function min or max/, '2 oob default' );

$f->knot( 2, 2 );
eval { $f->(3) };
like( $@, qr/\QError: given X (3) was out of bounds of function min or max/, '3 oob default' );

eval { $f->(0) };
like( $@, qr/\QError: given X (0) was out of bounds of function min or max/, '0 oob default' );

$f->knot( 3, 0 => 0 );
$f->knot( 4, 1 => 1 );

eval { $f->(3.5)(2) };
like( $@, qr/\QError: given X (2) was out of bounds of function min or max/, '2 oob default deep' );

my $f4 = Math::CPWLF->new( oob => 'level' );
$f->knot( 4, $f4 );
$f->knot( 4, 0 => 0 );
$f->knot( 4, 1 => 1 );

my $y = $f->(4)(2);
is($y, 1, '2 oob default -> level' );

}

{

my $f = Math::CPWLF->new( oob => 'die' );

$f->knot( 1, 1 );
eval { $f->(2) };
like( $@, qr/\QError: given X (2) was out of bounds of function min or max/, '2 oob die' );

$f->knot( 2, 2 );
eval { $f->(3) };
like( $@, qr/\QError: given X (3) was out of bounds of function min or max/, '3 oob die' );

eval { $f->(0) };
like( $@, qr/\QError: given X (0) was out of bounds of function min or max/, '0 oob die' );

$f->knot( 3, 0 => 0 );
$f->knot( 3, 1 => 1 );

eval { $f->(3)(2) };
like( $@, qr/\QError: given X (2) was out of bounds of function min or max/, '2 oob die deep' );

my $f4 = Math::CPWLF->new( oob => 'level' );
$f->knot( 4, $f4 );
$f->knot( 4, 0 => 0 );
$f->knot( 4, 1 => 1 );

my $y = $f->(4)(2);
is($y, 1, '2 oob die -> level' );

}

{

my $f = Math::CPWLF->new( oob => 'level' );

$f->knot( 1, 1 );
my $y = $f->(2);
is($y, 1, '2 oob level' );

$f->knot( 2, 2 );
$y = $f->(3);
is($y, 2, '3 oob level' );

$y = $f->(0);
is($y, 1, '0 oob level' );

$f->knot( 3, 0 => 0 );
$f->knot( 3, 1 => 1 );

$y = $f->(3)(2);
is($y, 1, '2 oob level deep' );

my $f4 = Math::CPWLF->new( oob => 'extrapolate' );
$f->knot( 4, $f4 );
$f->knot( 4, 0 => 0 );
$f->knot( 4, 1 => 1 );

$y = $f->(4)(2);
is($y, 2, '2 oob level -> extrapolate' );

}

{

my $f = Math::CPWLF->new( oob => 'extrapolate' );

$f->knot( 1, 1 );
my $y = $f->(2);
is($y, 1, '2 oob extrapolate' );

$f->knot( 2, 2 );
$y = $f->(3);
is($y, 3, '3 oob extrapolate' );

$y = $f->(0);
is($y, 0, '0 oob extrapolate' );

$f->knot( 3, 0 => 0 );
$f->knot( 3, 1 => 1 );

$y = $f->(3)(2);
is($y, 2, '2 oob extrapolate deep' );

my $f4 = Math::CPWLF->new( oob => 'level' );
$f->knot( 4, $f4 );
$f->knot( 4, 0 => 0 );
$f->knot( 4, 1 => 1 );

$y = $f->(4)(2);
is($y, 1, '2 oob extrapolate -> level' );

}

{

my $f = Math::CPWLF->new( oob => 'undef' );

$f->knot( 1, 1 );
my $y = $f->(2);
is($y, undef, '2 oob undef' );

$f->knot( 2, 2 );
$y = $f->(3);
is($y, undef, '3 oob undef' );

$y = $f->(0);
is($y, undef, '0 oob undef' );

$f->knot( 3, 0 => 0 );
$f->knot( 3, 1 => 1 );

$y = $f->(3)(2);
is($y, undef, '2 oob undef deep' );

$y = $f->(3)(2)(1);
is($y, undef, '2,1 oob undef deep' );

my $f4 = Math::CPWLF->new( oob => 'level' );
$f->knot( 4, $f4 );
$f->knot->(4)( 0 => 0 );
$f->knot->(4)( 1 => 1 );

$y = $f->(4)(2);
is($y, 1, '2 oob undef -> level' );

}

{

my $f = Math::CPWLF->new( oob => 'potato' );

$f->knot( 1, 1 );
eval { $f->(2) };
like( $@, qr/\QError: invalid oob option (potato)/, 'invalid oob handler' );

}