use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [1, 2, 3];
my $shuffled = $arr->shuffle;

ok
  $shuffled->has_any(sub { $_ == 1 })
  && $shuffled->has_any(sub { $_ == 2 })
  && $shuffled->has_any(sub { $_ == 3 })
  && $shuffled->count == 3,
  'boxed shuffle ok';

is_deeply
  [ $arr->all ],
  [ 1, 2, 3 ],
  'original array intact';

done_testing;
