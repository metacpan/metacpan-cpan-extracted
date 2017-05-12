use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [1 .. 4];
ok $arr->rotate_in_place == $arr, 
  'boxed rotate_in_place returned self ok';
is_deeply
  [ $arr->all ],
  [ 2, 3, 4, 1 ],
  'boxed rotate_in_place ok';

done_testing;
