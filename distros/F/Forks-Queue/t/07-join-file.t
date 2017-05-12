use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('File');

my $TEMP = TEMP_DIR();

exercise_join( impl => 'File', file1 => "$TEMP/q11a", file2 => "$TEMP/q11b" );

done_testing;
