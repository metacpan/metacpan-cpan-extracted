use strict;
use warnings;
use Test::More;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

PREP('Shmem');
my $qfile = do { no warnings 'once'; "$Forks::Queue::Shmem::DEV_SHM/q1m-$$" };

unlink $qfile;
ok(! -f $qfile, 'queue file does not exist yet');

########

my $q = Forks::Queue::Shmem->new( file => $qfile, style => 'fifo' );

ok($q, 'got queue object');
ok(ref($q) eq 'Forks::Queue::Shmem', 'has correct object type');
ok(-f $qfile, 'queue file created');
ok(-s $qfile > 1024, 'queue header section created');

exercise_fifo($q);

undef $q;
ok(! -f $qfile, 'queue file destroyed when queue object was out of scope');

done_testing;
