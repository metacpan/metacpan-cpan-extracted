#!/usr/bin/perl

use strict;
use warnings;
use Config;
use Math::Random::MTwist qw(:rand :seed :dist :state);
use Test::More tests => 22;

use constant IS_32_BIT => (~0 == 0xffff_ffff) ? 1 : 0;

sub is_string {
  my $what = shift;
  ($what & ~$what) ne '0';
}

diag("\nIS_32_BIT:".IS_32_BIT);
diag('HAS_UINT64_T:'.Math::Random::MTwist::HAS_UINT64_T);
diag('NVMANTBITS:'.Math::Random::MTwist::NVMANTBITS);


# If you change the order of the tests the expected results will change!

# We cannot test all of the distributions because most of them contain loops
# whose loop count we cannot predict.

cmp_ok(seed32(1_000_100_303), '==', 1_000_100_303, 'seed32');
cmp_ok(srand(2_000_200_303), '==', 2_000_200_303, 'srand');

cmp_ok(irand32(), '==', 3_596_888_088, 'irand32');
like(rand32(), qr/^0\.645163/, 'rand32');

my $seed = 4_000_400_707;
seed32($seed);
like(rand(), qr/^0\.505808/, 'rand');

seed32($seed);
like(rd_triangular(0, 2, 1), qr/^1\.005825/, 'rd_triangular');

seed32($seed);
like(rd_ltriangular(0, 2, 1), qr/^1\.005825/, 'rd_ltriangular');

seed32($seed);
like(rd_uniform(-73, 73), qr/^0\.848028/, 'rd_uniform');

seed32($seed);
like(rd_luniform(-73, 73), qr/^0\.848028/, 'rd_luniform');

seed32($seed);
like(rd_double(), qr/^-1\.671732.+e-301$/i, 'rd_double');

seed32($seed);
is(randstr(19), "n\232\263\275\357\307\374\266\203NO\224\201\2061?\261?i", 'randstr');

do {
  my $seed = 0b1010000100111100011110010000101;
  my $d1 = do { seed32($seed); scalar rd_double(); };
  my $d2 = do { seed32($seed); rd_double(0); };
  my $d3 = do { seed32($seed); (rd_double())[0]; };
  cmp_ok($d1, '==', $d2, 'rd_double(0)');
  cmp_ok($d2, '==', $d3, '(rd_double())[0]');
};

seed32($seed);
do {
  my $state = getstate();
  cmp_ok(length $state, '>', 624*4, 'getstate');
  cmp_ok(irand32(), '==', 2_172_430_608, 'irand32 before setstate');
  my $rs = rd_double(2);
  is($rs, "\201\2061?\261?i\351", 'rd_double(2) before setstate');

  setstate($state);
  cmp_ok(irand32(), '==', 2_172_430_608, 'irand32 after setstate');
  is($rs, rd_double(2), 'rd_double(2) after setstate');
};

seed32($seed);
do {
  my $i = irand64();
  if (! defined $i) {
    ok(IS_32_BIT, 'irand64 returned undef: your Perl should use 32-bit integers');
    ok(!Math::Random::MTwist::HAS_UINT64_T, "irand64 returned undef: your system shouldn't have uint64_t");
    pass('dummy');
  }
  elsif (is_string($i)) {
    is($i, '9330518418105384881', 'irand64 string value');
    ok(IS_32_BIT, 'irand64 returned a string: your Perl should use 32-bit integers');
    ok(Math::Random::MTwist::HAS_UINT64_T, 'irand64 returned a string: your system should have uint64_t');
  }
  else {
    cmp_ok($i, '==', 9330518418105384881, 'irand64 numeric value');
    pass('dummy');
    pass('dummy');
  }
};

seed32($seed);
do {
  my $i = rd_iuniform64(-73, 0);
  if (defined $i) {
    cmp_ok($i, '==', -24, 'rd_iuniform64 numeric value');
  }
  else {
    ok(IS_32_BIT, 'rd_iuniform64 returned undef: your Perl should use 32-bit integers');
  }
};
