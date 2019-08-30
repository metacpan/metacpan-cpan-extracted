use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('Shmem');

my $TEMP = TEMP_DIR();
diag "$0: temp dir is $TEMP";

unlink "$TEMP/q7m", "$TEMP/q7n";

exercise_join( impl => 'Shmem', file1 => "q7m", file2 => "q7n" );

done_testing;
