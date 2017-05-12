use warnings;
use strict;

use Test::More;
use Devel::Unwind;

mark TOPLEVEL {
    eval {
        unwind TOPLEVEL;
        fail "Execution after die";
        1;
    } or do {
        fail "Execution in do block";
    };
    fail "Execution after eval but inside mark block";
};
pass "Execution resumes after mark block";
done_testing;
