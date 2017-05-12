use strict;
use warnings;

use Test::More;
use Test::Exception;

use Math::BigInt;

BEGIN { use_ok 'Math::Random::Xorshift' => qw/rand srand irand/ }

lives_ok { Math::Random::Xorshift::srand } 'Default seeds';
dies_ok  { Math::Random::Xorshift::srand(0) } 'Zero seed';
lives_ok { Math::Random::Xorshift::srand(42) } 'Proper seed';
dies_ok  { Math::Random::Xorshift::srand(0, 0, 0, 0) } '4 zero seeds';
lives_ok { Math::Random::Xorshift::srand(42, 42, 42, 42) } '4 proper seeds';

Math::Random::Xorshift::srand;

IRAND_RANGE_TEST: {
  my $lim = Math::BigInt->new(1) << 32;
  my $msg = 'range of irand() is [0, UINT32_MAX)';
  for (0 .. 9_999) {
    my $rand = Math::Random::Xorshift::irand;
    unless (0 <= $rand and $rand < $lim) {
      ok(0, $msg);
      last IRAND_RANGE_TEST;
    }
  }
  ok(1, $msg);
}

RAND_RANGE_TEST: {
  my $msg = 'range of rand() is [0, $upper_limit)';
  for my $lim (1 .. 3) {
    for (0 .. 9_999) {
      my $rand = Math::Random::Xorshift::rand($lim);
      unless (0 <= $rand and $rand < $lim) {
        ok(0, $msg);
        last RAND_RANGE_TEST;
      }
    }
  }
  ok(1, $msg);
}

done_testing;
