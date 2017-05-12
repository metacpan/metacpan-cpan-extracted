use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $first  = +{a => 1, b => 2, c => 3, d => 4};
my $second = +{a => 1, b => 2, x => 1, y => 2};

my $diff = $first->diff($second);
is_deeply
  [ $diff->sort->all ],
  [ qw/c d x y/ ],
  'boxed two-hash diff ok'
  or diag explain $diff;

done_testing
