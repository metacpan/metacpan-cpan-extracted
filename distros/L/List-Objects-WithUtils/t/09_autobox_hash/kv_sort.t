use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{ map {; $_ => 1 } qw/d b c a/ };

is_deeply
  [ $hr->kv_sort->all ],
  [
    [ a => 1 ],
    [ b => 1 ],
    [ c => 1 ],
    [ d => 1 ]
  ],
  'boxed kv_sort ok';

done_testing;
