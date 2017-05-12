#!/usr/local/bin/perl -w
use strict;
use HTTP::DAV;
use Test;
use lib 't';

# Tests Response.pm's ability to handle multistatus documents.
# Prerequisite: Resource.pm's _XML_parse_multistatus works.

my $TESTS;
$TESTS=20;
plan tests => $TESTS;

my $dav = HTTP::DAV->new;
HTTP::DAV::DebugLevel(3);

my $resource = $dav->new_resource( -uri => 'http://testserver:8080/test/' );

# MAKE OURSELVES A DUMMY REQUEST
my $request = HTTP::Request->new(PROPFIND => 'http://testserver:8080/test/' );
print "REQUEST>>: " . $request->as_string();

# MAKE OURSELVES A DUMMY RESPONSE
# From perldoc HTTP::Response
# $r = HTTP::Response->new($rc, [$msg, [$header, [$content]]])
#      Constructs a new `HTTP::Response' object describing a
#      response with response code `$rc' and optional message
#      `$msg'.  The message is a short human readable single
#      line string that explains the response code.

my $headers = HTTP::Headers->new();
$headers->header('Date' => 'Thu, 03 Feb 2001 00:00:00 GMT');
$headers->header('Content-Type' => 'text/xml; charset="utf-8"');

# LOAD t/multistatus.xml AS OUR CONTENT
open(F,"t/multistatus.xml") || die("Couldn't find multistatus.xml");;
my $content;
while(<F>) { $content.=$_ };

my $response = HTTP::DAV::Response->new("207","Multi-Status",$headers,$content);

# Put the dummy request into teh dummy response. Not 
# really required but HTTP::Response dies when you 
# do an as_string if you don't do this first.
$response->request($request);

# Requires the response code to be reset 
# for older versions of LWP 
$response->set_message( $response->code );

# A 207 will return OK. But down 
# further it should fail because their will be 
# sub-status's that fail.
if (! ok($response->is_success) ) {
   print $response->message() ."\n";
}

# use XML::DOM to parse the result.
my $resource_list;
eval {
my $parser = new XML::DOM::Parser;
my $doc = $parser->parse($response->content);

# We're only interested in the error codes that come out of $resp.
$resource_list = $resource->_XML_parse_multistatus( $doc, $response ) 
};
if ($@) {
   print "XML error: " . $@;
} else {
   ok(1);
}

print "RESPONSE>>: " . $response->as_string();

# Check that the response is a multistatus
ok($response->is_multistatus());

# Check that the message returned is indeed 'Multistatus'
ok($response->message(), 'Multistatus');

# Check that the response successfully says that it failed
ok($response->is_success(),0);

# Check an array of messages
my @messages = $response->messages();
ok(scalar(@messages), 5);
ok($messages[4], '/Forbidden/');

# Check that the URI in at least one of the resourcs is absolute.
# Search for Parse 1 area in Resource.pm
ok($response->url_bynum(0),'/http\:\/\//');

# Check that there are five errors in the multistatus.
ok($response->response_count(),5-1);

# Check that the desc for status 1 and status 3 are ok 
ok($response->description_bynum(0), undef);
ok($response->description_bynum(2), "/Looks good to me/");

# Check that the code for status 5 is forbidden
ok($response->code_bynum(4), '403');

# Check the overall response description
ok($response->get_responsedescription(), 'There has been an access violation error.');

######################################################################
# Check some of the resources etc.
ok( $resource_list->count_resources(), 5);
my @progeny = $resource_list->get_resources();

my @urls = $resource_list->get_urls();
print join("\n",@urls) . "\n";

# Test getting slighlt different URI's.
$urls[1] =~ s/\/+$//g; # Remove the trailing slash from the collection
# Now see if we get the same resource.
my $resource1= $resource_list->get_member( $urls[1] );
print "Resource 1: " . $urls[1] . ": $resource1\n";
ok($progeny[1] eq $resource1 );

# Test removing the second last element (0,1,2,'3',4)
my $resource3 = $resource_list->get_member( $urls[3] );
my $resource3a= $resource_list->remove_resource( $resource3 );
print "Is Removed resource <-> sames as \$urls[3]?\n";
if ($resource3->get_uri eq $resource3a->get_uri ) {
   ok 1;
}
#if ($resource3 && $resource3->get_uri eq $urls[3] ) {
#   ok 1;
#}

# Test that we now only have 4 resoruces
my @urls2 = $resource_list->get_urls();
print join("\n",@urls2) . "\n";
ok ( scalar @urls2, 4 );


# Resource 1 has 2 locks types supported "exclusive:write" and "shared:write"
my $supportedlocks_arr = $progeny[0]->get_property('supportedlocks');
ok ( scalar(@$supportedlocks_arr), 2 );

# Resource 3 should have no locks supported.
$supportedlocks_arr = $progeny[2]->get_property('supportedlocks');
ok( ref($supportedlocks_arr) ne "ARRAY" );

print $progeny[4]->as_string();
ok($progeny[4]->get_property('author'),'/Johnson/');

