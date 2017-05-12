use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $first = +{
  map {; $_ => 1 } qw/ a b c d e /
};
my $second = hash(
  map {; $_ => 1 } qw/ c d x y  /
);
my $third = +{
  map {; $_ => 1 } qw/ a b c d e f g /
};

my $intersects = $first->intersection($second, $third);
ok $intersects->count == 2, 'boxed intersection returned 2 keys'
  or diag explain $intersects;
is_deeply 
  [ $intersects->sort->all ],
  [ qw/ c d / ],
  'boxed intersection intersection looks ok'
    or diag explain $intersects;

done_testing;
