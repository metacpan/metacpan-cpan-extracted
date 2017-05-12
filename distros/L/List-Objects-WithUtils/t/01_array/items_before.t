use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 7 );
my $before = $arr->items_before(sub { $_ == 4 });
is_deeply
  [ $before->all ],
  [ 1 .. 3 ],
  'items_before ok';

ok array->items_before(sub { $_ == 4 })->is_empty,
  'empty array items_before ok';

$before = array(1..3)->items_before(sub { $_ == 1 });
ok $before->is_empty, 'non-matching items_before ok'
  or diag explain $before;

done_testing;
