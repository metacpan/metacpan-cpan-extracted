use strict;
use warnings;
use Test::More;
use lib '.';
require "t/exercises.tt";

PREP('Shmem');
my $qfile = "q2m-$$";

unlink "$Forks::Queue::Shmem::DEV_SHM/$qfile";
ok(! -f "$Forks::Queue::Shmem::DEV_SHM/$qfile",
   'queue file does not exist yet');

my $q = Forks::Queue::Shmem->new( file => $qfile, style => 'lifo' );

ok($q && ref($q) eq 'Forks::Queue::Shmem', 'got queue with correct type');
ok(-f "$Forks::Queue::Shmem::DEV_SHM/$qfile", 'queue file created');
ok(-s "$Forks::Queue::Shmem::DEV_SHM/$qfile" > 1024,
   'queue header section created');

exercise_lifo($q);

undef $q;
ok(! -f "$Forks::Queue::Shmem::DEV_SHM/$qfile",
   'queue file destroyed when queue object left scope');

$q = Forks::Queue::Shmem->new( file => $qfile, style => 'lifo' );
ok(-f "$Forks::Queue::Shmem::DEV_SHM/$qfile", 'queue file created');
exercise_lifo2($q);
undef $q;
ok(! -f "$Forks::Queue::Shmem::DEV_SHM/$qfile",
   'queue file destroyed when queue object left scope');

done_testing();
