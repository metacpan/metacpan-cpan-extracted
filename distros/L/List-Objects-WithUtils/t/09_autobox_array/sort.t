use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

ok []->sort->is_empty, 'boxed empty array sort ok';

my $arr = [4, 2, 3, 1];
my $sorted = $arr->sort(sub { $_[0] <=> $_[1] });
is_deeply
  [ $sorted->all ],
  [ 1, 2, 3, 4 ],
  'boxed sort ok';

my $warned;
$SIG{__WARN__} = sub { $warned = shift };

$sorted = $arr->sort(sub { $a <=> $b });
is_deeply
  [ $sorted->all ],
  [ 1, 2, 3, 4 ],
  'boxed sort ok';

ok !$warned, 'using $a/$b produced no warnings'
  or fail 'using $a/$b produced warning: '.$warned;

done_testing;
