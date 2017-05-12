use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('Shmem');

my $TEMP = TEMP_DIR();
diag "$0: temp dir is $TEMP";

unlink "$TEMP/q11a", "$TEMP/q11b";

exercise_join( impl => 'Shmem', file1 => "q11a", file2 => "q11b" );

done_testing;
