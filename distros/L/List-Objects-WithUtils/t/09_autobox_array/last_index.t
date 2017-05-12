use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [qw/ a ba bb c /];

ok $arr->lastidx(sub { /^b/ }) == 2,
  'boxed lastidx ok';
ok $arr->last_index(sub { /d/ }) == -1,
  'boxed negative last_index ok';
ok []->last_index(sub { 1 }) == -1,
  'boxed last_index on empty array ok';

done_testing;
