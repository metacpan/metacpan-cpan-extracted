use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hs = +{
  foo => 1,
  bar => 2,
  baz => 3,
};

my $iter = $hs->iter;

my %result;
while (my ($k, $v) = $iter->()) {
  $result{$k} = $v
}

is_deeply 
  +{ %result },
  +{ foo => 1, bar => 2, baz => 3 },
  'boxed iter() ok';

done_testing
