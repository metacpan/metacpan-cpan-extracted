# Make sure we allow a trailing comma.

use strict;
use warnings;

use Test::More;

use Dios;

func foo($foo, $bar,) {
    return [$foo, $bar];
}

is_deeply foo(23, 42), [23, 42];

done_testing;
