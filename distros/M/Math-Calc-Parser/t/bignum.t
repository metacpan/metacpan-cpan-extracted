use strict;
use warnings;
use utf8;
use Encode 'encode';
use Test::Needs { 'Math::BigInt' => '1.999722', 'Math::BigFloat' => '1.999722' };
use Math::Calc::Parser;
use Test::More;

my $parser = Math::Calc::Parser->new(bignum => 1);

my $result = Math::Calc::Parser->evaluate([2,2,'+']);
is $result, 4, 'Evaluated 2+2';
$result = $parser->evaluate([Math::BigFloat->new(2),Math::BigFloat->new(3),'ln','*']);
is $result, Math::BigFloat->new(3)->blog->bmul(2), 'Evaluated 2 ln 3';

Math::BigFloat->round_mode('common');

sub _norm { Math::BigFloat->new($_[0]->bround(30)->bstr) }

sub calc ($) { _norm($parser->evaluate($_[0])) }

is calc '3+2', 5, 'Addition';
is calc '3-2', 1, 'Subtraction';
is calc '3*2', 6, 'Multiplication';
is calc '3/2', 1.5, 'Division';
is calc '3%2', 1, 'Modulo';
is calc '3^2', 9, 'Exponent';
is calc '3<<2', 12, 'Left shift';
is calc '3>>1', 1, 'Right shift';
is calc '3!', 6, 'Factorial';

is calc 'e', _norm(Math::BigFloat->new(1)->bexp), 'Euler\'s number';
is calc 'pi', _norm(Math::BigFloat->bpi), 'Pi';
is calc 'π', _norm(Math::BigFloat->bpi), encode('UTF-8', 'π');

is calc 'abs -2', 2, 'Absolute value';
is calc 'abs 2', 2, 'Absolute value';
is calc 'int 2.5', 2, 'Cast to integer';
is calc 'int -2.5', -2, 'Cast to integer';
is calc 'ceil 2.5', 3, 'Ceiling';
is calc 'ceil -2.5', -2, 'Ceiling';
is calc 'floor 2.5', 2, 'Floor';
is calc 'floor -2.5', -3, 'Floor';
is calc 'round 2.5', 3, 'Round';
is calc 'round -2.5', -3, 'Round';

is calc 'acos 0', _norm(scalar Math::BigFloat->bpi->bdiv(2)), 'Arccosine';
is calc 'asin -1', _norm(-(scalar Math::BigFloat->bpi->bdiv(2))), 'Arcsine';
is calc 'atan 1', _norm(scalar Math::BigFloat->bpi->bdiv(4)), 'Arctangent';
is calc 'atan2(1,1)', _norm(scalar Math::BigFloat->bpi->bdiv(4)), 'Arctangent (2 args)';
is calc 'sin pi/2', 1, 'Sine';
is calc 'cos π', -1, 'Cosine';
is calc 'tan -π/4', -1, 'Tangent';

is calc 'log 5', _norm(scalar Math::BigFloat->new(5)->blog->bdiv(Math::BigFloat->new(10)->blog)), 'Common logarithm';
is calc 'ln 5', _norm(Math::BigFloat->new(5)->blog), 'Natural logarithm';
is calc 'logn(5,2)', _norm(scalar Math::BigFloat->new(5)->blog->bdiv(Math::BigFloat->new(2)->blog)), 'Custom logarithm';

is calc 'sqrt 64', 8, 'Square root';

my $rand = calc 'rand';
ok($rand >= 0 && $rand < 1, 'Random number');

done_testing;
