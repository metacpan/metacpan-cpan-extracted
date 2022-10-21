# Run checks on dd_assign, overload_copy, dd_copy and dd_clone
use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;


my $obj = Math::FakeDD->new();

dd_assign($obj, 1.625);

cmp_ok($obj->{msd}, '==', 1.625, "msd == 1.625");
cmp_ok($obj->{lsd}, '==', 0, "lsd == 0");

cmp_ok(Math::MPFR::_itsa($obj->{msd}), '==', 3, "msd is NV");
cmp_ok(Math::MPFR::_itsa($obj->{lsd}), '==', 3, "lsd is NV");

dd_assign($obj, '5.125');

cmp_ok($obj->{msd}, '==', 5.125, "msd == 5.125");
cmp_ok($obj->{lsd}, '==', 0, "lsd == 0");

cmp_ok(Math::MPFR::_itsa($obj->{msd}), '==', 3, "msd is NV");
cmp_ok(Math::MPFR::_itsa($obj->{lsd}), '==', 3, "lsd is NV");

cmp_ok(dd_inf()             , '>' , 0, "dd_inf() is +ve");
cmp_ok(dd_inf(-1)           , '<' , 0, "dd_inf(-1) is -ve");
cmp_ok(dd_is_inf(dd_inf())  , '!=', 0, "+inf is recognized as inf");
cmp_ok(dd_is_inf(dd_inf(-1)), '!=', 0, "-inf is recognized as inf");
cmp_ok(dd_is_nan(dd_inf(-1)), '==', 0, "-inf is not nan"          );

cmp_ok(dd_is_nan(dd_nan())  , '!=', 0, "dd_nan() is recognized as nan");
cmp_ok(dd_is_inf(dd_nan())  , '==', 0, "nan is not inf"               );

my $x = Math::FakeDD->new(2.5);
my $y = $x;
my $x_clone = dd_clone($x);
my $x_copy  = dd_copy ($x);

$x *= 4;

cmp_ok($y, '==', 2.5, 'the value of the copy is unaltered');
cmp_ok($x, '==', 10, 'the original value is reset correctly');

cmp_ok($x_clone, '==', 2.5, 'the value of the copy is unaltered');
cmp_ok($x_copy,  '==', 2.5, 'the original value is reset correctly');

$y = $x;
cmp_ok($y, '==', 10, 'the copy is updated correctly');

cmp_ok($x_clone, '==', 2.5, 'dd_clone returned a separate copy');
cmp_ok($x_copy,  '==', 2.5, 'dd_copy returned a separate copy');

$x_clone = dd_clone($y);
$x_copy  = dd_copy ($y);

cmp_ok($x_clone, '==', 10, 'dd_clone updated the value correctly');
cmp_ok($x_copy,  '==', 10, 'dd_copy updated the value correctly');

eval {dd_clone(Math::MPFR->new(1.23));};
like($@, qr/^Arg given to dd_clone or dd_copy must be a Math::FakeDD object/,
    'dd_clone rejects Math::MPFR object argument');

eval {dd_copy(17);};
like($@, qr/^Arg given to dd_clone or dd_copy must be a Math::FakeDD object/,
     'dd_copy rejects plain perl scalar argument');

$x = Math::FakeDD -> new("1.79769313486231580793728971405303e+308");

cmp_ok(dd_is_inf($x)  , '!=', 0, "1.79769313486231580793728971405303e+308 is inf");

cmp_ok($x, '==', mpfr2dd(dd2mpfr($x)), "1.79769313486231580793728971405303e+308 passes round trip");

cmp_ok(dd_is_inf(mpfr2dd(mpfr2098('1.79769313486231580793728971405303e+308'))), '!=', 0,
       "mpfr2dd(mpfr2098('1.79769313486231580793728971405303e+308')) ok");

$x = Math::FakeDD -> new("-1.79769313486231580793728971405303e+308");

cmp_ok($x, '==', dd_inf(-1), "-1.79769313486231580793728971405303e+308 is -inf");

cmp_ok($x, '==', mpfr2dd(dd2mpfr($x)), "-1.79769313486231580793728971405303e+308 passes round trip");

cmp_ok(mpfr2dd(mpfr2098('-1.79769313486231580793728971405303e+308')), '==', dd_inf(-1),
       "mpfr2dd(mpfr2098('-1.79769313486231580793728971405303e+308')) ok");

done_testing();
