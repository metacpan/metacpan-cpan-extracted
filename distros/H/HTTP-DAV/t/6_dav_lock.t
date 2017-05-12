#!/usr/local/bin/perl -w
use strict;
use HTTP::DAV;
use Test;
use lib 't';
use TestDetails qw($test_user $test_pass $test_url $test_cwd do_test fail_tests test_callback);

# Tests basic LOCKing.

my $TESTS;
$TESTS=13;
plan tests => $TESTS;
fail_tests($TESTS) unless $test_url =~ /http/;

my $user = $test_user;
my $pass = $test_pass;
my $url = $test_url;
my $cwd = $test_cwd;

HTTP::DAV::DebugLevel(1);

# Make a directory with our process id after it 
# so that it is somewhat random
my $newdir = "perldav_test$$";

=begin

Locking - Test plan
-------------------------
We want to perform test functions against our locking mechanisms. This stretches the legs of:
 - delete/put/mkcol's use of the if headers
 - the locked resources state management
and then secondly
 - the depth headers etc...

Setup.
   Client 1: OPEN 
   Client 2: OPEN 
   Client 1: MKCOL perldav_test
   Client 1: MKCOL perldav_test/subdir

Test 1. We want to test a lock/unlock sequence.
   Client 1: LOCK perldav_test
   Client 1: UNLOCK perldav_test

Test 2. Then a lock/put sequence
   Client 1: LOCK perldav_test
   Client 1: PUT  perldav_test/subdir/file.txt

Test 3. Then a lock/mkcol sequence (and again with another client)
    Client 2: MKCOL perldav_test/subdir2 (should fail as we don't own the lock)
    Client 1: MKCOL perldav_test/subdir3 (fails badly on the subsequent 
                                         delete. not sure why)
Test 4. Then a lock/lock sequence (should fail)
   Client 1: LOCK perldav_test/subdir (should fail, can't nest locks)

Test 5. Then a lock/delete sequence (should work)
   Client 1: DELETE perldav_test

Test 6. Then a delete/unlock sequence (should fail resource was delete)
   Client 1: UNLOCK perldav_test (should fail in client as no locks held after the delete).


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
do_test $dav1, $dav1->lock  ($newdir),          1,"dav1->LOCK $newdir";
do_test $dav1, $dav1->unlock($newdir),          1,"dav1->UNLOCK $newdir";

# Test 2
do_test $dav1, $dav1->lock  ($newdir),          1,"dav1->LOCK $newdir";
do_test $dav1, $dav1->put(\"Testdata","$newdir/subdir/file.txt"),1,"dav1->PUT $newdir/subdir/file.txt";

# Test 3
# For some reason mydocsonline allows this test to succeed!?
# I don't need a lock token to create the following directory. Weird.
do_test $dav2, $dav2->mkcol ("$newdir/subdir2"),0,"dav2->MKCOL $newdir/subdir2";

# Contentious activity with mod_dav
# For some reason, I just can't get this 
# to work with my mod_dav. Works with Greg's though??? 
# Very very annoyed spent hours tracking it. I'll give 
# you a porsche if you can find out why it bugs out.
do_test $dav1, $dav1->mkcol ("$newdir/subdir3"),1,"dav1->MKCOL $newdir/subdir3";

# Test 4
do_test $dav1, $dav1->lock  ("$newdir/subdir"), 0,"dav1->LOCK $newdir/subdir";

# Test 5
do_test $dav1, $dav1->delete($newdir),          1,"dav1->DELETE $newdir";

# Test 6
do_test $dav1, $dav1->unlock($newdir),          0,"dav1->UNLOCK $newdir";

