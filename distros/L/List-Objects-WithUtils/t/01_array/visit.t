use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(1,2,3);
my $res = [];
array->visit(sub { push @$res, $_ });
is_deeply $res, [], 'empty array visit ok';

my $ret = $arr->visit(sub { push @$res, $_ });
ok $ret == $arr, 'visit returned invocant';
is_deeply $res, [ 1, 2, 3 ], 'visit ok'
  or diag explain $res;

done_testing
