use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(1 .. 4);
ok $arr->rotate_in_place == $arr, 
  'rotate_in_place returned self ok';
is_deeply
  [ $arr->all ],
  [ 2, 3, 4, 1 ],
  'rotate_in_place default opts ok';

ok $arr->rotate_in_place(right => 1) == $arr,
  'rotate_in_place rightwards returned self ok';
is_deeply
  [ $arr->all ],
  [ 1, 2, 3, 4 ],
  'rotate_in_place rightwards ok';

ok $arr->rotate_in_place(left => 1) == $arr,
  'rotate_in_place leftwards returned self ok';
is_deeply [ $arr->all ],
  [ 2, 3, 4, 1 ],
  'rotate_in_place leftwards ok';


ok array->rotate_in_place->is_empty, 'empty array rotate_in_place ok';


eval {; $arr->rotate_in_place(left => 1, right => 1) };
like $@, qr/direction/, 'bad opts die ok';

done_testing;
