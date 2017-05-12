use strict;
use warnings;

use Test::More;
use Devel::Unwind;

mark FOO {
    eval {
        my @a = sort {
            unwind FOO;
        } qw/a b c d/;
        fail "Execution resumes in eval";
        1;
    } or do {
        fail "Execution resumes in do block";
    };
    fail "Execution resumes in after eval but inside mark block";
};
pass "Execution resumes after mark block";
done_testing;
