use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [1 .. 4];
my $left = $arr->rotate;
is_deeply
  [ $left->all ],
  [ 2, 3, 4, 1 ],
  'boxed rotate ok';
is_deeply
  [ $arr->all ],
  [ 1, 2, 3, 4 ],
  'original array intact';

done_testing
