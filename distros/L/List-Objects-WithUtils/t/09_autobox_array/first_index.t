use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [qw/ a ba bb c /];
my $firstidx = $arr->firstidx(sub { /^b/ });
ok $firstidx == 1, 'boxed firstidx ok';
ok $arr->first_index(sub { /^b/ }) == $firstidx,
  'boxed first_index alias ok';
ok $arr->first_index(sub { /d/ }) == -1,
  'boxed negative first_index ok';
ok []->first_index(sub { 1 }) == -1,
  'boxed first_index on empty array ok';

done_testing;
