# (also see utilsby_no_xs.t)
use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [
  +{ id => 2 },
  +{ id => 1 },
  +{ id => 3 },
];

my $sorted = $arr->nsort_by(sub { $_->{id} });

is_deeply
  [ $sorted->all ],
  [ +{ id => 1 }, +{ id => 2 }, +{ id => 3 } ],
  'boxed nsort_by ok';

done_testing;
