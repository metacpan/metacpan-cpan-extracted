use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

is_deeply
  [ array->grep(sub { 1 })->all ],
  [ ],
  'empty array grep ok';

my $arr = array(qw/ a b c b /);

my $found = $arr->grep(sub { $_ eq 'b' });
is_deeply [ $found->all ], [ ('b') x 2 ], 'grep on topicalizer ok';
$found = $arr->grep(sub { $_[0] eq 'b' });
is_deeply [ $found->all ], [ ('b') x 2 ], 'grep on arg ok';

done_testing;
