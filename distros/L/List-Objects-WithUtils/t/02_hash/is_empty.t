use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

ok hash->is_empty, 'is_empty ok';
ok !hash(foo => 1)->is_empty, 'negative is_empty ok';

done_testing;
