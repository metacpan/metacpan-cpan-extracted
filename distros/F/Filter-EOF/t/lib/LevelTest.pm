package LevelTest;
use warnings;
use strict;

our (
    $COMPILE_TIME,

    $TEST_COMPILETIME,
    $TEST_RUNTIME,
);

use LevelFilter foo => 12;

BEGIN { $TEST_COMPILETIME = 1 if $COMPILE_TIME == 1 }

$TEST_RUNTIME = 1 if $COMPILE_TIME == 0;

1;
