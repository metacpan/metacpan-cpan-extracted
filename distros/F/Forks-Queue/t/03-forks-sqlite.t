use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('SQLite');

my $TEMP = TEMP_DIR();
my $qfile_s = "q3s-$$";
my $qfile_t = "q3t-$$";

unlink "$TEMP/$qfile_s", "$TEMP/$qfile_t";
ok(-d $TEMP, 'queue directory exists');
ok(! -f "$TEMP/$qfile_s", 'queue file does not exist yet');
ok(! -f "$TEMP/$qfile_t", 'queue file does not exist yet');

my $q1 = Forks::Queue->new( impl => 'SQLite', db_file => "$TEMP/$qfile_s" );
my $q2 = Forks::Queue->new( impl => 'SQLite', db_file => "$TEMP/$qfile_t",
                            persist => 1 );

ok($q1 && ref($q1) eq 'Forks::Queue::SQLite',
   'got queue with correct type');

exercise_forks($q1);

undef $q1;
ok(! -f "$TEMP/$qfile_s", 'queue file destroyed when object left scope');

ok($q2 && ref($q2) eq 'Forks::Queue::SQLite', 'got queue with correct type');
exercise_forks($q2);
undef $q2;
ok(-f "$TEMP/$qfile_t", 'queue with persist option not destroyed');
unlink("$TEMP/$qfile_t");
ok(! -f "$TEMP/$qfile_t", 'queue file removed manually');

done_testing;
