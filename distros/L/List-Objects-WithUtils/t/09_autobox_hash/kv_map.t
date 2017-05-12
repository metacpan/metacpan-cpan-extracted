use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hs = +{
  foo => 1,
  bar => 2,
  baz => 3,
};

my @res;
my $returned = $hs->kv_map(
  sub { push @res, @_; ($_[0], $_[1] + 1) }
);

is_deeply 
  +{ @res }, 
  $hs->unbless, 
  'boxed kv_map ok';

is_deeply 
  $returned->inflate->unbless,
  +{ foo => 2, bar => 3, baz => 4 },
  'boxed kv_map retval ok';


done_testing
