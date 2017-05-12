use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [qw/ a b c d /];
my $spliced = $arr->splice(2);
is_deeply
  [ $arr->all ],
  [ qw/ a b / ],
  'boxed single arg splice modified orig ok';
is_deeply
  [ $spliced->all ],
  [ qw/ c d / ],
  'boxed single arg splice ok';

$arr = [qw/ a b c d /];
$spliced = $arr->splice(1, 3);
is_deeply
  [ $arr->all ],
  [ 'a' ],
  'boxed 2-arg splice modified orig ok';
is_deeply
  [ $spliced->all ],
  [ qw/ b c d / ],
  'boxed 2-arg splice ok';

done_testing;
