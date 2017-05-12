use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hr = hash(a => 1, b => 2, c => 3, d => 4 );

ok $hr->get('b') == 2, 'get ok';

my $results = $hr->get('b', 'c');
ok 
  $results->has_any(sub { $_ == 2 })
  && $results->has_any(sub { $_ == 3 }),
  'multi-key get ok';

done_testing;
