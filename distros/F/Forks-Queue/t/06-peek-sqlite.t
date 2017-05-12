use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('SQLite');

my $TEMP = TEMP_DIR();
unlink "$TEMP/q3d";

ok(! -f "$TEMP/q3d", 'queue file does not exist yet');
my $q4 = Forks::Queue->new( impl => 'SQLite', db_file => "$TEMP/q3d",
                            style => 'fifo' );
$q4->clear;
exercise_peek($q4);
undef $q4;

done_testing;
