use strict;
use warnings;

use Test::More;
use Devel::Unwind;

eval {
    mark FOO {
        return 1;
    };
    return 1;
} or do {
    fail "Died when returning from mark";
};

mark FOOBAR {
    unwind FOOBAR;
    fail "Execution resumed inside mark FOOBAR after unwind";
};
pass "Execution resumed after mark";
done_testing;
