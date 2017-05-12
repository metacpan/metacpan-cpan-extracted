use Test::More tests => 1;

use List::Lazy qw/ lazy_fixed_list /;

my $list = ( lazy_fixed_list 1..5 );

is_deeply [ $list->batch(2)->all ], [ [1,2], [3,4], [5] ];
