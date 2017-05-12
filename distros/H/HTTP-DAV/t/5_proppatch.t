#!/usr/local/bin/perl -w
use strict;
use HTTP::DAV;
use Test;
use Cwd;
use lib 't';
use TestDetails qw($test_user $test_pass $test_url $test_cwd do_test fail_tests test_callback);

# Tests basic proppatch.

my $TESTS;
$TESTS=14;
plan tests => $TESTS;
fail_tests($TESTS) unless $test_url =~ /http/;


my $user = $test_user;
my $pass = $test_pass;
my $url = $test_url;
my $cwd = $test_cwd; # Remember where we started

HTTP::DAV::DebugLevel(3);

# Make a directory with our process id after it 
# so that it is somewhat random
my $newdir = "perldav_test$$";

=begin

Proppatch - Test plan
-------------------------
We want to perform test functions against proppatch. 

Setup.
   OPEN
   MKCOL perldav_test
   CWD perldav_test
   PUT perldav_test/file.txt

   #is option(perldav_test,PROPFIND)
   #is option(perldav_test/file.txt, PROPFIND)

Test 1. We want to test a set prop sequence.
   if is_option(perldav_test,PROPFIND) {
      PROPPATCH(perldav_test, set patrick:test_prop=test_val)
   }
   if is_option(perldav_test/file.txt,PROPFIND) {
      PROPPATCH(perldav_test/file.txt, set patrick:test_prop=test_val)
   }

Test 2. Then a remove prop sequence
   PROPPATCH perldav_test (remove patrick:test_prop)

Test 3. Then lock perldav_test and do a proppatch. No namespace
   3a. LOCK perldav_test
   3a. PROPPATCH perldav_test (set test_prop=test_val)
   3b. PROPPATCH perldav_test (remove DAV:test_prop)
   3b. UNLOCK perldav_test

=cut 

# Setup
my $dav1 = HTTP::DAV->new();
$dav1->credentials( $user, $pass, $url );
do_test $dav1, $dav1->open  ( $url ),  1,"OPEN $url";

# Determine server's willingness to proppatching and locking
# IIS5 currently does not support pp on files or colls.
my $options =$dav1->options();
my $coll_proppatch=( $options=~/\bPROPPATCH\b/)?1:0;
my $coll_lock=     ( $options=~/\bLOCK\b/     )?1:0;
my $cps = ($coll_proppatch)?"supports":"does not support";
my $cls = ($coll_lock     )?"supports":"does not support";
print "$options\n";
print "** Server $cps proppatch against collections ** \n";
print "** Server $cls locking against collections ** \n";

if (!$coll_proppatch) {
   skip_num($TESTS-1); # We've already done one test on the open
   exit;
}


######################################################################
my $resource;

do_test $dav1, $dav1->mkcol ($newdir), 1,"MKCOL $newdir";
do_test $dav1, $dav1->cwd   ($newdir), 1,"CWD $newdir";


## Test 1.
do_test $dav1, 
   $dav1->proppatch(-namespace=>'patrick',
                    -propname=>'test_prop',
                    -propvalue=>'test_val'),
   '/Resource/', 
   "proppatch set test_prop";

$resource = $dav1->propfind(-depth=>0);
if ($resource) {
   do_test $dav1, 
           $resource->get_property('test_prop'),
           'test_val',
           "propfind get_property test_prop";
} else {
   print "Couldn't perform propfind\n";
   ok 0;
}
print $resource->as_string;


## Test 2
do_test 
   $dav1, 
   $dav1->proppatch(-namespace=>'patrick',
                    -propname=>'test_prop',
                    -action=>'remove'),
   '/Resource/', 
   "proppatch remove test_prop";

$resource = $dav1->propfind(-depth=>0);
if ($resource) {
   do_test $dav1, 
           $resource->get_property('test_prop'),
           '',
           "propfind get_property test_prop";
} else {
   print "Couldn't perform propfind\n";
   ok 0;
}
print $resource->as_string;

######################################################################
if ($coll_lock) {
   do_test $dav1, $dav1->lock(),          1,"LOCK";
   
   # Test 3a
   do_test 
      $dav1, 
      $dav1->set_prop(-propname=>'test_prop',-propvalue=>'test_value2'),
      '/Resource/', 
      "proppatch set DAV:test_prop";
   
   $resource = $dav1->propfind(-depth=>0);
   if ($resource) {
      do_test $dav1, 
              $resource->get_property('test_prop'),
              'test_value2',
              "propset get_property DAV:test_prop";
   } else {
      print "Couldn't perform propfind\n";
      ok 0;
   }
   print $resource->as_string;

   # Test 3b
   do_test 
      $dav1, 
      $dav1->unset_prop(-propname=>'test_prop',-namespace=>'DAV'),
      '/Resource/', 
      "unset_prop DAV:test_prop";
   
   $resource = $dav1->propfind(-depth=>0);
   if ($resource) {
      do_test $dav1, 
              $resource->get_property('test_prop'),
              '',
              "propfind get_property DAV:test_prop";
   } else {
      print "Couldn't perform propfind\n";
      ok 0;
   }
   print $resource->as_string;

   do_test $dav1, $dav1->unlock(),          1,"UNLOCK";
}

# Cleanup
if ( $test_url =~ /http/ ) {
   print "Cleaning up\n";
   $dav1->cwd("..");
   do_test $dav1, $dav1->delete($newdir),      1,"DELETE $newdir";
}
