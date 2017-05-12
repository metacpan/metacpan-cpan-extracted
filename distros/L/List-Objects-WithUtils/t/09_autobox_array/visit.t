use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [1,2,3];
my $res = [];
[]->visit(sub { push @$res, $_ });
is_deeply $res, [], 'boxed empty array visit ok';

$arr->visit(sub { push @$res, $_ });
is_deeply $res, [ 1, 2, 3 ], 'boxed visit ok'
  or diag explain $res;

done_testing
