use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 7 );
my $after = $arr->items_after_incl(sub { $_ == 3 });
is_deeply
  [ $after->all ],
  [ 3 .. 7 ],
  'items_after_incl ok';

ok $arr->items_after_incl(sub { $_ > 10 })->is_empty,
  'items_after_incl empty resultset ok';

ok array->items_after_incl(sub { $_ == 1 })->is_empty,
  'items_after_incl on empty array ok';

done_testing;
