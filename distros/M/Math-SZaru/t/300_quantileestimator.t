use strict;
use warnings;

use Test::More;
use Math::SZaru;
use Math::SZaru::QuantileEstimator;

SCOPE: {
  my $e = Math::SZaru::QuantileEstimator->new(100);
  isa_ok($e, 'Math::SZaru::QuantileEstimator');

  is_deeply($e->estimate(), [0], "estimate on empty set");
  is($e->tot_elems(), 0, "tot_elems on empty set");
  $e->add_elem($_) for 1..50;
  $e->add_elems(51..100);
  is_deeply($e->estimate(), [1..100]);
}

pass();
done_testing();

