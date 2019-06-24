use warnings;
use strict;
use Test::More;
use Test::Exception;
use HubSpot::Client;
use Data::Dumper;

BEGIN {}

my $hub_id = $ENV{'HUBSPOT_HUB_ID'};
my $hub_api_key = $ENV{'HUBSPOT_API_KEY'};
SKIP: {
	skip "Environment variable HUBSPOT_API_KEY not defined; skipping tests", 1 if length $hub_api_key < 1;

	# Client object is created OK with a test API key
	ok(sub {HubSpot::Client->new({ api_key => '6a2f41a3-c54c-fce8-32d2-0324e1c32e22', hub_id => '9999' })}, "Client creation with example API key");
	ok(sub {HubSpot::Client->new({ api_key => '', hub_id => '9999' })}, "Client creation OK with empty API key; key ignored");
	ok(sub {HubSpot::Client->new({ api_key => undef, hub_id => '9999' })}, "Client creation OK with undefined API key; key ignored");
	dies_ok(sub {HubSpot::Client->new({ api_key => 'foo', hub_id => '9999' })}, "Client creation dies with nonsense API key");
	ok(sub {HubSpot::Client->new({ hub_id => '9999' })}, "Client creation is OK with no API key");
}
done_testing();
