use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [qw/ a b c /];

my $last = $arr->tail;
ok $last eq 'c', 'scalar tail ok';

my ($tail, $remains) = $arr->tail;
ok $tail eq 'c', 'list tail first item ok';
is_deeply
  [ $remains->all ],
  [ qw/ a b / ],
  'list tail second item ok';

done_testing;
