use strict;
use warnings;
use Math::Calc::Parser 'calc';
use Test::More;

my $parser = Math::Calc::Parser->new;

eval { Math::Calc::Parser->parse('(') };
like $@, qr/Mismatched parentheses/, 'right error';
eval { $parser->parse('e)') };
like $@, qr/Mismatched parentheses/, 'right error';
eval { $parser->parse('log , 2') };
like $@, qr/Misplaced comma/, 'right error';
eval { $parser->parse('invalid') };
like $@, qr/Invalid function/, 'right error';
eval { $parser->parse('7`2') };
like $@, qr/Unknown token/, 'right error';
eval { $parser->evaluate(['*']) };
like $@, qr/Malformed expression/, 'right error';
eval { $parser->evaluate(['unknown']) };
like $@, qr/Invalid function/, 'right error';
eval { calc '5/0' };
ok length($@), "Exception: $@";
eval { calc '(-2)!' };
like $@, qr/Error in function.*Factorial of negative number/, 'right error';
$parser->add_functions(undef => sub { undef });
eval { $parser->evaluate('undef') };
like $@, qr/Undefined result from function/, 'right error';
my $result = $parser->try_evaluate([2,3]);
is $result, undef, 'Exception evaluating expression';
like $parser->error, qr/Malformed expression/, 'right error';
$result = Math::Calc::Parser->try_evaluate('');
is $result, undef, 'Exception evaluating expression';
like $Math::Calc::Parser::ERROR, qr/No expression to evaluate/, 'right error';
like +Math::Calc::Parser->error, qr/No expression to evaluate/, 'right error';

done_testing;
