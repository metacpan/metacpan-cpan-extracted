use strict;
use warnings;
use Math::Calc::Parser;
use Test::More;

my $parser = Math::Calc::Parser->new;

my $parsed = Math::Calc::Parser->parse('');
is_deeply $parsed, [], 'Parsed empty expression';
$parsed = $parser->parse('1');
is_deeply $parsed, [1], 'Parsed lone number';

my $twoplustwo = [2,2,'+'];
$parsed = $parser->parse('2+2');
is_deeply $parsed, $twoplustwo, 'Parsed 2+2';
$parsed = $parser->parse('2    + 2');
is_deeply $parsed, $twoplustwo, 'Parsed 2+2 with whitespace';
$parsed = $parser->parse('(2)+2');
is_deeply $parsed, $twoplustwo, 'Parsed 2+2 with parentheses';
$parsed = $parser->parse('(2+2)');
is_deeply $parsed, $twoplustwo, 'Parsed 2+2 with parentheses';
my $twotimestwo = [2,2,'*'];
$parsed = $parser->parse('2*2');
is_deeply $parsed, $twotimestwo, 'Parsed 2*2';
$parsed = $parser->parse('(2)2');
is_deeply $parsed, $twotimestwo, 'Parsed 2*2 with implicit multiplication';
$parsed = $parser->parse('2 (2)');
is_deeply $parsed, $twotimestwo, 'Parsed 2*2 with implicit multiplication';

$parsed = $parser->parse('2+3*4');
is_deeply $parsed, [2,3,4,'*','+'], 'Parsed 2+3*4';
$parsed = $parser->parse('(2+3)4');
is_deeply $parsed, [2,3,'+',4,'*'], 'Parsed (2+3)*4';
$parsed = $parser->parse('2^3*4/5');
is_deeply $parsed, [2,3,'^',4,'*',5,'/'], 'Parsed 2^3*4/5';
$parsed = $parser->parse('(2^(3*4))/5');
is_deeply $parsed, [2,3,4,'*','^',5,'/'], 'Parsed (2^(3*4))/5';

$parsed = $parser->parse('2--3');
is_deeply $parsed, [2,3,'u-','-'], 'Parsed unary minus';
$parsed = $parser->parse('2-+3');
is_deeply $parsed, [2,3,'u+','-'], 'Parsed unary plus';
$parsed = $parser->parse('2!-3');
is_deeply $parsed, [2,'!',3,'-'], 'Parsed factorial';

$parsed = $parser->parse('ln(5)');
is_deeply $parsed, [5,'ln'], 'Parsed function';
$parsed = $parser->parse('ln 5');
is_deeply $parsed, [5,'ln'], 'Parsed function';
$parsed = $parser->parse('5 ln 5');
is_deeply $parsed, [5,5,'ln','*'], 'Parsed function with implicit multiplication';
$parsed = $parser->parse('ln (5*3)');
is_deeply $parsed, [5,3,'*','ln'], 'Parsed function with expression in args';
$parsed = $parser->parse('ln 5*3');
is_deeply $parsed, [5,3,'*','ln'], 'Parsed function with bare expression in args';
$parsed = $parser->parse('rand');
is_deeply $parsed, ['rand'], 'Parsed no-arg function';
$parsed = $parser->parse('rand 5');
is_deeply $parsed, ['rand',5,'*'], 'Parsed no-arg function with implicit multiplication';
$parsed = $parser->parse('log rand 5');
is_deeply $parsed, ['rand',5,'*','log'], 'Parsed no-arg function with implicit multiplication';
$parsed = $parser->parse('log(rand)5');
is_deeply $parsed, ['rand','log',5,'*'], 'Parsed no-arg function parenthesized';
$parsed = $parser->parse('logn(ln 5, e 3)');
is_deeply $parsed, [5,'ln','e',3,'*','logn'], 'Parsed multi-arg function';

done_testing;
