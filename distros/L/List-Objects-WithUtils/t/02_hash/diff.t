use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $first = hash(a => 1, b => 2, c => 3, d => 4);
my $second =   +{a => 1, b => 2, x => 1, y => 2};

my $diff = $first->diff($second);
is_deeply
  [ $diff->sort->all ],
  [ qw/c d x y/ ],
  'two-hash diff ok'
  or diag explain $diff;

my $third = hash(a => 1, b => 2, c => 3, e => 1);
$diff = $third->diff($first, $second);
is_deeply
  [ $diff->sort->all ],
  [ qw/c d e x y/ ],
  'three-hash diff ok'
  or diag explain $diff;

done_testing
