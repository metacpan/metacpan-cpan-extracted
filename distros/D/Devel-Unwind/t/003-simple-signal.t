use strict;
use warnings;

use Test::More;
use Devel::Unwind;
use Time::HiRes qw(alarm sleep);

$SIG{ALRM} = sub {
    unwind FOO;
};

mark FOO {
    eval {
        alarm 0.2;
        sleep 0.5;
        fail "Execution resumes in eval after alarm fires";
    } or do {
        fail "Execution resumes in do block for eval after alarm fires";
    };
    fail "Execution resumes after eval but inside mark after alarm fires";
};
pass "Execution resumes after mark block";
done_testing;
