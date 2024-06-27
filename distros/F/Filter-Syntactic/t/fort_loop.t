use 5.022;
use warnings;


use Test::More;

plan tests => 3;

use lib qw< ./tlib ./t/tlib >;
use FortLoop -debug;

fort my $count (1..3) {
    note "...in loop $count";
}

for my $count (4..6) {
    note "...in loop $count";
}

done_testing();


