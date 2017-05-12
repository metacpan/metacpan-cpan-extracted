use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [0];
my $pushed = $arr->push( 1 .. 3 );
ok $pushed == $arr, 'boxed push returned self';
is_deeply
  [ $arr->all ],
  [ 0 .. 3 ],
  'boxed push ok';

done_testing;
