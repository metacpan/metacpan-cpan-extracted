use strict;
use warnings;

use Test::More;
use Math::SZaru;
use Math::SZaru::TopEstimator;

SCOPE: {
  my $e = Math::SZaru::TopEstimator->new(1000);
  isa_ok($e, 'Math::SZaru::TopEstimator');

  is_deeply($e->estimate(), [], "estimate on empty set");
  is($e->tot_elems(), 0, "tot_elems on empty set");

  $e->add_elem("foo");
  $e->add_elem("bar");
  $e->add_elems(qw(bar baz));
  $e->add_elem("baz");
  $e->add_elem("baz");
  is_deeply($e->estimate(), [[baz => 3,], [bar => 2], [foo => 1]], "estimate on smaller-than-exact-storage set");
  is($e->tot_elems(), 6, "tot_elems on smaller-than-exact-storage set");

  $e->add_weighted_elem("blarg", 100);
  is_deeply($e->estimate(), [[blarg => 100], [baz => 3,], [bar => 2], [foo => 1]], "estimate on smaller-than-exact-storage set");
  is($e->tot_elems(), 7, "tot_elems on smaller-than-exact-storage set");

  $e = Math::SZaru::TopEstimator->new(100);
  isa_ok($e, 'Math::SZaru::TopEstimator');
  $e->add_weighted_elems(1000, 3, 100, 1, 20, 3, "foo", 1);
  for my $x (1..500) {
    $e->add_weighted_elem($x, $x);
    $e->add_elem($x) for 1..20;
  }
  is($e->tot_elems(), 4 + 500 + 500 * 20);
  is($e->estimate()->[0][0], 500);
}

pass();
done_testing();

