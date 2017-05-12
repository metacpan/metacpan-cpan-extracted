use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

ok +{}->array_type eq 'List::Objects::WithUtils::Array',
  'autoboxed array_type ok';

done_testing;
