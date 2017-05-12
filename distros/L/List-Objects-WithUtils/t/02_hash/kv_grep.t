use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hs = hash(
  foo => 1,
  bar => 2,
  baz => 3,
);

my $res = $hs->kv_grep(sub { $_[1] > 1 });

is_deeply
  $res->unbless,
  +{ bar => 2, baz => 3 },
  'kv_grep (positional args) ok';

my $warned;
$SIG{__WARN__} = sub { $warned = shift };

$res = $hs->kv_grep(sub { $b > 1 });
is_deeply
  $res->unbless,
  +{ bar => 2, baz => 3 },
  'kv_grep (named args) ok';

ok !$warned, '$a/$b vars produced no warning'
  or fail 'using $a/$b produced warning: '.$warned;

done_testing
