use 5.20.0;

use Test2::V0;

use List::Lazy qw/ lazy_fixed_list /;

my $list = lazy_fixed_list grep { $_ % 2 } 1..10;

is $list->next => 1;

is [ $list->all ], [ 3,5,7,9 ];

done_testing;
