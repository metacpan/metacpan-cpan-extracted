use strict;
use warnings;
use utf8;
use Encode 'encode';
use Test::Needs { 'Math::BigInt' => '1.999722', 'Math::BigFloat' => '1.999722', 'Math::BigRat' => '0.260804' };
use Math::Calc::Parser;
use Test::More;

my $parser = Math::Calc::Parser->new(bigrat => 1);

my $result = Math::Calc::Parser->evaluate([2,2,'+']);
is $result, 4, 'Evaluated 2+2';
$result = $parser->evaluate('3/9');
is $result, '1/3', 'Evaluated 3/9';
$result = $parser->evaluate('3>>2');
is $result, '3/4', 'Evaluated 3>>2';

sub calc ($) { $parser->evaluate($_[0]) }

is calc '3+2', 5, 'Addition';
is calc '3-2', 1, 'Subtraction';
is calc '3*2', 6, 'Multiplication';
is calc '3/2', '3/2', 'Division';
is calc '3%2', 1, 'Modulo';
is calc '3^2', 9, 'Exponent';
is calc '3<<2', 12, 'Left shift';
is calc '3>>1', '3/2', 'Right shift';
is calc '3!', 6, 'Factorial';

is calc 'abs -2', 2, 'Absolute value';
is calc 'abs 2', 2, 'Absolute value';
is calc 'int(5/2)', 2, 'Cast to integer';
is calc 'int(-5/2)', -2, 'Cast to integer';
is calc 'ceil(5/2)', 3, 'Ceiling';
is calc 'ceil(-5/2)', -2, 'Ceiling';
is calc 'floor(5/2)', 2, 'Floor';
is calc 'floor(-5/2)', -3, 'Floor';
is calc 'round(5/2)', 3, 'Round';
is calc 'round(-5/2)', -3, 'Round';

is calc 'sqrt(1/64)', '1/8', 'Square root';

done_testing;
