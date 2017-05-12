#!/usr/local/bin/perl -w
use strict;
use HTTP::DAV;
use Test;
use lib 't';
use TestDetails qw($test_user $test_pass $test_url do_test fail_tests test_callback);

# Tests dav options functionality.

my $TESTS;
$TESTS=6;
plan tests => $TESTS;
fail_tests($TESTS) unless $test_url =~ /http/;

my $user = $test_user;
my $pass = $test_pass;
my $url = $test_url;
$url=~ s/\/$//g; # Remove trailing slash

HTTP::DAV::DebugLevel(1);

=begin

DAV.pm::options() - Test plan
-------------------------
We want to perform test functions against proppatch. 
   OPEN
   MKCOL perldav
   OPTIONS                    (looking for PROPFIND)
   OPTIONS perldav            (looking for PROPFIND)
   OPTIONS http://...perldav  (looking for PROPFIND)

=cut 

# Setup
# Make a directory with our process id after it 
# so that it is somewhat random
my $perldav_test_uri = "perldav_test" .$$;
my $perldav_test_url = "$url/$perldav_test_uri/";

my $dav = HTTP::DAV->new();
$dav->credentials( $user, $pass, $url );
do_test $dav, $dav->open ($url),          1,"OPEN $url";
do_test $dav, $dav->mkcol($perldav_test_uri),    1,"MKCOL $perldav_test_uri";

print "OPTIONS\n" . "----\n";
do_test $dav, $dav->options( "$url" ),              '/PROPFIND/', "OPTIONS $url (looking for PROPFIND)";
do_test $dav, $dav->options( "$perldav_test_uri" ), '/PROPFIND/', "OPTIONS $perldav_test_uri (looking for PROPFIND)";
do_test $dav, $dav->options( "$perldav_test_url" ), '/PROPFIND/', "OPTIONS $perldav_test_url (looking for PROPFIND)";

# Cleanup
do_test $dav, $dav->delete("$perldav_test_url"),1,"DELETE $perldav_test_url";
