use strict;
use warnings;

use Test::More;
use Devel::Unwind;

use lib 't/lib';

mark FOO {
    eval {
        require "required_unwind_fail.pm";
        fail "Execution resumes in eval";
        1;
    } or do {
        fail "Execution resumes in do block";
    };
    fail "Execution resumes after eval but inside mark block";
};
pass "Execution resumes after mark block";
done_testing;
