#!/usr/local/bin/perl -w
use strict;
use HTTP::DAV;
use Test;
use lib 't';
use TestDetails qw($test_user $test_pass $test_url $test_cwd do_test fail_tests test_callback);

# Tests advanced locking, like shared locks and steal locks

my $TESTS;
$TESTS=11;
plan tests => $TESTS;
fail_tests($TESTS) unless $test_url =~ /http/;

my $user = $test_user;
my $pass = $test_pass;
my $url = $test_url;
my $cwd = $test_cwd; # Remember where we started.

HTTP::DAV::DebugLevel(1);

# Make a directory with our process id after it 
# so that it is somewhat random
my $newdir = "perldav_test$$";

=begin

Advanced Locking - Test plan
-------------------------
We want to perform test functions against our locking mechanisms. This stretches the legs of:
 - the headers (depth, type, scope, owner)
 - shared locking
 - steal locks

Setup.
   Client 1: OPEN 
   Client 2: OPEN 
   Client 1: MKCOL perldav_test
   Client 1: MKCOL perldav_test/subdir

Test 1. Test timeout header
   Client 1: LOCK perldav_test with timeout=10m
   Client 1: UNLOCK perldav_test with timeout=10m

Test 1. Test 2 shared locks
   Client 1: LOCK perldav_test with scope=shared
   Client 2: LOCK perldav_test with scope=shared
=cut 

# Setup
my $dav1 = HTTP::DAV->new();
my $dav2 = HTTP::DAV->new();
$dav1->credentials( $user, $pass, $url );
$dav2->credentials( $user, $pass, $url );
do_test $dav1, $dav1->open( $url ), 1, "dav1->OPEN $url";
do_test $dav2, $dav2->open( $url ), 1, "dav2->OPEN $url";
do_test $dav1, $dav1->mkcol ($newdir),          1,"dav1->MKCOL $newdir";
do_test $dav1, $dav1->mkcol ("$newdir/subdir"), 1,"dav1->MKCOL $newdir/subdir";

# Test 1
do_test $dav1, $dav1->lock(-url=>$newdir,-timeout=>"10m"), 1,"dav1->LOCK $newdir timeout=10mins";
my $u = $url; $u =~ s/\/$//g;
my $r1 = $dav1->new_resource("$u/$newdir");
my $r2 = $dav2->new_resource("$u/$newdir");
print $r1->as_string;
my @locks = $r1->get_locks(-owned=>1);
my $lock = shift @locks;
my $timeout = ($lock->get_timeout()||0) if ($lock);
if ($timeout) {
   my $secstogo = ($timeout-time);
   print "Timesout in: $secstogo seconds\n";
   if ( $secstogo <= 10*60 ) {
      print "Whoopee!! The server honored out timeout of 10 minutes. (but I'm not hanging around to watch it timeout :)\n";
   } else {
      print "Hmmm... server did strange thing with my 10min lock. Maybe made it infinite?\n";
   }
} else {
   print "Server ignored my lock timeout. Oh well... c'est la vie.\n";
}

do_test $dav1, $dav1->unlock($newdir),          1,"dav1->UNLOCK $newdir";

# Test 2
do_test $dav1, 
        $dav1->lock(-url=>$newdir, 
                    -scope=>'shared', 
                    -owner=>'dav1' 
                    ), 
        1,"dav1->LOCK $newdir (scope=shared)";

do_test $dav2, 
        $dav2->lock(-url=>$newdir,
                    -scope=>'shared',
                    -depth=>0,
                    -owner=>'http://dav2'
                    ),
        1,"dav2->LOCK $newdir (scope=shared)";

$r1->propfind();
$r2->propfind();
print "DAV1:" . $r1->as_string;
print "DAV2:" . $r2->as_string;

do_test $dav1, $dav1->steal(-url=>$newdir), 1,"dav1->STEAL $newdir";

$r1->propfind();
print "DAV1:" . $r1->as_string;

do_test $dav2, $dav2->unlock(-url=>$newdir), 0,"dav2->UNLOCK $newdir";
my $resp=$r2->propfind();
print "DAV2:" . $r2->as_string;

#$r1->build_ls();
#$r1->get_property(short_ls);

do_test $dav1, $dav1->delete(-url=>$newdir), 1,"dav1->DELETE $newdir";
