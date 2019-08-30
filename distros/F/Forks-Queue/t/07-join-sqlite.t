use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('SQLite');

my $TEMP = TEMP_DIR();

exercise_join( impl => 'SQLite', file1 => "$TEMP/q7s",
               file2 => "$TEMP/q7t" );

done_testing;
