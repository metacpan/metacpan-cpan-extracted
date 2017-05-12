package SimpleTest;
use warnings;
use strict;

our (
    $TEST_ON_IMPORT,
    $TEST_ON_IMPORT_CLASS,
    $TEST_ON_IMPORT_ARGS,

    $TEST_ON_EOF,
    $TEST_ON_EOF_CLASS,

    $TEST_ORDER,
    $TEST_PHASE,
    $TEST_COMPILETIME,
    $TEST_RUNTIME,

    $TEST_MODIFICATION,
);

use SimpleFilter foo => 23, bar => 13;

BEGIN { $TEST_COMPILETIME = 1 if $TEST_PHASE eq 'compile' }

$TEST_RUNTIME = 1 if $TEST_PHASE eq 'run';

1;
