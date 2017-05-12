#!/usr/bin/perl

use Business::FedEx::ShipRequest;
use Data::Dumper;

my $fe = Business::FedEx::ShipRequest->new();
	      

$fe->track('yo', 'hey', 'http://10.2.0.2:9500/cgi-bin/fedex.pl', '823883459321');

$data = $fe->get_data('num_tracking_activities');

print "$data, Done\n";
