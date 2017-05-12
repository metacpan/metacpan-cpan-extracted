use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{
  scalar => 1,

  hash => +{
    a => 1,
    b => +{
      x => 10
    },
  },

  hashobj => hash(
    d => [],
    e => [
      1, { z => 9 },
    ],
  ),
};

cmp_ok $hr->get_path('scalar'), '==', 1,
  'boxed shallow get_path ok';

cmp_ok $hr->get_path(qw/hash b x/), '==', 10,
  'boxed deep get_path ok';

done_testing
