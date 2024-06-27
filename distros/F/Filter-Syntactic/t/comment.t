use 5.022;
use warnings;


use Test::More;

plan tests => 5;

use lib qw< ./tlib ./t/tlib >;
use CommenTest;

my $x = 1;
### This is a test: $x == 1

### This is another test: -r __FILE__()

for (1..3) {
    ### This is also a test ($_): 1 <= $_ && $_ <= 3
}

done_testing();



