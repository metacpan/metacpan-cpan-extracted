use 5.20.0;

use Test2::V0;

use List::Lazy qw/ :all /;

is lazy_fixed_list( 1..10 )->reduce(sub{ $a + $b }) => 55;

done_testing;
