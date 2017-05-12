use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

ok hash->array_type eq 'List::Objects::WithUtils::Array',
  'array_type ok';

done_testing;
