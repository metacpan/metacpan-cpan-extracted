#! perl

use strict;
use warnings;
use Test::More;
use Config;

BEGIN {
   if ($Config{useithreads}) {
      require threads;
   } else {
      plan skip_all => 'Need Perl with thread support for these tests';
   }
};


use Time::HiRes ();

use File::SharedNFSLock;

my $some_file = 'some_file_on_nfs';
my $lock_file = 'some_file_on_nfs.lock';


# Trying to use many threads doing many simultaneous lock() operations to see
# if a race condition can be triggered.

my @threads;
push @threads, threads->create(\&worker) for 1..30;

my @finished;
while ( threads->list() ) { # number of non-joined, non-detached threads
   for my $joinable ( threads->list(threads::joinable) ) {
      push @finished, $joinable->tid;
      $joinable->join;
   }
}

is scalar @finished, 30;


sub worker {
   my ($delay, $msg) = @_;
   my $flock = File::SharedNFSLock->new(
      file => $some_file,
   );
   for (1..30) {
     $flock->lock;
     $flock->unlock;
   }
   return 1;
}


done_testing();
