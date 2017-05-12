# (also see utilsby_no_xs.t)
use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(
  +{ id => 2 },
  +{ id => 1 },
  +{ id => 3 },
);

my $sorted = $arr->nsort_by(sub { $_->{id} });

is_deeply
  [ $sorted->all ],
  [ +{ id => 1 }, +{ id => 2 }, +{ id => 3 } ],
  'nsort_by ok';

ok array->nsort_by(sub { $_->foo })->is_empty, 'empty array nsort_by ok';

done_testing;
