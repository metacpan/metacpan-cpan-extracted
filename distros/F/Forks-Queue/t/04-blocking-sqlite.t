use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('SQLite');

my $TEMP = TEMP_DIR();

ok(! -f "$TEMP/q3c", 'queue file does not exist yet');

my $q3 = Forks::Queue->new( impl => 'SQLite', db_file => "$TEMP/q3c",
                            style => 'lifo' );

ok($q3 && ref($q3) eq 'Forks::Queue::SQLite', 'got queue with correct type');
exercise_blocking($q3);
undef $q3;
ok(! -f "$TEMP/q3c", 'queue file destroyed when object left scope');

done_testing;
