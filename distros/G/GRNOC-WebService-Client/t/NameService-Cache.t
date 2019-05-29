#!/usr/bin/perl

use Test::More tests => 4;

use strict;
use GRNOC::WebService::Client;
use JSON::XS;
use Data::Dumper;
use FindBin;
my $svc = GRNOC::WebService::Client->new(
					 service_name => 'urn:publicid:IDN+grnoc.iu.edu:GlobalNOC:CDS:1:Node',
					 service_cache_file => $FindBin::Bin . '/conf/name_service.xml'
					);

ok(defined $svc ,"GRNOC::WebService::Client new() seems to work");
ok($svc->{'urls'}->{'1'}[0] eq 'https://fake.grnoc.iu.edu/cds/1/node.cgi', "Found the CDS version 1 Node");

$svc->set_service_identifier("urn:publicid:IDN+grnoc.iu.edu:GlobalNOC:CDS:1:Node");

is(@{$svc->{'urls'}->{'1'}}, 1, "still only 1 resolveable URL");


$svc->set_service_identifier("urn:publicid:IDN+grnoc.iu.edu:DOES:NOT:1:EXIST");

like($svc->get_error(), qr/\QUnable to find a usable URL for URN = urn:publicid:IDN+grnoc.iu.edu:DOES:NOT:1:EXIST in service cache file/, "got proper error message back");
