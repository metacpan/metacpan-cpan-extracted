use strict;
use warnings;

use JavaBin;
use Test::More;

for ( .1, 1.23, 3.14159 ) {
    is from_javabin( to_javabin $_ ), $_, $_;
}

done_testing;
