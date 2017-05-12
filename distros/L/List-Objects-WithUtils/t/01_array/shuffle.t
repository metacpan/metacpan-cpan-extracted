use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(1, 2, 3);
my $shuffled = $arr->shuffle;

ok
  $shuffled->has_any(sub { $_ == 1 })
  && $shuffled->has_any(sub { $_ == 2 })
  && $shuffled->has_any(sub { $_ == 3 })
  && $shuffled->count == 3,
  'shuffle() ok';

is_deeply
  [ $arr->all ],
  [ 1, 2, 3 ],
  'original array intact';


ok array->shuffle->is_empty, 'empty array shuffle ok';

done_testing;
