use 5.20.0;

use Test2::V0;

use List::Lazy qw/ lazy_fixed_list /;

my $list = lazy_fixed_list( 1..100 )->until(sub{ $_ > 10 });
is [ $list->all ] => [ 1..10 ];

done_testing;
