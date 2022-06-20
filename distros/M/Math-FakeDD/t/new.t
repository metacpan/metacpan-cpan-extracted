
use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

warn "\nmpfr version: ", MPFR_LIB_VERSION . " (", Math::MPFR::MPFR_VERSION_STRING .")\n";
warn "min prec    : ", Math::MPFR::RMPFR_PREC_MIN(), "\n";

cmp_ok($Math::FakeDD::VERSION, '==', 0.04, "Version number is correct");

eval { Math::FakeDD->new(1,2) };
like($@, qr/Too many args given to new/, "method call: To many args");

eval { Math::FakeDD::new(1,2) };
like($@, qr/Too many args given to new/, "function call: To many args");

my $obj = Math::FakeDD->new();

cmp_ok($obj->{msd}, '==', 0, "msd == 0");
cmp_ok($obj->{lsd}, '==', 0, "lsd == 0");

cmp_ok(Math::MPFR::_itsa($obj->{msd}), '==', 2, "msd is IV");
cmp_ok(Math::MPFR::_itsa($obj->{lsd}), '==', 2, "lsd is IV");

my $obj2 = Math::FakeDD::new('1.3');

if(NV_IS_DOUBLE) {
  cmp_ok($obj2->{msd}, '==', 1.3,                     "msd == 1.3");
  cmp_ok($obj2->{lsd}, '==', -4.4408920985006264e-17, "lsd == -4.4408920985006264e-17");
}

like(sprintf("%s", $obj2), qr/^\[1\.3 \-4\.4408920985006264e\-(0+)?17\]/i, "new() assigns '1.3' correctly");

my $obj3 = Math::FakeDD->new('0.1');

if(NV_IS_DOUBLE) {
  cmp_ok($obj3->{msd}, '==', 0.1,                     "msd == 0.1");
  cmp_ok($obj3->{lsd}, '==', -5.551115123125783e-18, "lsd == -5.551115123125783e-18");
}

cmp_ok("$obj3", 'eq', '[0.1 -5.551115123125783e-18]', "new() assigns '0.1' correctly");

my $obj4 = Math::FakeDD->new($obj3);
cmp_ok($obj3, '==', $obj4, "new() creates a copy correctly");


done_testing();
