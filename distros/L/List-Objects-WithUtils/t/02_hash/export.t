use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hr = hash( foo => 'bar', baz => undef );
is_deeply
  +{ $hr->export },
  +{ foo => 'bar', baz => undef },
  'export ok';

done_testing;
