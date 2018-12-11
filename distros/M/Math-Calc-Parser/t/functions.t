use strict;
use warnings;
use utf8;
use Encode 'encode';
use Math::Calc::Parser 'calc';
use Math::Complex;
use Test::More;

is calc 'e', exp(1), 'Euler\'s number';
is calc 'pi', pi, 'Pi';
is calc 'π', pi, encode('UTF-8', 'π');
is +(calc 'i')->Im, 1, 'Imaginary unit';
is +(calc 'i')->Re, 0, 'Imaginary unit';

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

is calc 'acos 0', pi/2, 'Arccosine';
is calc 'asin -1', -(pi/2), 'Arcsine';
is calc 'atan 1', pi/4, 'Arctangent';
is calc 'atan2(1,1)', pi/4, 'Arctangent (2 args)';
is calc 'sin pi/2', 1, 'Sine';
is calc 'cos π', -1, 'Cosine';
is calc 'tan -π/4', -1, 'Tangent';

is calc 'log 5', log10(5), 'Common logarithm';
is calc 'ln 5', ln(5), 'Natural logarithm';
is calc 'logn(5,2)', log(5) / log(2), 'Custom logarithm';

is calc 'sqrt 64', 8, 'Square root';

my $rand = calc 'rand';
ok($rand >= 0 && $rand < 1, 'Random number');

my $parser = Math::Calc::Parser->new;
$parser->add_functions(my_function => sub { 5 });
is $parser->evaluate('my_function'), 5, 'Added no-arg function';
$parser->add_functions(my_function => { args => 2, code => sub { $_[0]+$_[1]+1 } });
is $parser->evaluate('my_function(2,3)'), 6, 'Added two-arg function';
is $parser->try_evaluate('my_function 2'), undef, 'Exception calling two-arg function with one arg';
$parser->remove_functions('π');
is $parser->try_evaluate('π'), undef, encode 'UTF-8', 'Removed function "π"';
$parser->add_functions(text => sub { '45blah' });
is $parser->evaluate('text'), 45, 'Results cast to number';

my $parser2 = Math::Calc::Parser->new;
is $parser2->try_evaluate('my_function(2,3)'), undef, 'Custom function specific to parser object';
is $parser2->try_evaluate('π'), pi, 'Function removal specific to parser object';
$parser2->remove_functions('*');
is $parser2->try_evaluate('2*3'), 6, 'Operator function not removed';

ok !eval { $parser->add_functions(_foo => sub { 1 }); 1 }, 'Invalid function name';
like $@, qr/invalid name/, 'right error';
ok !eval { $parser->add_functions(foo => { code => sub { 1 } }); 1 }, 'No argument count';
like $@, qr/argument count/, 'right error';
ok !eval { $parser->add_functions(foo => { args => 'foo', code => sub { 1 } }); 1 } , 'Invalid argument count';
like $@, qr/argument count/, 'right error';
ok !eval { $parser->add_functions(foo => { args => 1 }); 1 }, 'No coderef';
like $@, qr/coderef/, 'right error';
ok !eval { $parser->add_functions(foo => { args => 1, code => [] }); 1 } , 'Invalid coderef';
like $@, qr/coderef/, 'right error';

$parser->add_functions(myCaSe => { args => 1, code => sub { $_[0]*2 } });
is $parser->try_evaluate('MYcAsE 4'), undef, 'Case sensitive function';
$parser->remove_functions('myCASE');
is $parser->try_evaluate('myCaSe 2'), 4, 'Case sensitive function removal';

done_testing;
