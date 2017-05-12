use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

ok !defined array->random, 'empty array random ok';

my $arr = array(qw/ foo bar /);
my $random = $arr->random;
ok
  $random eq 'foo' || $random eq 'bar',
  'random() ok';

done_testing;
