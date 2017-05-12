use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(qw/ a b c /);

my $first = $arr->head;
ok $first eq 'a', 'scalar head ok';

my ($head, $tail) = $arr->head;
isa_ok $tail, 'List::Objects::WithUtils::Array';

ok $head eq 'a', 'list head first item ok';
is_deeply
  [ $tail->all ],
  [ qw/ b c / ],
  'list head second item ok';

ok !defined array->head, 'empty array head undef ok';
($head, $tail) = array->head;
ok !defined $head, 'empty array list head first item undef ok';
ok $tail->is_empty, 'empty array list head second item is_empty';

done_testing;
