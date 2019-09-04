use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('Shmem');

my $TEMP = TEMP_DIR();
diag "$0: temp dir is $TEMP";
my $qfile1 = "q7m-$$";
my $qfile2 = "q7n-$$";

unlink "$TEMP/$qfile1", "$TEMP/$qfile2";

exercise_join( impl => 'Shmem', file1 => "$qfile1", file2 => "$qfile2" );

done_testing;
