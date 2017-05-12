use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 10 ];

my $threeper = $arr->ssect(3);

ok $threeper->count == 4, 'boxed ssect(3) returned four items';
my $res = []->ssect(3);
ok $res->is_empty,
  'boxed ssect on empty array produced empty array'
    or diag explain $res;

done_testing;
