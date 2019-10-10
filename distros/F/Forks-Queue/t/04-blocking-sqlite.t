use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('SQLite');

my $TEMP = TEMP_DIR();
my $qfile = "q4u-$$";

ok(! -f "$TEMP/$qfile", 'queue file does not exist yet');

my $q4 = Forks::Queue->new( impl => 'SQLite', db_file => "$TEMP/$qfile",
                            style => 'lifo' );

ok($q4 && ref($q4) eq 'Forks::Queue::SQLite', 'got queue with correct type');
exercise_blocking($q4);
undef $q4;
ok(! -f "$TEMP/$qfile", 'queue file destroyed when object left scope');

done_testing;
