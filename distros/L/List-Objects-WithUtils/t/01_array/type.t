use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

ok !array->type, 'array() has empty ->type';

done_testing;
