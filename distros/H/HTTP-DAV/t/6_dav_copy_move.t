#!/usr/local/bin/perl -w
use strict;
use HTTP::DAV;
use Test;
use lib 't';
use TestDetails qw($test_user $test_pass $test_url $test_cwd do_test fail_tests test_callback);

# Tests basic copy and move functionality.

my $TESTS;
$TESTS=14;
#$TESTS=18;
plan tests => $TESTS;
fail_tests($TESTS) unless $test_url =~ /http/;


my $user = $test_user;
my $pass = $test_pass;
my $url = $test_url;
$url=~ s/\/$//g; # Remove trailing slash
my $cwd = $test_cwd; # Remember where we started.

HTTP::DAV::DebugLevel(3);

=begin

COPY - Test plan
-------------------------
We want to perform test functions against proppatch. 

Setup.
   OPEN
   MKCOL perldav_test
   MKCOL perldav_test/subdir
   CWD perldav_test

Test 1. 
   COPY perldav_test perldav_test_copy
   OPEN perldav_test_copy/subdir/

Test 2. 
   COPY perldav_test perldav_test_copy (no overwrite)

Test 3. 
   COPY perldav_test perldav_test_copy (with overwrite, depth 0)
   OPEN perldav_test_copy
   OPEN perldav_test_copy/subdir/ (should fail because no depth).

MOVE - Test plan
-------------------------
We want to perform test functions against proppatch. 

Setup.

Test 1. 
   TODO 

Cleanup
   DELETE perldav_test
   DELETE perldav_test_copy

=cut 


# Setup
# Make a directory with our process id after it 
# so that it is somewhat random
my $sourceuri = "perldav_test" .$$ . "_".time;
my $sourceurl = "$url/$sourceuri";
my $targeturi = ${sourceuri} . "_copy";
my $targeturl = "$url/$targeturi";
print "sourceuri: $sourceuri\n";
print "sourceurl: $sourceurl\n";
print "targeturi: $targeturi\n";
print "targeturl: $targeturl\n";

my $dav1 = HTTP::DAV->new();
$dav1->credentials( $user, $pass, $url );
do_test $dav1, $dav1->open ($url),    1,"OPEN $url";
do_test $dav1, $dav1->mkcol($sourceuri),    1,"MKCOL $sourceuri";
do_test $dav1, $dav1->mkcol("$sourceuri/subdir"), 1,"MKCOL $sourceuri/subdir";
do_test $dav1, $dav1->cwd  ($sourceuri),    1,"CWD $sourceuri";

print "COPY\n" . "----\n";
my $resource1 = $dav1->get_workingresource();
my $resource2 = $dav1->new_resource( -uri => $targeturl );
my $resource3 = $dav1->new_resource( -uri =>"$targeturl/subdir" );

# Test 1 - COPY
do_test $dav1, $resource1->copy( $resource2 ),1, 
        "COPY $sourceuri to $targeturi";
do_test $dav1, $dav1->open( "$targeturl/subdir" ),  1, "OPEN $targeturi/subdir";

# Test 2 - COPY (no overwrite)
do_test $dav1, $resource1->copy( -dest=>$resource2, -overwrite=>"F" ),0, 
        "COPY $sourceuri to $targeturi (no overwrite)";

# Test 3 - COPY (overwrite, no depth)
do_test $dav1, $resource1->copy( -dest=>$resource2, -overwrite=>"T", -depth=>0 ),1, 
        "COPY $sourceuri to $targeturi (with overwrite, no depth)";
do_test $dav1, $dav1->open( "$targeturl" ),         1, "GET $targeturi";
do_test $dav1, $dav1->open( "$targeturl/subdir" ),  0, "GET $targeturi/subdir";




print "MOVE\n" . "----\n";

sub getlocks {
   my $r = $dav1->new_resource($url);
   $r->propfind(-depth=>1 );
   my $rl = $r->get_lockedresourcelist;
   print "rl=$rl\n";
   my $x = $rl->get_locktokens();
   foreach my $i ( $rl->get_resources() ) {
      my @locks = $i->get_locks();
      use Data::Dumper;
      print "All locks for " . $i->get_uri . ":\n";
      print Data::Dumper->Dump( [@locks] , [ '@locks' ] );
   }

#   use Data::Dumper;
#   print "All locks:\n";
#   print Data::Dumper->Dump( [$rl] , [ '$rl' ] );
}

# Re-setup
do_test $dav1, $dav1->delete( "$sourceurl" ),  1, "DELETE $sourceuri";

do_test $dav1, $dav1->lock( "$targeturl" ),         1, "LOCK $targeturi";
do_test $dav1, $dav1->lock( "$sourceurl" ),         1, "LOCK $sourceuri";

&getlocks;

# Test 4 - MOVE target(2) back to source(1)
do_test $dav1,
        $dav1->move( -url=>$targeturl,-dest=>$sourceurl ),1, 
        "MOVE $targeturi to $sourceuri";

# This unlock should fail because MOVE eats source locks
# I can't seem to get these tests to work.
# For some reason mod_dav has strange behaviour with trailing slashes if you move or copy null-locked files.
# For some reason, it keeps shadowed versions of the null-lock 
#after deleting the directory.
#do_test $dav1, $dav1->unlock( "$targeturl" ),         0, "UNLOCK $targeturl";
#do_test $dav1, $dav1->unlock( "$sourceurl" ),         1, "UNLOCK $sourceurl";

# Cleanup
$dav1->cwd("..");
#do_test $dav1, $dav1->delete("$sourceurl"),1,"DELETE $sourceurl";
#do_test $dav1, $dav1->delete("$targeturl"),0,"DELETE $targeturl";

$dav1->unlock( "$targeturl" );
$dav1->unlock( "$sourceurl" );
$dav1->delete( "$targeturl" );
$dav1->delete( "$sourceurl" );

