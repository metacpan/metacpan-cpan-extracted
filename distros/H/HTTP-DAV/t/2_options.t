#!/usr/local/bin/perl -w
use strict;
use HTTP::DAV;
use Test;
use lib 't';
use TestDetails qw($test_user $test_pass $test_url do_test fail_tests test_callback);

my $TESTS;
$TESTS = 6;
plan tests => $TESTS; 
fail_tests($TESTS) unless $test_url =~ /http/;

my $dav = HTTP::DAV->new;
$dav->DebugLevel(3);

$dav->credentials( $test_user, $test_pass, $test_url );

my $resource = $dav->new_resource( -uri => $test_url );
my $response = $resource->options();
if ( ! ok($response->is_success) ) {
   print $response->message() ."\n";
}

print "DAV compliancy: ". $resource->is_dav_compliant(). "\n";
ok($resource->is_dav_compliant());

my $options = $resource->get_options || "";
print "$options\n";
ok($options,'/PROPFIND/');
ok($resource->is_option('PROPFIND'),1);
ok($resource->is_option('JUNKOPTION'),0);
   
ok($resource->get_username(),$test_user);
