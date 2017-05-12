use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hs = hash(
  foo => 1,
  bar => 2,
  baz => 3,
);

my @res;
my $returned = $hs->kv_map(
  sub { push @res, @_; ($_[0], $_[1] + 1) }
);

is_deeply 
  +{ @res }, 
  $hs->unbless, 
  'kv_map (positional) input ok';

is_deeply 
  $returned->inflate->unbless,
  +{ foo => 2, bar => 3, baz => 4 },
  'kv_map (positional) retval ok';


my $warned;
$SIG{__WARN__} = sub { $warned = shift };

$returned = $hs->kv_map(
  sub { push @res, $a, $b; ($a, $b + 1) }
);

is_deeply 
  +{ @res }, 
  $hs->unbless, 
  'kv_map (named) input ok';

is_deeply 
  $returned->inflate->unbless,
  +{ foo => 2, bar => 3, baz => 4 },
  'kv_map (named) retval ok';

ok !$warned, '$a/$b vars produced no warning'
  or fail 'using $a/$b produced warning: '.$warned;

done_testing
