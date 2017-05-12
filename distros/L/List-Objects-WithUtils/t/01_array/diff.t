use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

is_deeply
  [ array(1 .. 3)->diff([ 3, 2, 1 ])->all ],
  [ ],
  'zero element diff ok';

my $first  = array(qw/a b c d e /);
my $second =      [qw/a b c x y /];

my $diff = $first->diff($second);
is_deeply
  [ $diff->sort->all ],
  [ qw/d e x y / ],
  'two-array diff ok'
  or diag explain $diff;

my $third = array(qw/a b c x z /);
$diff = $first->diff($second, $third);
is_deeply
  [ $diff->sort->all ],
  [ qw/d e x y z/ ],
  'three-array diff ok'
  or diag explain $diff;

$diff = array(1 .. 3)->diff( array('2') );
is_deeply
  [ $diff->sort(sub { $_[0] <=> $_[1] })->all ],
  [ 1, 3 ],
  'uneven array diff ok'
  or diag explain $diff;

$diff = array(1 .. 3)->diff(array);
is_deeply
  [ $diff->sort(sub { $_[0] <=> $_[1] })->all ],
  [ 1 .. 3 ],
  'diff against empty array ok'
  or diag explain $diff;

$diff = array->diff( [ 1 .. 3 ] );
is_deeply
  [ $diff->sort(sub { $_[0] <=> $_[1] })->all ],
  [ 1 .. 3 ],
  'diff from empty array ok'
  or diag explain $diff;

ok array->diff(array)->is_empty, 'empty arrays diff ok';

done_testing
