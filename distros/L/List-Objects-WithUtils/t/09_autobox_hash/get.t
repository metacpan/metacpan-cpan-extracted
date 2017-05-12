use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{a => 1, b => 2, c => 3, d => 4};

ok $hr->get('b') == 2, 'boxed get ok';

my $results = $hr->get('b', 'c');
ok 
  $results->has_any(sub { $_ == 2 })
  && $results->has_any(sub { $_ == 3 }),
  'boxed multi-key get ok';

done_testing;
