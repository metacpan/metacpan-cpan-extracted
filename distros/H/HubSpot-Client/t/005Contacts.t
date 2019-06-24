use warnings;
use strict;
use Test::More;
use HubSpot::Client;
use Data::Dumper;

BEGIN {}

my $rate_limit_delay = 1;

my $hub_id = $ENV{'HUBSPOT_HUB_ID'};
my $hub_api_key = $ENV{'HUBSPOT_API_KEY'};
SKIP: {
	skip "Environment variable HUBSPOT_API_KEY not defined; skipping tests", 1 if length $hub_api_key < 1;
	
	my $client = HubSpot::Client->new({ api_key => $hub_api_key, hub_id => $hub_id });

	my $contacts = $client->contacts(3);
	ok(1, "Retrieving specified number of contacts, below 250");
	# Should get exactly the number we asked for back. All returned in one page
	is(scalar(@$contacts), 3, "Counting returned number of owners");

	# PROPERTIES
	my $contact = $$contacts[0];
	like($contact->id, qr/^\d{3,}/, "Checking contact ID is populated - '".$contact->id."'");
	is(length($contact->firstName) > 0, 1, "Checking contact first name is populated - '".$contact->firstName."'");
	is(length($contact->getProperty('firstname')) > 0, 1, "Checking contact first name is populated when retrieved by getProperty - '".$contact->getProperty('firstname')."'");
	is(length($contact->lastName) > 0, 1, "Checking contact last name is populated - '".$contact->lastName."'");
	#~ is(length($contact->company) > 0, 1, "Checking contact company is populated - '".$contact->company."'");
	isa_ok($contact->lastModifiedDateTime, 'DateTime', "Checking lastModifiedDateTime is populated - ".$contact->lastModifiedDateTime->iso8601());
	is(scalar(keys %{$contact->properties}) > 0, 1, "Checking properties property is populated");

	#~ diag(Data::Dumper->Dump([$contact]));

	my $username = qr/[a-z0-9_+]([a-z0-9_+.]*[a-z0-9_+])?/;
	my $domain   = qr/[a-z0-9.-]+/;
	like($contact->primaryEmail, qr/^$username\@$domain$/, "Checking contact email is populated - '".$contact->primaryEmail."'");

	# PAGINATION
	$contacts = $client->contacts(251);
	ok(1, "Retrieving specified number of contacts, above 250");
	SKIP: {
		skip "Not enough contacts to test pagination", 2 if scalar(@$contacts) < 251;

		# Should get exactly the number we asked for back. Requires pagination
		is(scalar(@$contacts), 251, "Counting returned number of owners");
		# TO make sure we are getting different pages and adding them up and not just getting the same page
		# (ie pagination is working), compare the first result of the first page to what should be the
		# first result of the second page. They should have different ids
		isnt($$contacts[0]->id, $$contacts[250]->id, "Getting successive pages");
	}
	
	# SINGLE CONTACT
	my $id_contact = $client->contact_by_id($contact->id);
	ok($id_contact, "Retrieving a specified contact by ID");
	ok(scalar(keys %{$id_contact->properties} > 10, "Contact should have lots of properties"));
	is($client->contact_by_id(""), undef, "Not found contact returns undef"); 
}
done_testing();
