use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(qw/ a b c /);

my $last = $arr->tail;
ok $last eq 'c', 'scalar tail ok';

my ($tail, $remains) = $arr->tail;
ok $tail eq 'c', 'list tail first item ok';
is_deeply
  [ $remains->all ],
  [ qw/ a b / ],
  'list tail second item ok';

ok !defined array->tail , 'empty array scalar tail undef ok';
($tail, $remains) = array->tail;
ok !defined $tail, 'empty array list tail first item undef ok';
ok $remains->is_empty, 'empty array list tail second item is_empty ok';

done_testing;
