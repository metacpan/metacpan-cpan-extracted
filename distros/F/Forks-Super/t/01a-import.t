use Forks::Super MAX_PROC => 9, CHILD_FORK_OK => -1;
use strict;
use warnings;

if (eval 'use Test::More tests => 2;1' ) {
    ok($Forks::Super::MAX_PROC == 9, 'MAX_PROC set on import');
    ok($Forks::Super::CHILD_FORK_OK == -1, 'CHILD_FORK_OK set on import');
} else {
    print "1..2\n";
    print $Forks::Super::MAX_PROC==9 ? "ok 1\n" : "not ok 1\n";
    print $Forks::Super::CHILD_FORK_OK == -1 ? "ok 2\n" : "not ok 2\n";
}

