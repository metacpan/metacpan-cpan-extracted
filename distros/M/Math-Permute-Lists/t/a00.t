use Test::More qw(no_plan);
use strict;

use Math::Permute::Lists;
use Data::Dump qw(dump);

my $a = '';

ok 8 == permute {$a .= "@_\n"} [1,2], [3, 4];

ok $a eq <<END
1 2 3 4
1 2 4 3
2 1 3 4
2 1 4 3
3 4 1 2
3 4 2 1
4 3 1 2
4 3 2 1
END

