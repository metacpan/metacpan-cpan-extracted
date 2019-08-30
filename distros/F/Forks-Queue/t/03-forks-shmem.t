use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('Shmem');

my $TEMP = do {
    no warnings 'once';
    $Forks::Queue::Shmem::DEV_SHM;
};

unlink "$TEMP/q3m", "$TEMP/q3n";
ok(-d $TEMP, 'queue directory exists');
ok(! -f "$TEMP/q3m", 'queue file does not exist yet');
ok(! -f "$TEMP/q3n", 'queue file does not exist yet');

my $q1 = Forks::Queue->new( impl => 'Shmem', file => "q3m" );
my $q2 = Forks::Queue->new( impl => 'Shmem', file => "q3n", persist => 1 );

ok($q1 && ref($q1) eq 'Forks::Queue::Shmem', 'got queue with correct type');

exercise_forks($q1);

undef $q1;
ok(! -f "$TEMP/q3m", 'queue file destroyed when object left scope');

ok($q2 && ref($q2) eq 'Forks::Queue::Shmem', 'got queue with correct type');
exercise_forks($q2);
undef $q2;
ok(-f "$TEMP/q3n", 'queue with persist option not destroyed');
unlink("$TEMP/q3n");
ok(! -f "$TEMP/q3n", 'queue file removed manually');

done_testing;
