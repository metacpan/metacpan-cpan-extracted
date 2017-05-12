use Test::More 'no_plan';

use List::Maker;

sub odd { shift() % 2 }

is_deeply [<1..10 : odd X>],     [1,3,5,7,9]    => '<1..10 : odd X>';
is_deeply [<1..10x3 : odd N>],   [1,7]          => '<1..10x3 : odd N>';
is_deeply [<1,5..10 : odd I>],   [1,5,9]        => '<1,5..10 : odd I>';
is_deeply [<1,5..10 : odd \$_>], [1,5,9]        => '<1,5..10 : odd \\$_>';
is_deeply [<1..20 : /7/>],       [7,17]         => '<1..20 : /7/>';
