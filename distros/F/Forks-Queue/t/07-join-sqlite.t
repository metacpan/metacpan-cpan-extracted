use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('SQLite');

my $TEMP = TEMP_DIR();

exercise_join( impl => 'SQLite', file1 => "$TEMP/q11a",
               file2 => "$TEMP/q11b" );

done_testing;
