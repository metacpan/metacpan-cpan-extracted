#!/usr/local/bin/perl -w
use strict;
use HTTP::DAV;
use Test;
use lib 't';
use TestDetails qw($test_user $test_pass $test_url do_test fail_tests test_callback);

# Sends out a propfind request to the server 
# specified in "PROPFIND" in the TestDetails 
# module.

my $TESTS;
$TESTS=9;
plan tests => $TESTS;
fail_tests($TESTS) unless $test_url =~ /http/;

my $dav = HTTP::DAV->new;
HTTP::DAV::DebugLevel(3);

$dav->credentials( $test_user,$test_pass,$test_url );

my $response;
my $resource = $dav->new_resource( -uri => $test_url );

######################################################################
# RUN THE TESTS

ok($resource->set_property('testing','123'));
ok($resource->get_property('testing'),'123');
ok($resource->is_collection(),0);

$response = $resource->propfind();
if (! ok($response->is_success) ) {
   print $response->message() ."\n";
}

ok($resource->is_collection());
ok($resource->get_property('resourcetype'));

$response = $resource->propfind( -depth=>0, "<D:prop><D:lockdiscovery/></D:prop>");
if (! ok($response->is_success) ) {
   print $response->message() ."\n";
}

#use Data::Dumper;
#print Data::Dumper->Dump( [$resource] , [ '$resource' ] );
#print $resource->as_string;


$response = $resource->options();
if (! ok($response->is_success) ) {
   print $response->message() ."\n";
}

#$resource->set_property('supportedlocks',[]);
if ( $resource->is_dav_compliant() eq 2 && $resource->is_option('LOCK') ) {
   my $supportedlocks_arr = $resource->get_property('supportedlocks');
   print "supportedlocks_arr: ". ref($supportedlocks_arr) ."\n";
   ok(1) if ref($supportedlocks_arr) eq "ARRAY";
} else {
   skip 1,1;
}
