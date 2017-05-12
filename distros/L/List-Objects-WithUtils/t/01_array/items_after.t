use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 7 );
my $after = $arr->items_after(sub { $_ == 3 });
is_deeply
  [ $after->all ],
  [ 4 .. 7 ],
  'items_after ok';

ok $arr->items_after(sub { $_ > 10 })->is_empty,
  'items_after empty resultset ok';

ok array->items_after(sub { $_ == 1 })->is_empty,
  'items_after on empty array ok';

done_testing;
