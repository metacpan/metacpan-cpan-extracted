use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('SQLite');

my $TEMP = TEMP_DIR();

unlink "$TEMP/q3a", "$TEMP/q3b";
ok(-d $TEMP, 'queue directory exists');
ok(! -f "$TEMP/q3a", 'queue file does not exist yet');
ok(! -f "$TEMP/q3b", 'queue file does not exist yet');

my $q1 = Forks::Queue->new( impl => 'SQLite', db_file => "$TEMP/q3a" );
my $q2 = Forks::Queue->new( impl => 'SQLite', db_file => "$TEMP/q3b",
                            persist => 1 );

ok($q1 && ref($q1) eq 'Forks::Queue::SQLite',
   'got queue with correct type');

exercise_forks($q1);

undef $q1;
ok(! -f "$TEMP/q3a", 'queue file destroyed when object left scope');

ok($q2 && ref($q2) eq 'Forks::Queue::SQLite', 'got queue with correct type');
exercise_forks($q2);
undef $q2;
ok(-f "$TEMP/q3b", 'queue with persist option not destroyed');
unlink("$TEMP/q3b");
ok(! -f "$TEMP/q3b", 'queue file removed manually');

done_testing;
