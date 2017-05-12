use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 7 ];
my $after = $arr->items_after(sub { $_ == 3 });
is_deeply
  [ $after->all ],
  [ 4 .. 7 ],
  'boxed items_after ok';

ok $arr->items_after(sub { $_ > 10 })->is_empty,
  'boxed items_after empty resultset ok';

ok []->items_after(sub { $_ == 1 })->is_empty,
  'boxed items_after on empty array ok';

done_testing;
