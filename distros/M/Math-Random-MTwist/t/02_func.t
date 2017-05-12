#!/usr/bin/perl

use strict;
use warnings;
use Math::Random::MTwist qw(:rand :seed :dist :state);
use Test::More tests => 24;

# If you change the order of the tests the expected results will change!

ok(srand(1_000_686_894) == 1_000_686_894, 'srand');

ok(irand32() == 2_390_553_143, 'irand32');
{
  my $i = irand64();
  ok(!defined $i || $i == 5_527_845_158, 'irand64');
}
ok(rand()   =~ /^0\.9457734/, 'rand');
ok(rand32() =~ /^0\.3981395/, 'rand32');

ok(rd_erlang(2, 1)  =~ /^1\.2556495/, 'rd_erlang');
ok(rd_lerlang(2, 1) =~ /^0\.3129639/, 'rd_lerlang');

ok(rd_exponential(1)  =~ /^1\.3165971/, 'rd_exponential');
ok(rd_lexponential(1) =~ /^0\.3011559/, 'rd_lexponential');

ok(rd_lognormal(1, 0)  =~ /^0\.8843699/, 'rd_lognormal');
ok(rd_llognormal(1, 0) =~ /^1\.2886502/, 'rd_llognormal');

ok(rd_normal(5, 1)  =~ /^3\.4375795/, 'rd_normal');
ok(rd_lnormal(5, 1) =~ /^4\.8138142/, 'rd_lnormal');

ok(rd_triangular(0, 2, 1)  =~ /^1\.0779715/, 'rd_triangular');
ok(rd_ltriangular(0, 2, 1) =~ /^1\.3103709/, 'rd_ltriangular');

ok(rd_weibull(1.5, 1)  =~ /^0\.7575942/, 'rd_weibull');
ok(rd_lweibull(1.5, 1) =~ /^0\.5284899/, 'rd_lweibull');

ok(rd_double() =~ /^8.6196948.+e-145$/, 'rd_double');

{
  my $seed = 0b1010000100111100011110010000101;
  my $d1 = do { seed32($seed); rd_double(); };
  my $d2 = do { seed32($seed); rd_double(0); };
  my $d3 = do { seed32($seed); (rd_double())[0]; };
  ok($d1 == $d2, 'rd_double(0)');
  ok($d2 == $d3, '(rd_double())[0]');
}

{
  my $state = getstate();
  ok(length $state > 624*4, 'getstate');
  ok(irand32() == 2_419_637_362, 'irand32 before setstate');
  my $rs = rd_double(2);

  setstate($state);
  ok(irand32() == 2_419_637_362, 'irand32 after setstate');
  ok($rs eq randstr(), 'randstr');
}
