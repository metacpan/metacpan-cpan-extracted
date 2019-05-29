#!/usr/bin/perl

use Test::More tests => 10;

use strict;
use GRNOC::WebService::Client;
use JSON::XS;
use Data::Dumper;

# first verify that default behavior is to decode as JSON
my $svc = GRNOC::WebService::Client->new(
					 url           => 'http://localhost:8529/name_service.cgi',
					 );

my $results = $svc->help();

is( ref($results), "ARRAY", "checking for decoded JSON result");

is( @$results, 6, "checking for decoded amount");

is( $results->[0], "get_classes", "checking first decoded element");

# now verify that raw_output works and returns a string
$svc = GRNOC::WebService::Client->new(
				      url           => 'http://localhost:8529/name_service.cgi',
				      raw_output    => 1
				      );

$results = $svc->help();

isnt( ref($results), "ARRAY", "verifying not decoded");

is( $results, '["get_classes","get_clouds","get_locations_by_urn","get_versions","help","list_services"]', "checking for raw output");

$svc->set_raw_output(0);

$results = $svc->help();

is(ref($results), "ARRAY", "checking for decoded JSON result");

is(@$results, 6, "checking for decoded amount");

is($results->[0], "get_classes", "checking first decoded element");

$svc->set_raw_output(1);

$results = $svc->help();

isnt( ref($results), "ARRAY", "verifying not decoded");

is( $results, '["get_classes","get_clouds","get_locations_by_urn","get_versions","help","list_services"]', "checking for raw output");
