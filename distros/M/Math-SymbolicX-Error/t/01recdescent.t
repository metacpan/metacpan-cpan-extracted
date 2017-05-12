use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
  use_ok('Math::Symbolic');
  use_ok('Number::WithError');
}
BEGIN {
#  $Math::Symbolic::Parser = Math::Symbolic::Parser->new(implementation => 'Yapp');
  $Math::Symbolic::Parser = Math::Symbolic::Parser->new(implementation => 'RecDescent', recompile=>1);
  use_ok('Math::SymbolicX::Error');
}

Math::Symbolic->import(qw/parse_from_string/);

my $cplx = parse_from_string('error(1 +/- 0.2)');
ok($cplx->value() eq Number::WithError->new(1, 0.2),
'error() returning correct result');

$cplx = parse_from_string('error_big(1+0.1-0.2)');
ok($cplx->value() eq Number::WithError->new(1, [0.1,0.2]),
'error_big() returns correct result'
);

