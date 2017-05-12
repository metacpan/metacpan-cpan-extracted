use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [4];
my $unshifted = $arr->unshift( 1 .. 3 );
ok $unshifted == $arr, 'boxed unshift returned self';
is_deeply
  [ $arr->all ],
  [ 1 .. 4 ],
  'boxed unshift ok';

ok []->unshift(1)->count == 1, 'unshift to empty array ok';

done_testing;
