use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

ok []->reverse->is_empty, 'empty array reverse ok';

my $arr = [1, 2, 3];
my $reverse = $arr->reverse;
is_deeply
  [ $reverse->all ],
  [ 3, 2, 1 ],
  'boxed reverse ok';

is_deeply
  [ $arr->all ],
  [ 1, 2, 3 ],
  'original intact';

done_testing;
