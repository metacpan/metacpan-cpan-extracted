use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $empty = []->rotator;
ok !defined $empty->(), 'boxed empty rotator returned undef';

my $rotator = [1, 2, 3]->rotator;
my @vals = map {; $rotator->() } 1 .. 7;
is_deeply
  [ @vals ],
  [ 1, 2, 3, 1, 2, 3, 1 ],
  'boxed rotator ok';

done_testing
