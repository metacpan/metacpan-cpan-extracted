use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [];
$arr->set( 1 => 'bar' );
is_deeply
  [ $arr->all ],
  [ undef, 'bar' ],
  'boxed set on empty list ok';

$arr = [1, 2, 3];
my $set = $arr->set( 1 => 'foo' );
ok $arr == $set, 'boxed set returned self';
is_deeply
  [ $arr->all ],
  [ 1, 'foo', 3 ],
  'boxed set ok';

done_testing;
