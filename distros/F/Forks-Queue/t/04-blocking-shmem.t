use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('Shmem');

my $TEMP = TEMP_DIR();

ok(! -f "$TEMP/q3o", 'queue file does not exist yet');

my $q3 = Forks::Queue->new( impl => 'Shmem', file => "q3o",
                            style => 'lifo' );

ok($q3 && ref($q3) eq 'Forks::Queue::Shmem', 'got queue with correct type');
exercise_blocking($q3);
undef $q3;
ok(! -f "$TEMP/q3o", 'queue file destroyed when object left scope');

done_testing;
