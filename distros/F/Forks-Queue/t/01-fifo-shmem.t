use strict;
use warnings;
use Test::More;
require "t/exercises.tt";

PREP('Shmem');

unlink "$Forks::Queue::Shmem::DEV_SHM/q1m";
ok(! -f "$Forks::Queue::Shmem::DEV_SHM/q1m",
   'queue file does not exist yet');

########

my $q = Forks::Queue::Shmem->new( file => 'q1m', style => 'fifo' );

ok($q, 'got queue object');
ok(ref($q) eq 'Forks::Queue::Shmem', 'has correct object type');
ok(-f "$Forks::Queue::Shmem::DEV_SHM/q1m", 'queue file created');
ok(-s "$Forks::Queue::Shmem::DEV_SHM/q1m" > 1024,
   'queue header section created');

exercise_fifo($q);

undef $q;
ok(! -f "$Forks::Queue::Shmem::DEV_SHM/q1m",
   'queue file destroyed when queue object was out of scope');

done_testing;
