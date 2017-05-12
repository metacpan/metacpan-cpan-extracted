use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(qw/ a b c d /);
my $spliced = $arr->splice(2);
is_deeply
  [ $arr->all ],
  [ qw/ a b / ],
  'single arg splice modified orig ok';
is_deeply
  [ $spliced->all ],
  [ qw/ c d / ],
  'single arg splice ok';

$arr = array(qw/ a b c d /);
$spliced = $arr->splice(1, 3);
is_deeply
  [ $arr->all ],
  [ 'a' ],
  '2-arg splice modified orig ok';
is_deeply
  [ $spliced->all ],
  [ qw/ b c d / ],
  '2-arg splice ok';

$spliced->splice(2, 1, 'e');
is_deeply
  [ $spliced->all ],
  [ qw/ b c e / ],
  '3-arg splice ok';

done_testing;
