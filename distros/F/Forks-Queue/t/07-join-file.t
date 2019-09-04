use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('File');

my $TEMP = TEMP_DIR();
my $qfile1 = "q7f-$$";
my $qfile2 = "q7g-$$";

exercise_join( impl => 'File', file1 => "$TEMP/$qfile1",
                               file2 => "$TEMP/$qfile2" );

done_testing;
