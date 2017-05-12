use strict;
use warnings;
use Math::Calc::Parser 'calc';
use Math::Complex 'i';
use Test::More;

my $parser = Math::Calc::Parser->new;

my $result = Math::Calc::Parser->evaluate([2,2,'+']);
is $result, 4, 'Evaluated 2+2';
$result = $parser->evaluate([2,3,'ln','*']);
is $result, 2*log(3), 'Evaluated 2 ln 3';
$result = $parser->evaluate([2,3,4,5,'+','*','^']);
cmp_ok $result, '==', 2**(3*(4+5)), 'Evaluated 2^(3*(4+5))';
$result = $parser->evaluate(['i','i','*']);
cmp_ok $result, '==', -1, 'Evaluated i*i';
$result = $parser->evaluate([1,'u-','sqrt']);
cmp_ok $result, '==', i, 'Evaluated sqrt -1';
$result = $parser->evaluate('1+2*3^4');
cmp_ok $result, '==', 1+2*3**4, 'Evaluated 1+2*3^4 as string expression';
$result = calc 'log 7';
is $result, log(7)/log(10), 'Evaluated log 7 with calc()';

done_testing;
