use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array', 'hash';

my $first = hash(
  map {; $_ => 1 } qw/ a b c d e /
);
my $second = hash(
  map {; $_ => 1 } qw/ c d x y  /
);
my $third = +{
  map {; $_ => 1 } qw/ a b c d e f g /
};

my $intersects = $first->intersection($second, $third);
ok $intersects->count == 2, '2 keys in intersection'
  or diag explain $intersects;
is_deeply 
  [ $intersects->sort->all ],
  [ qw/ c d / ],
  'intersection looks ok'
    or diag explain $intersects;

my $firstarr  = array(1 .. 10);
my $secondarr = array(5 .. 8, 12, 14, 15);
$intersects = 
  $firstarr->map(sub { $_ => 1 })->inflate
  ->intersection( $secondarr->map(sub { $_ => 1 })->inflate );
is_deeply
  [ $intersects->sort->all ],
  [ 5 .. 8 ],
  'intersection from array looks ok';

done_testing;
