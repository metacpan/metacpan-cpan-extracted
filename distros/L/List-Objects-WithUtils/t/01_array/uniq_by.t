# (also see utilsby_no_xs.t)
use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(
  { id => 1 },
  { id => 2 },
  { id => 1 },
  { id => 3 },
  { id => 3 },
);
my $uniq = $arr->uniq_by(sub { $_->{id} });
is_deeply
  [ $uniq->all ],
  [
    { id => 1 },
    { id => 2 },
    { id => 3 },
  ],
  'uniq_by ok';

ok array->uniq_by(sub { $_->foo })->is_empty, 'empty array uniq_by ok';

done_testing;
