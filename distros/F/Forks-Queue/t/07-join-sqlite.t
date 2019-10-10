use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('SQLite');

my $TEMP = TEMP_DIR();

exercise_join( impl => 'SQLite', file1 => "$TEMP/q7s-$$",
               file2 => "$TEMP/q7t-$$" );

done_testing;

unlink "$TEMP/q7s-$$", "$TEMP/q7s-$$.result";

