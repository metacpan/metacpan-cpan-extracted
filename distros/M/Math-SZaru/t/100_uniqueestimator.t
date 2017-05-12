use strict;
use warnings;

use Test::More;
use Math::SZaru;
use Math::SZaru::UniqueEstimator;

SCOPE: {
  my $e = Math::SZaru::UniqueEstimator->new(1000);
  isa_ok($e, 'Math::SZaru::UniqueEstimator');
  is($e->estimate(), 0, "estimate on empty set");
  is($e->tot_elems(), 0, "tot_elems on empty set");

  $e->add_elem("foo");
  $e->add_elems(qw(bar baz));
  $e->add_elem("baz");
  is($e->estimate(), 3, "estimate on smaller-than-exact-storage set");
  is($e->tot_elems(), 4, "tot_elems on smaller-than-exact-storage set");

  $e->add_elem($_) for 1..10000;
  $e->add_elem($_) for 1..10000;
  is($e->tot_elems(), 20004, "tot_elems on large set");
  ok($e->estimate > 7000 && $e->estimate < 13000);
}

pass();
done_testing();

