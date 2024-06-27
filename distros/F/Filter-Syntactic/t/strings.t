use 5.022;
use warnings;


use Test::More;

plan tests => 3;

use lib qw< ./tlib ./t/tlib >;
use StringTests;

note "this is now a test";

"this is also a test";

"a final test";

done_testing();

