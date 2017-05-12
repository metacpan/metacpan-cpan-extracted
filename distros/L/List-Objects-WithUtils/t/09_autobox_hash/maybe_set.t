use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hash = +{foo => 1, bar => 2, baz => 3};

ok $hash->maybe_set(foo => 3, bar => 4, quux => 5) == $hash,
  'boxed maybe_set returned self ok';

is_deeply
  +{ $hash->export },
  +{ foo => 1, bar => 2, baz => 3, quux => 5 },
  'boxed maybe_set ok';

done_testing
