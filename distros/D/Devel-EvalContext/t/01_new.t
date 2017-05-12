use strict; use warnings;
use Test::More tests => 1;
use Devel::EvalContext;

my $context = Devel::EvalContext->new;
isa_ok($context, 'Devel::EvalContext');
