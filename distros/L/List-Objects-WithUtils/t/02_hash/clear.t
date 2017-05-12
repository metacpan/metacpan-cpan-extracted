use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hr = hash(foo => 1, bar => 2);
ok $hr->clear == $hr, 'clear returned self';
ok $hr->is_empty, 'clear ok';

done_testing;
