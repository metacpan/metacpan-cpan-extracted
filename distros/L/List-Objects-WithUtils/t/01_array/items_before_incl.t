use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 7 );
my $before = $arr->items_before_incl(sub { $_ == 4 });
is_deeply
  [ $before->all ],
  [ 1 .. 4 ],
  'items_before_incl ok';

ok array->items_before_incl(sub { $_ == 1 })->is_empty,
  'items_before_incl on empty array ok';

done_testing;
