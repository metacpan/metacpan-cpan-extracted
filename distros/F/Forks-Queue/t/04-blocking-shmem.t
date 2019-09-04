use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('Shmem');
my $qfile = "q3o-$$";
my $TEMP = do {
    no warnings 'once';
    $Forks::Queue::Shmem::DEV_SHM;
};

ok(! -f "$TEMP/$qfile", 'queue file does not exist yet');

my $q3 = Forks::Queue->new( impl => 'Shmem', file => $qfile,
                            style => 'lifo' );

ok($q3 && ref($q3) eq 'Forks::Queue::Shmem', 'got queue with correct type');
exercise_blocking($q3);
undef $q3;
ok(! -f "$TEMP/$qfile", 'queue file destroyed when object left scope');

done_testing;
