use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(qw/ a ba bb c /);
my $firstidx = $arr->firstidx(sub { /^b/ });
ok $firstidx == 1, 'firstidx ok';
ok $arr->first_index(sub { /^b/ }) == $firstidx,
  'first_index alias ok';

ok $arr->first_index(sub { /c/ }) == 3,
  'firstidx ok';

ok $arr->first_index(sub { /d/ }) == -1,
  'negative first_index ok';

ok array->first_index(sub { 1 }) == -1,
  'first_index on empty array ok';

done_testing;
