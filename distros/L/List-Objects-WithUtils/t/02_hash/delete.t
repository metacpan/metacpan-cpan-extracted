use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hr = hash(foo => 1, baz => 2, bar => 3, quux => 4);
$hr->delete('quux');
ok !$hr->get('quux'), 'delete ok';

my $deleted = $hr->delete('foo', 'baz');
ok $deleted->count == 2, 'deleted 2 elements';
is_deeply
  +{ $hr->export },
  +{ bar => 3 },
  'delete (multi-key) ok';

done_testing;
