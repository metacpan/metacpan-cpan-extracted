
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

done_testing();
