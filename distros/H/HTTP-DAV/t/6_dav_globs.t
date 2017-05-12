#!/usr/local/bin/perl -w

################################################################
# t/t_dav_globs.t
# Tests globbing functionality: wildcards, like *, ? etc in URL's
#
# GLOB - Test plan
# -------------------------
# We want to perform test functions against ... 
# 
# Test 1. 
#   OPEN perldav_test_copy/subdir/ (should fail because no depth).


use strict;
use HTTP::DAV;
use lib 't';
use TestDetails qw($test_user $test_pass $test_url do_test fail_tests test_callback);
use Test;

my $TESTS=11;
plan tests => $TESTS;
fail_tests($TESTS) unless $test_url =~ /http/;

HTTP::DAV::DebugLevel(3);

my $targeturi = "perldav_test" .$$ . "_".time;
my $shorturi = "perldav_test" .$$;
my $targeturl = URI->new_abs($targeturi,$test_url);
my $localdir = "/tmp/$targeturi";

print "targeturi: $targeturi\n";
print "targeturl: $targeturl\n";

my $dav1 = HTTP::DAV->new();
$dav1->credentials( $test_user, $test_pass, $test_url );

# SETUP
# make URL/perldav_12341234/test_data/*
do_test $dav1, $dav1->open ($test_url),     1,"OPEN $test_url";
do_test $dav1, $dav1->mkcol($targeturl),    1,"MKCOL $targeturl";
do_test $dav1, mkdir($localdir), 1, "system mkdir $localdir";

# TEST 1
# Test that working directory =~ /$shorturi/
do_test $dav1, $dav1->cwd("$shorturi*"),    1,"CWD $shorturi*";
do_test $dav1, $dav1->get_workingurl, "/$shorturi/", "CHECK WORKING DIRECTORY =~ /$shorturi/";

# TEST 2
do_test $dav1, $dav1->put(-local=>"t/test_data/file*", -callback=>\&test_callback), 1, "PUT t/test_data/file*";

# TEST 3
# Test for get xxxxxx* (should fail)
do_test $dav1, $dav1->get(-url=>"xxxxx*",    -to=>$localdir), 0, 'GET xxxxx*';

# TEST 4
# Test for get file[1_]* (should succeed)
do_test $dav1, $dav1->get(-url=>"file[1_]*", -to=>$localdir,-callback=>\&test_callback), 1, 'GET file[1_]*';

# TEST 5
# Test for delete *.txt (should succeed)
do_test $dav1, $dav1->delete(-url=>"*.txt",-callback=>\&test_callback), 1, 'DELETE *.txt';

# TEST 6
# Test for delete *.txt (should fail)
do_test $dav1, $dav1->delete(-url=>"*.txt",-callback=>\&test_callback), 0, 'DELETE *.txt';

# CLEANUP
do_test $dav1, $dav1->delete("$targeturl"), 1,"DELETE $targeturl";
system("/bin/rm -rf $localdir");
