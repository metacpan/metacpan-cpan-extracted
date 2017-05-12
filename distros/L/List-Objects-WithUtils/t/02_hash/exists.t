use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hr = hash(foo => 1, baz => 2);
ok $hr->exists('foo'), 'exists ok';
ok !$hr->exists('bar'), 'negative exists ok';

done_testing;
