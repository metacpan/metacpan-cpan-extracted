use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hs = hash(
  foo => 1,
  bar => 2,
  baz => 3,
);

my $iter = $hs->iter;

my %result;
while (my ($k, $v) = $iter->()) {
  $result{$k} = $v
}

is_deeply 
  +{ %result },
  +{ foo => 1, bar => 2, baz => 3 },
  'iter() ok';

ok !hash->iter->(), 'empty hash iter() ok';

done_testing
