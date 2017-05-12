use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';
my $hr = hash( foo => 1, bar => 2 );
is_deeply
  [ $hr->keys->sort->all ],
  [ qw/bar foo/ ],
  'keys() ok';

done_testing;
