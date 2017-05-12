use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 7 ];
my $after = $arr->items_after_incl(sub { $_ == 3 });
is_deeply
  [ $after->all ],
  [ 3 .. 7 ],
  'boxed items_after_incl ok';

ok $arr->items_after_incl(sub { $_ > 10 })->is_empty,
  'boxed items_after_incl empty resultset ok';

ok []->items_after_incl(sub { $_ == 1 })->is_empty,
  'boxed items_after_incl on empty array ok';

done_testing;
