use strict;
use warnings;

use Test::More;
use Test::Exception;

use Math::BigInt;

BEGIN { use_ok 'Math::Random::Xorshift' }

lives_ok { Math::Random::Xorshift->new } 'Default seeds';
dies_ok  { Math::Random::Xorshift->new(0) } 'Zero seed';
lives_ok { Math::Random::Xorshift->new(42) } 'Proper seed';
dies_ok  { Math::Random::Xorshift->new(0, 0, 0, 0) } '4 zero seeds';
lives_ok { Math::Random::Xorshift->new(42, 42, 42, 42) } '4 proper seeds';
dies_ok  { Math::Random::Xorshift->new(42, 42, 42, 42, 42) } 'Too many seeds';

IRAND_RANGE_TEST: {
  my $rng = Math::Random::Xorshift->new;
  my $lim = Math::BigInt->new(1) << 32;
  my $msg = 'range of irand() is [0, UINT32_MAX)';
  for (0 .. 9_999) {
    my $rand = $rng->irand;
    unless (0 <= $rand and $rand < $lim) {
      ok(0, $msg);
      last IRAND_RANGE_TEST;
    }
  }
  ok(1, $msg);
}

RAND_RANGE_TEST: {
  my $rng = Math::Random::Xorshift->new;
  my $msg = 'range of rand() is [0, $upper_limit)';
  for my $lim (1 .. 3) {
    for (0 .. 9_999) {
      my $rand = $rng->rand($lim);
      unless (0 <= $rand and $rand < $lim) {
        ok(0, $msg);
        last RAND_RANGE_TEST;
      }
    }
  }
  ok(1, $msg);
}

done_testing;
