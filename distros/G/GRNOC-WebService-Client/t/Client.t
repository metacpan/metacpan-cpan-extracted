use Test::More tests => 3;

use strict;
use GRNOC::WebService::Client;
use JSON::XS;
use Data::Dumper;

my $svc = GRNOC::WebService::Client->new(
					 url => "http://localhost:8529/test.cgi"
					 );

ok(defined $svc ,"Creating new Client");

my $methods = $svc->help();

is(@$methods, 5, "all methods registered");

my $results = $svc->test();

is($results->{'results'}->{'success'}, 1, "Successfully parsed JSON");

	
