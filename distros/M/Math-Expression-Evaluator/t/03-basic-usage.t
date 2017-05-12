use strict;
use warnings;
use Test::More;
use Data::Dumper;
BEGIN { plan tests => 3 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

$m = Math::Expression::Evaluator->new('2+3');

is $m->val(), 5, '->new($expression)';

$m = Math::Expression::Evaluator->new({}, '2+3');

is $m->val(), 5, '->new(\%options, $expression)';
