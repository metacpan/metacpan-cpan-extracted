use strict;
use warnings;

use Test::More;
use Devel::Unwind;

$SIG{__DIE__} = sub {
    unwind FOO;
};

eval {
    mark FOO {
        eval {
            die "from eval";
            fail "Execution resumes in eval";
        } or do {
            fail "Execution resumes in do-block";
        };
        fail "Execution resumes in after eval but inside mark block";
        1
    };
};
pass "Execution resumes after mark block";
done_testing;
