use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $empty = array->rotator;
ok !defined $empty->(), 'empty rotator ok';

my $rotator = array(1, 2, 3)->rotator;

my @vals = map {; $rotator->() } 1 .. 7;
is_deeply
  [ @vals ],
  [ 1, 2, 3, 1, 2, 3, 1 ],
  'rotator ok';

done_testing
