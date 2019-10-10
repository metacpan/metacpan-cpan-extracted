use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('File');
my $qfile_a = "q8a-$$";
my $qfile_b = "q8b-$$";

my $TEMP = TEMP_DIR();

# avoiding 't' here just in case it is an NFS filesystem
diag "Using '$TEMP' for queue file";

unlink "$TEMP/$qfile_a", "$TEMP/$qfile_b";
ok(-d $TEMP, 'queue directory exists');
ok(! -f "$TEMP/$qfile_a", 'queue file does not exist yet');
ok(! -f "$TEMP/$qfile_b", 'queue file does not exist yet');

my $q1 = Forks::Queue->new( impl => 'File', file => "$TEMP/$qfile_a",
                            dflock => 1 );
my $q2 = Forks::Queue->new( impl => 'File', file => "$TEMP/$qfile_b",
                            dflock => 1, persist => 1 );

ok($q1 && ref($q1) eq 'Forks::Queue::File', 'got queue with correct type');

exercise_forks($q1);

undef $q1;
ok(! -f "$TEMP/$qfile_a", 'queue file destroyed when object left scope');

ok($q2 && ref($q2) eq 'Forks::Queue::File', 'got queue with correct type');
exercise_forks($q2);
undef $q2;
ok(-f "$TEMP/$qfile_b", 'queue with persist option not destroyed');
unlink("$TEMP/$qfile_b");
ok(! -f "$TEMP/$qfile_b", 'queue file removed manually');

done_testing;
