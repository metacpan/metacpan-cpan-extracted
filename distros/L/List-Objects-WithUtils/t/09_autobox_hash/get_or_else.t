use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{a => 1, b => 2, c => 3, d => 4};

ok $hr->get_or_else('b') == 2, 'boxed single-arg get_or_else ok';
ok !$hr->get_or_else('e'), 'boxed single-arg negative get_or_else ok';

cmp_ok $hr->get_or_else(b => 9), '==', 2,
  'boxed get_or_else found item ok';
cmp_ok $hr->get_or_else(e => 'foo'), 'eq', 'foo',
  'boxed get_or_else defaulted to scalar ok';

my ($invoc, $key);
cmp_ok $hr->get_or_else(e => sub { ($invoc, $key) = @_; 'foo' }),
  'eq', 'foo',
  'boxed get_or_else executed coderef ok';

cmp_ok $invoc, '==', $hr, 'boxed get_or_else coderef invocant ok';
cmp_ok $key, 'eq', 'e',   'boxed get_or_else coderef key ok';

done_testing;
