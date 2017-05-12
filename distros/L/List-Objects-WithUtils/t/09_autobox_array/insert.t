use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [];

my $insert = $arr->insert(0 => 1);
ok $insert == $arr, 'boxed insert returned self ok';
is_deeply
  [ $arr->all ],
  [ 1 ],
  'boxed insert first position on empty list ok';

$arr->insert(4 => 2);
is_deeply
  [ $arr->all ],
  [ 1, undef, undef, undef, 2 ],
  'boxed insert pre-filled nonexistant elems ok';

$arr->insert(3 => 3);
is_deeply
  [ $arr->all ],
  [ 1, undef, undef, 3, undef, 2 ],
  'boxed insert to middle ok';

done_testing;
