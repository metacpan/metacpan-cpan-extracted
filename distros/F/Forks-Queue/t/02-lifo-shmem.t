use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('Shmem');

unlink "$Forks::Queue::Shmem::DEV_SHM/q2m";
ok(! -f "$Forks::Queue::Shmem::DEV_SHM/q2m",
   'queue file does not exist yet');

my $q = Forks::Queue::Shmem->new( file => "q2m", style => 'lifo' );

ok($q && ref($q) eq 'Forks::Queue::Shmem', 'got queue with correct type');
ok(-f "$Forks::Queue::Shmem::DEV_SHM/q2m", 'queue file created');
ok(-s "$Forks::Queue::Shmem::DEV_SHM/q2m" > 1024,
   'queue header section created');

exercise_lifo($q);

undef $q;
ok(! -f "$Forks::Queue::Shmem::DEV_SHM/q2m",
   'queue file destroyed when queue object left scope');

$q = Forks::Queue::Shmem->new( file => 'q2m', style => 'lifo' );
ok(-f "$Forks::Queue::Shmem::DEV_SHM/q2m", 'queue file created');
exercise_lifo2($q);
undef $q;
ok(! -f "$Forks::Queue::Shmem::DEV_SHM/q2m",
   'queue file destroyed when queue object left scope');

done_testing();
