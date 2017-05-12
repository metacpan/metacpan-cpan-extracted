use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [qw/ a b c /];

my $first = $arr->head;
ok $first eq 'a', 'boxed scalar head ok';

my ($head, $tail) = $arr->head;
isa_ok $tail, 'List::Objects::WithUtils::Array';
ok $head eq 'a', 'boxed list head first item ok';
is_deeply
  [ $tail->all ],
  [ qw/ b c / ],
  'boxed list head second item ok';

done_testing;
