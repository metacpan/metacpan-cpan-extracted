use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(1, undef, 3);

ok $arr->defined(0),  'defined(0) ok';
ok !$arr->defined(1), '!defined(1) ok';
ok $arr->defined(2),  'defined(2) ok';
ok !$arr->defined(3), '!defined(3) ok';

done_testing
