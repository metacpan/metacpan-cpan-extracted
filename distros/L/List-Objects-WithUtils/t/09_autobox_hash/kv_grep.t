use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hs = +{
  foo => 1,
  bar => 2,
  baz => 3,
};

my $res = $hs->kv_grep(sub { $_[1] > 1 });

is_deeply
  $res->unbless,
  +{ bar => 2, baz => 3 },
  'boxed kv_grep ok';

done_testing
