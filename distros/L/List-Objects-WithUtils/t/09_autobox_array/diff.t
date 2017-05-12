use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

is_deeply
  [ [1 .. 3]->diff([ 3, 2, 1 ])->all ],
  [ ],
  'zero element diff ok';

my $first  = [qw/a b c d e /];
my $second = [qw/a b c x y /];

my $diff = $first->diff($second);
is_deeply
  [ $diff->sort->all ],
  [ qw/d e x y / ],
  'boxed two-array diff ok'
  or diag explain $diff;

$diff = [1 .. 3]->diff(array);
is_deeply
  [ $diff->sort(sub { $_[0] <=> $_[1] })->all ],
  [ 1 .. 3 ],
  'boxed diff against empty array ok'
  or diag explain $diff;

done_testing
