use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array;
ok $arr->is_empty, 'is_empty ok';
$arr->push(1);
ok !$arr->is_empty, 'negative is_empty ok';

done_testing;
