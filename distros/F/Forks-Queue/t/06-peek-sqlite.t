use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('SQLite');

my $TEMP = TEMP_DIR();
unlink "$TEMP/q6s";

ok(! -f "$TEMP/q6s", 'queue file does not exist yet');
my $q4 = Forks::Queue->new( impl => 'SQLite', db_file => "$TEMP/q6s",
                            style => 'fifo' );
$q4->clear;
exercise_peek($q4);
undef $q4;

done_testing;
