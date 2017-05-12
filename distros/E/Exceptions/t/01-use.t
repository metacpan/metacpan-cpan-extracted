#!perl

use strict;
use warnings;
use Test::More 0.88; # done_testing()

BEGIN {
    use_ok('Exceptions') or BAIL_OUT("Can't use module");
    use_ok('Exception') or BAIL_OUT("Can't use module");
    use_ok('SimpleException') or BAIL_OUT("Can't use module");
}

done_testing();
