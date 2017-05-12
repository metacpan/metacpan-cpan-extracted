use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

is_deeply
  [ []->grep(sub { 1 })->all ],
  [ ],
  'boxed empty array grep ok';

my $arr = [qw/ a b c b /];

my $found = $arr->grep(sub { $_ eq 'b' });
is_deeply [ $found->all ], [ ('b') x 2 ], 'boxed grep on topicalizer ok';
$found = $arr->grep(sub { $_[0] eq 'b' });
is_deeply [ $found->all ], [ ('b') x 2 ], 'boxed grep on arg ok';

done_testing;
