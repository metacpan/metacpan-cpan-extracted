use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('Shmem');
my $qfile = "q4o-$$";
my $TEMP = do {
    no warnings 'once';
    $Forks::Queue::Shmem::DEV_SHM;
};

ok(! -f "$TEMP/$qfile", 'queue file does not exist yet');

my $q4 = Forks::Queue->new( impl => 'Shmem', file => $qfile,
                            style => 'lifo' );

ok($q4 && ref($q4) eq 'Forks::Queue::Shmem', 'got queue with correct type');
ok(-f "$TEMP/$qfile",
   "Shmem queue file $qfile created before blocking exercise");
exercise_blocking($q4);
undef $q4;
ok(! -f "$TEMP/$qfile", 'queue file destroyed when object left scope');

done_testing;
