use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 7 ];
my $before = $arr->items_before(sub { $_ == 4 });
is_deeply
  [ $before->all ],
  [ 1 .. 3 ],
  'boxed items_before ok';

ok []->items_before(sub { $_ == 4 })->is_empty,
  'boxed empty array items_before ok';

$before = [1..3]->items_before(sub { $_ == 1 });
ok $before->is_empty, 'boxed non-matching items_before ok'
  or diag explain $before;

done_testing;
