# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Example-XS-FasterHashes.t'

#########################

use strict;
use warnings;

use Time::HiRes qw( time );
use Test::More tests => 1;
BEGIN { use_ok('Example::XS::FasterHashes') };


##use a C debugger and you see the hash numbers stay the same but the shared
##char *s become different in the 2 different ithreads
#$o->getKC(2);
#threads->create(sub {
#    print "in thread\n";
#    $o->getKC(2);
#    print "end thread\n";
#    })->join();

my $o = new Example::XS::FasterHashes;
diag("starting benchmark will take 30 seconds\n");
my ($t1beg, $t1end, $t2beg, $t2end);
$t1beg = time;
for(0..1000000){
     for (int(rand 6)+1) {$o->get($_);}
}
$t1end = time;
$t2beg = time;
for(0..1000000){
     for (int(rand 6)+1) {$o->getKC($_);}
}
$t2end = time;
diag("time for old way was ".($t1end-$t1beg)."\n");
diag("time for new way was ".($t2end-$t2beg)."\n");
