use strict;
use warnings;
use Test::More tests => 6;

use_ok('Math::Symbolic');
use_ok('Math::SymbolicX::Complex');
use_ok('Math::Complex');

use Math::Complex;
use Math::Symbolic qw/parse_from_string/;

my $cplx = parse_from_string('complex(1,2)');
ok($cplx->value() == Math::Complex->make(1,2),
'complex(RE,IM) returning correct result');

$cplx = parse_from_string('polar(1,pi/2)');
ok(abs(Re($cplx->value())) < 1e-8,
'polar returns correct result (re)'
);

ok(abs(Im($cplx->value()) - 1) < 1e-8,
'polar returns correct result (im)'
);

