#!/usr/bin/perl 

use Test::Simple tests=>4;

use strict;
use GRNOC::WebService::Client;
use JSON::XS;
use Data::Dumper;

my $svc = GRNOC::WebService::Client->new(
					 url => "http://localhost:8529/not_json.html"
					 );

ok(defined $svc ,"Creating new Client");

my $results = $svc->help();

ok(! defined $results, "Did'nt get back an answer.");

my $error = $svc->get_error();

ok($error =~ m/malformed JSON string/, "Got back the error.");

ok(defined $svc ,"Client did not crash.");

	
