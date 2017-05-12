use strict;
use warnings;

use Test::More tests => 182;

use Math::decNumber qw(:all);

#====== FromString, ToString

my $x = FromString(1234.567);
ok( ref($x) eq 'decNumberPtr' );

my $s = ToString($x);
ok( $s eq '1234.567' );

$x = d_('1234.567'); 
ok( ref($x) eq 'decNumberPtr' );

$s = ToString($x);
ok( $s eq '1234.567' );

$x = d_(1234.567);
ok( ref($x) eq 'decNumberPtr' );

$s = ToString($x);
ok( $s eq '1234.567' );

$x = d_('1234.567');
ok( ref($x) eq 'decNumberPtr' );

$s = ToString($x);
ok( $s eq '1234.567' );

ok( d_(1.23) == d_(1.23000) );

#====== Add, Sub

ok( d_(5.1) + d_(3.5) == d_(8.6) );

ok( Add(d_(5.1), d_(3.5)) == d_(8.6) );

ok( d_(5.1) - d_(3.5) == d_(1.6) );

ok( Subtract(d_(5.1), d_(3.5)) == d_(1.6) );

ok( d_(3.5) - d_(5.1) == d_(-1.6) );

ok( d_(8.7) + (d_(3.5) + d_(5.1)) == d_(17.3) );

ok( d_(8.7) - (d_(3.5) + d_(5.1)) == d_(0.1) );

ok( d_(8.7) - (d_(3.5) - d_(5.1)) == d_(10.3) );

#====== negate

$x = d_(-12.345);
ok( -$x == 12.345);

$x = d_(123.45);
ok( -$x == -123.45);

$x = d_(-12.345);
ok( CopyNegate($x) == 12.345);

$x = d_(123.45);
ok( CopyNegate($x) == -123.45);

$b = CopySign($x, d_(78.23));
ok($b == $x);

$b = CopySign($x, d_(-78.23));
ok($b == -$x);

$x = CopyAbs( d_(-78.23) );
ok( $x == d_(78.23) );

$x = CopyAbs( d_(78.23) );
ok( $x == d_(78.23) );

#====== Mul, Div

ok( d_(2.1) * d_(3.7) == d_(7.77) );

ok( d_(2.1) * d_(-3.7) == d_(-7.77) );

ok( Multiply(d_(2.1), d_(-3.7)) == d_(-7.77) );

ok( d_(-2.1) * d_(-3.7) == d_(7.77) );

ok( d_(7.77) / d_(3.7) == d_(2.1) );

ok( d_(-7.77) / d_(3.7) == d_(-2.1) );

ok( d_(7.77) / d_(-3.7) == d_(-2.1) );

ok( Divide(d_(7.77), d_(-3.7)) == d_(-2.1) );

ok( d_(-7.77) / d_(-3.7) == 2.1 );

ok( d_(7.77) / d_(3.7) / d_(0.7)  == d_(3) );

ok( d_(2.1) * d_(3.7) / d_(21)  == d_(0.37) );

ok( d_(7.77) / d_(3.7) * d_(2.1)  == d_(4.41) );

ok( FMA( d_(2), d_(3), d_(5) ) == 11 );

ok( FMA( d_ 2, 3, 5 ) == 11 );

ok( FMA( d_( 2, 3), d_ 5 ) == 11 );

$x = d_ 5;
ok( FMA( d_ 2, 3, $x ) == 11 );

my ($u, $v, $w ) = d_ 2, 3, 5;
ok( FMA( $u, $v, $w ) == 11 );

#====== abs

ok( abs(d_(-3.5)) == d_(3.5) );

ok( abs(d_(3.5)) == d_(3.5) );

ok( Abs(d_(-3.5)) == d_(3.5) );

ok( Abs(d_(3.5)) == d_(3.5) );

#====== sqrt

ok( sqrt(d_ 25) == d_(5) );

ok( sqrt(d_ 3) == SquareRoot(d_ 3) );

#====== power

$x = d_(3.4)**3;
ok( $x == d_(39.304) );

$x = 3.4**d_(3);
ok( $x == d_(39.304) );

$x = d_(3.4)**d_(3);
ok( $x == d_(39.304) );

#====== log Log10 Exp

ok( log( d_ 10 ) == Ln( d_ 10) );

ok( Log10(d_(10)) == 1 );

ok( Exp(d_(0)) == 1 );

#====== remainder %

ok( d_(13) % 5 == 3 );

ok( 13 % d_(5) == 3 );

ok( d_(13) % d_(5) == 3 );

ok( Remainder(d_(13), d_(5)) == 3 );

ok( RemainderNear(d_(13), d_(5)) == -2 );

ok( DivideInteger(d_(13), d_(5) ) == 2 );

ok( ToIntegralValue(d_(123.456)) == 123 );

ok( ToIntegralValue(d_(-123.456)) == -123 );

ok( ToIntegralValue(d_(123.789)) == 124 );

ok( ToIntegralValue(d_(-123.789)) == -124 );

ok( ToIntegralExact(d_(123.456)) == 123 );

ok( ToIntegralExact(d_(-123.456)) == -123 );

ok( ToIntegralExact(d_(123.789)) == 124 );

ok( ToIntegralExact(d_(-123.789)) == -124 );

#====== Compare CompareSignal

ok( Compare( d_(3), d_(5) ) == -1 );

ok( Compare( d_(3.2), d_(3.2) ) == 0 );

ok( Compare( d_(5), d_(3) ) == 1 );

ok( ( d_(3) <=> d_(5) ) == -1 );

ok( ( d_(3.2) <=> d_(3.2) ) == 0 );

ok( ( d_(5) <=> d_(3) ) == 1 );

ok( CompareSignal( d_(3), d_(5) ) == -1 );

ok( CompareSignal( d_(3.2), d_(3.2) ) == 0 );

ok( CompareSignal( d_(5), d_(3) ) == 1 );

ok( CompareTotal( d_(3), d_(5) ) == -1 );

ok( CompareTotal( d_(3.2), d_(3.2) ) == 0 );

ok( CompareTotal( d_(5), d_(3) ) == 1 );

ok( CompareTotalMag( d_(3), d_(-5) ) == -1 );

ok( CompareTotalMag( d_(3.2), d_(-3.2) ) == 0 );

ok( CompareTotalMag( d_(5), d_(-3) ) == 1 );

#====== order

ok( d_(2.1) < d_(3) );

ok( d_(2.1) < 3 );

ok( 2.1 < d_(3) );

ok( d_(2.1) <= d_(3) );

ok( d_(2.1) <= 3 );

ok( 2.1 <= d_(3) );

ok( d_(5.1) > d_(3) );

ok( d_(5.1) > 3 );

ok( 5.1 > d_(3) );

ok( d_(5.1) >= d_(3) );

ok( d_(5.1) >= 3 );

ok( 5.1 >= d_(3) );

$x = d_(5.1);
ok( $x >= d_(3) );

#====== Max Min MaxMag  MinMag

ok( Max(d_(-4.23), d_(1.25) ) == 1.25 );

ok( Min(d_(-4.23), d_(1.25) ) == -4.23 );

ok( MaxMag(d_(-4.23), d_(1.25) ) == -4.23 );

ok( MinMag(d_(-4.23), d_(1.25) ) == 1.25 );

#====== inv, and or xor shift

ok( Invert(d_(10111)) == d_('1111111111111111111111111111101000') );

$x = d_(10111);
ok( ~$x == d_('1111111111111111111111111111101000') );

ok( And(d_(1011101), d_(1110111)) == d_(1010101) );

ok( (d_(1011101) & d_(1110111)) == d_(1010101) );

ok( Or(d_(1011101), d_(1110111)) == d_(1111111) );

ok( (d_(1011101) | d_(1110111)) == d_(1111111) );

ok( Xor(d_(1011101), d_(1110111)) == d_(101010) );

ok( (d_(1011101) ^ d_(1110111)) == d_(101010) );

ok( Shift(d_(123), d_(3)) == 123000);

ok( (d_(123) << 3) == 123000);

ok( (d_(123456) >> 3) == 123);

ok( Rotate(d_(123456), d_(-3)) == d_('4560000000000000000000000000000123') );

#====== inc et dec

$x = d_ 35.2;
$b = ++$x;
ok( $x == d_(36.2) and $b == d_(36.2) );

$x = d_ 35.2;
$b = $x++;
ok( $x == d_(36.2) and $b == d_(35.2) );

$x = d_ 35.2;
$b = --$x;
ok( $x == d_(34.2) and $b == d_(34.2) );

$x = d_ 35.2;
$b = $x--;
ok( $x == d_(34.2) and $b == d_(35.2) );

for( my $i = d_(0); $i != 1; $i += 0.01) {}
ok(1);    # no infinite loop

#====== Next*

ok( NextPlus(d_ 123.456) == d_('123.4560000000000000000000000000001') );

ok( NextPlus(d_ -123.456) == d_('-123.4559999999999999999999999999999') );

ok( NextMinus(d_ 123.456) == d_('123.4559999999999999999999999999999') );

ok( NextMinus(d_ -123.456) == d_('-123.4560000000000000000000000000001') );

ok( NextToward(d_(123.456), d_(200)) == d_('123.4560000000000000000000000000001') );

ok( NextToward(d_(123.456), d_(100)) == d_('123.4559999999999999999999999999999') );

#====== ScaleB  LogB

ok( ScaleB(d_(123.456), d_(2)) == d_ '12345.6' );

ok( ScaleB(d_(123.456), d_(5)) == d_ '1.23456E+7' );

ok( LogB(d_(123.456)) == 2 );

ok( LogB(d_(0.00123456)) == -3 );

#====== Plus Minus Reduce

ok( Plus(d_(0.00123456)) == 0.00123456 );

ok( Reduce(d_(0.00123456)) == 0.00123456 );

ok( Minus(d_(0.00123456)) == -0.00123456 );

ok( Trim(d_(123.40000000)) == 123.4 );

#====== Quantize SameQuantum Rescale  

ok( Quantize(d_(0.00123456), d_(78.9456)) == 0.0012 );

ok( Rescale(d_(0.00123456), d_(-4)) == 0.0012 );

ok( SameQuantum(d_(0.0012), d_(0.0078)) == 1 );

#====== Test functions

ok( IsCanonical( d_ 3.2) );

ok( IsFinite( d_ 3.2) );

ok( !IsFinite( d_(3.2)/0 ) );

ok( !IsInfinite( d_ 3.2) );

ok( IsInfinite( d_(3.2)/0 ) );

ok( IsNaN( d_(0) /0 ) );

ok( !IsNaN( d_(3.51) ) );

ok( IsNegative( d_ -3.2) );

ok( !IsNegative( d_ +3.2) );

ok( IsNormal( d_ -3.2) );

ok( !IsNormal( d_('1e-9999'))  );

ok( IsQNaN( d_(0) /0 ) );

ok( !IsQNaN( d_(3.5) ) );

ok( IsSNaN(  FromString 'sNaN'  ) );

ok( !IsSNaN( d_(3.5) ) );

ok( IsSpecial( d_(0) /0 ) );

ok( !IsSpecial( d_(3.5) ) );

ok( IsSubnormal( d_('1e-6144')) );

ok( !IsZero( d_(0.001)) );

ok( IsZero( d_(0.000)) );

#====== Class

ok( ClassToString(0) eq 'sNaN' );
ok( ClassToString(1) eq 'NaN' );
ok( ClassToString(2) eq '-Infinity' );
ok( ClassToString(3) eq '-Normal' );
ok( ClassToString(4) eq '-Subnormal' );
ok( ClassToString(5) eq '-Zero' );
ok( ClassToString(6) eq '+Zero' );
ok( ClassToString(7) eq '+Subnormal' );
ok( ClassToString(8) eq '+Normal' );
ok( ClassToString(9) eq '+Infinity' );

ok( ClassToString(d_(1)/0) eq '+Infinity' );
ok( Class(d_(1)/0) == 9 );
ok( ClassToString(d_(-1)/0) eq '-Infinity' );
ok( Class(d_(-1)/0) == 2 );
ok( ClassToString(d_('glop')) eq 'NaN' );
ok( Class(d_('glop')) == 1 );
ok( ClassToString(d_(2)) eq '+Normal' );
ok( Class(d_(2)) == 8 );
ok( ClassToString(d_(-3)) eq '-Normal' );
ok( Class(d_(-3)) == 3 );
ok( ClassToString(d_(0)) eq '+Zero' );
ok( Class(d_(0)) == 6 );
ok( ClassToString(d_(+0)) eq '+Zero' );
ok( Class(d_(+0)) == 6 );
ok( ClassToString(d_(-0)) eq '+Zero' );
ok( Class(d_(-0)) == 6 );
ok( ClassToString(-d_(0)) eq '-Zero' );
ok( Class(-d_(0)) == 5 );


#====== End of tests











