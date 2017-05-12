use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{ foo => 1, bar => 2 };
is_deeply
  [ $hr->keys->sort->all ],
  [ qw/bar foo/ ],
  'boxed keys ok';

done_testing;
