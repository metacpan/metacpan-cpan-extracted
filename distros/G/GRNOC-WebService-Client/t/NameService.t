#!/usr/bin/perl

use Test::More tests => 5;

use strict;
use GRNOC::WebService::Client;
use JSON::XS;
use Data::Dumper;


my $svc = GRNOC::WebService::Client->new(
					 service_name => 'urn:publicid:IDN+grnoc.iu.edu:GlobalNOC:CDS:1:Node',
					);

ok(defined($svc) ,"GRNOC::WebService::Client was created");

like($svc->get_error(), qr/Unable to find a usable URL: Neither name_services or service_cache_file were specified/,"invalid use");

$svc = GRNOC::WebService::Client->new(
				      service_name => 'urn:publicid:IDN+grnoc.iu.edu:GlobalNOC:CDS:1:Node',
				      name_services => ['http://localhost:8529/blah.cgi','http://localhost:8529/name_service.cgi'],
				      );

ok(defined($svc),"WebService client created with name_services");

ok($svc->{'urls'}->{'1'}[0] eq 'https://fake.grnoc.iu.edu/cds/1/node.cgi', "Found the CDS version 1 Node");


$svc->set_service_identifier("urn:publicid:IDN+grnoc.iu.edu:DOES:NOT:1:EXIST");

like($svc->get_error(), qr/\QUnable to find a usable URL for URN = urn:publicid:IDN+grnoc.iu.edu:DOES:NOT:1:EXIST in name services/, "got proper error message back");

