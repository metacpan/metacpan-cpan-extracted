use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('Shmem');
my $qfile_m = "q3m-$$";
my $qfile_n = "q3n-$$";

my $TEMP = do {
    no warnings 'once';
    $Forks::Queue::Shmem::DEV_SHM;
};

diag "Using '$TEMP' for queue file.";

unlink "$TEMP/$qfile_m", "$TEMP/$qfile_n";
ok(-d $TEMP, 'queue directory exists');
ok(! -f "$TEMP/$qfile_m", 'queue file does not exist yet');
ok(! -f "$TEMP/$qfile_n", 'queue file does not exist yet');

my $q1 = Forks::Queue->new( impl => 'Shmem', file => $qfile_m );
my $q2 = Forks::Queue->new( impl => 'Shmem', file => $qfile_n, persist => 1 );

ok($q1 && ref($q1) eq 'Forks::Queue::Shmem', 'got queue with correct type');

exercise_forks($q1);

undef $q1;
ok(! -f "$TEMP/$qfile_m", 'queue file destroyed when object left scope');

ok($q2 && ref($q2) eq 'Forks::Queue::Shmem', 'got queue with correct type');
exercise_forks($q2);
undef $q2;
ok(-f "$TEMP/$qfile_n", 'queue with persist option not destroyed');
unlink("$TEMP/$qfile_n");
ok(! -f "$TEMP/$qfile_n", 'queue file removed manually');

done_testing;
