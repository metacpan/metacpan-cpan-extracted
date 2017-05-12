use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(qw/ a ba bb c /);

ok $arr->lastidx(sub { /^b/ }) == 2,
  'lastidx ok';

ok $arr->last_index(sub { /^b/ }) == 2,
  'last_index alias ok';

ok $arr->last_index(sub { /d/ }) == -1,
  'negative last_index ok';

ok array->last_index(sub { 1 }) == -1,
  'last_index on empty array ok';

done_testing;
