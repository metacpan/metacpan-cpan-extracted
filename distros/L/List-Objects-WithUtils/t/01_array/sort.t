use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

ok array->sort->is_empty, 'empty array sort ok';

my $arr = array(4, 2, 3, 1);
my $sorted = $arr->sort(sub { $_[0] <=> $_[1] });
is_deeply
  [ $sorted->all ],
  [ 1, 2, 3, 4 ],
  'sort with positional args ok';


$sorted = $arr->sort;
is_deeply
  [ $sorted->all ],
  [ 1, 2, 3, 4 ],
  'sort with default sub ok';

is_deeply [ $arr->sort(undef)->all ], [ $arr->sort->all ],
  'sort non-subroutine (false) arg ok';
eval {; $arr->sort(1) };
ok $@, 'sort non-subroutine (true) arg dies ok';

my $warned;
$SIG{__WARN__} = sub { $warned = shift };

$sorted = $arr->sort(sub { $a <=> $b });
is_deeply
  [ $sorted->all ],
  [ 1, 2, 3, 4 ],
  'sort with named args ok';

ok !$warned, 'using $a/$b produced no warnings'
  or fail 'using $a/$b produced warning: '.$warned;

done_testing;
