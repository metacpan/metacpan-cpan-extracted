use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array;

my $insert = $arr->insert(0 => 1);
ok $insert == $arr, 'insert returned self ok';
is_deeply
  [ $arr->all ],
  [ 1 ],
  'insert first position on empty list ok';

$arr->insert(4 => 2);
is_deeply
  [ $arr->all ],
  [ 1, undef, undef, undef, 2 ],
  'insert pre-filled nonexistant elems ok';

$arr->insert(3 => 3);
is_deeply
  [ $arr->all ],
  [ 1, undef, undef, 3, undef, 2 ],
  'insert to middle ok';

$arr->insert(5 => 5);
is_deeply
  [ $arr->all ],
  [ 1, undef, undef, 3, undef, 5, 2 ],
  'insert next-to-last ok';

$arr->insert( 7 => 7 );
is_deeply
  [ $arr->all ],
  [ 1, undef, undef, 3, undef, 5, 2, 7 ],
  'insert last ok';

$arr->insert( 9 => 9 );
is_deeply
  [ $arr->all ],
  [ 1, undef, undef, 3, undef, 5, 2, 7, undef, 9 ],
  'insert one-off last ok';

$arr->insert( 0 => 0 );
is_deeply
  [ $arr->all ],
  [ 0, 1, undef, undef, 3, undef, 5, 2, 7, undef, 9 ],
  'insert first ok';

$arr->insert( 2 => 0, 1, 2 );
is_deeply
  [ $arr->all ],
  [ 0, 1, 0, 1, 2,  undef, undef, 3, undef, 5, 2, 7, undef, 9 ],
  'insert multiple ok';

done_testing;
