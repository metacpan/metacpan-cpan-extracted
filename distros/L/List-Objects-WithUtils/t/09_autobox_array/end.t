use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1, 2, 3 ];
ok $arr->end == 2, 'boxed end ok';
ok []->end == -1, 'empty boxed array end ok';

done_testing;
