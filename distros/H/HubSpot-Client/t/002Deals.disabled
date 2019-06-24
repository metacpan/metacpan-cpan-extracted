use warnings;
use strict;
use Test::More;
use HubSpot::Client;
use Data::Dumper;

BEGIN {}

my $hub_id = $ENV{'HUBSPOT_HUB_ID'};
my $hub_api_key = $ENV{'HUBSPOT_API_KEY'};
SKIP: {
	skip "Environment variable HUBSPOT_API_KEY not defined; skipping tests", 1 if length $hub_api_key < 1;
	
	my $client = HubSpot::Client->new({ api_key => $hub_api_key, hub_id => $hub_id });

	my $deals = $client->deals_recently_modified(3);
	# I'll be happy if it didn't crash
	ok(1, "Retrieving deals");
	# Should get 3 back
	is(scalar(@$deals), 3, "Counting returned number of deals");

	# Each one should have a number of well-populated properties
	foreach my $deal (@$deals)
	{
		ok($deal->name, "Checking deal name is populated - '".$deal->name."'");
		ok($deal->id, "Checking deal ID is populated - '".$deal->id."'");
	}
}
done_testing();
