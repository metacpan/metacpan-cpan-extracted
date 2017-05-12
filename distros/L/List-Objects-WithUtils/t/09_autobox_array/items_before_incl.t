use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 7 ];
my $before = $arr->items_before_incl(sub { $_ == 4 });
is_deeply
  [ $before->all ],
  [ 1 .. 4 ],
  'boxed items_before_incl ok';

ok []->items_before_incl(sub { $_ == 1 })->is_empty,
  'boxed items_before_incl on empty array ok';

done_testing;
