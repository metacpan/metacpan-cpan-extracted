# (also see utilsby_no_xs.t)
use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [
  { id => 1 },
  { id => 2 },
  { id => 1 },
  { id => 3 },
  { id => 3 },
];
my $uniq = $arr->uniq_by(sub { $_->{id} });
is_deeply
  [ $uniq->all ],
  [
    { id => 1 },
    { id => 2 },
    { id => 3 },
  ],
  'boxed uniq_by ok';

done_testing;
