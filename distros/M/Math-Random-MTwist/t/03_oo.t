#!/usr/bin/perl

use strict;
use warnings;
use Math::Random::MTwist;
use Test::More tests => 23;

my $mt = Math::Random::MTwist->new(1_000_686_894);

# If you change the order of the tests the expected results will change!

ok($mt->irand32() == 2_390_553_143, 'irand32');
{
  my $i = $mt->irand64();
  ok(!defined $i || $i == 5_527_845_158, 'irand64');
}
ok($mt->rand()   =~ /^0\.9457734/, 'rand');
ok($mt->rand32() =~ /^0\.3981395/, 'rand32');

ok($mt->rd_erlang(2, 1)  =~ /^1\.2556495/, 'rd_erlang');
ok($mt->rd_lerlang(2, 1) =~ /^0\.3129639/, 'rd_lerlang');

ok($mt->rd_exponential(1)  =~ /^1\.3165971/, 'rd_exponential');
ok($mt->rd_lexponential(1) =~ /^0\.3011559/, 'rd_lexponential');

ok($mt->rd_lognormal(1, 0)  =~ /^0\.8843699/, 'rd_lognormal');
ok($mt->rd_llognormal(1, 0) =~ /^1\.2886502/, 'rd_llognormal');

ok($mt->rd_normal(5, 1)  =~ /^3\.4375795/, 'rd_normal');
ok($mt->rd_lnormal(5, 1) =~ /^4\.8138142/, 'rd_lnormal');

ok($mt->rd_triangular(0, 2, 1)  =~ /^1\.0779715/, 'rd_triangular');
ok($mt->rd_ltriangular(0, 2, 1) =~ /^1\.3103709/, 'rd_ltriangular');

ok($mt->rd_weibull(1.5, 1)  =~ /^0\.7575942/, 'rd_weibull');
ok($mt->rd_lweibull(1.5, 1) =~ /^0\.5284899/, 'rd_lweibull');

ok($mt->rd_double() =~ /^8.6196948.+e-145$/, 'rd_double');

{
  my $seed = 0b1010000100111100011110010000101;
  my $d1 = do { $mt->seed32($seed); $mt->rd_double(); };
  my $d2 = do { $mt->seed32($seed); $mt->rd_double(0); };
  my $d3 = do { $mt->seed32($seed); ($mt->rd_double())[0]; };
  ok($d1 == $d2, 'rd_double(0)');
  ok($d2 == $d3, '(rd_double())[0]');
}

{
  my $state = $mt->getstate();
  ok(length $state > 624*4, 'getstate');
  ok($mt->irand32() == 2_419_637_362, 'irand32 before setstate');
  my $rs = $mt->rd_double(2);

  $mt->setstate($state);
  ok($mt->irand32() == 2_419_637_362, 'irand32 after setstate');
  ok($rs eq $mt->randstr(), 'randstr');
}
