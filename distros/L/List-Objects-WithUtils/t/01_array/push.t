use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(0);
my $pushed = $arr->push( 1 .. 3 );
ok $pushed == $arr, 'push returned self';
is_deeply
  [ $arr->all ],
  [ 0 .. 3 ],
  'push ok';

done_testing;
