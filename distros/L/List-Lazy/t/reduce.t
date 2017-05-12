use 5.20.0;

use Test::More tests => 1;

use List::Lazy qw/ :all /;

is lazy_fixed_list( 1..10 )->reduce(sub{ $a + $b }) => 55;
