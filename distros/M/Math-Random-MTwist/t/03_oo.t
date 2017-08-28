#!/usr/bin/perl

use strict;
use warnings;
use Config;
use Math::Random::MTwist;
use Test::More tests => 22;

use constant IS_32_BIT => ~0 == 0xffff_ffff;

sub is_string {
  my $what = shift;
  ($what & ~$what) ne '0';
}


# If you change the order of the tests the expected results will change!

# We cannot test all of the distributions because most of them contain loops
# whose loop count we cannot predict.

my $mt = Math::Random::MTwist->new();

cmp_ok($mt->seed32(1_000_100_303), '==', 1_000_100_303, 'seed32');
cmp_ok($mt->srand(2_000_200_303), '==', 2_000_200_303, 'srand');

cmp_ok($mt->irand32(), '==', 3_596_888_088, 'irand32');
like($mt->rand32(), qr/^0\.645163/, 'rand32');

my $seed = 4_000_400_707;
$mt->seed32($seed);
like($mt->rand(), qr/^0\.505808/, 'rand');

$mt->seed32($seed);
like($mt->rd_triangular(0, 2, 1), qr/^1\.005825/, 'rd_triangular');

$mt->seed32($seed);
like($mt->rd_ltriangular(0, 2, 1), qr/^1\.005825/, 'rd_ltriangular');

$mt->seed32($seed);
like($mt->rd_uniform(-73, 73), qr/^0\.848028/, 'rd_uniform');

$mt->seed32($seed);
like($mt->rd_luniform(-73, 73), qr/^0\.848028/, 'rd_luniform');

$mt->seed32($seed);
like($mt->rd_double(), qr/^-1\.671732.+e-301$/i, 'rd_double');

$mt->seed32($seed);
is($mt->randstr(19), "n\232\263\275\357\307\374\266\203NO\224\201\2061?\261?i", 'randstr');

do {
  my $seed = 0b1010000100111100011110010000101;
  my $d1 = do { $mt->seed32($seed); scalar $mt->rd_double(); };
  my $d2 = do { $mt->seed32($seed); $mt->rd_double(0); };
  my $d3 = do { $mt->seed32($seed); ($mt->rd_double())[0]; };
  cmp_ok($d1, '==', $d2, 'rd_double(0)');
  cmp_ok($d2, '==', $d3, '(rd_double())[0]');
};

$mt->seed32($seed);
do {
  my $state = $mt->getstate();
  cmp_ok(length $state, '>', 624*4, 'getstate');
  cmp_ok($mt->irand32(), '==', 2_172_430_608, 'irand32 before setstate');
  my $rs = $mt->rd_double(2);
  is($rs, "\201\2061?\261?i\351", 'rd_double(2) before setstate');

  $mt->setstate($state);
  cmp_ok($mt->irand32(), '==', 2_172_430_608, 'irand32 after setstate');
  is($rs, $mt->rd_double(2), 'rd_double(2) after setstate');
};

$mt->seed32($seed);
do {
  my $i = $mt->irand64();
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

$mt->seed32($seed);
do {
  my $i = $mt->rd_iuniform64(-73, 0);
  if (defined $i) {
    cmp_ok($i, '==', -24, 'rd_iuniform64 numeric value');
  }
  else {
    ok(IS_32_BIT, 'rd_iuniform64 returned undef: your Perl should use 32-bit integers');
  }
};
