use warnings;
use strict;
use Test::More;
use Test::Exception;
use HubSpot::Engagement;
use Data::Dumper;

BEGIN {}

subtest "Engagement types" => sub {
	dies_ok(sub {HubSpot::Engagement->new()}, "Die if engagement type isn't specified");
	ok(sub {HubSpot::Engagement->new(type => Hubspot::Engagement->NOTE)}, "Type NOTE via constant");
	ok(sub {HubSpot::Engagement->new(type => 'NOTE')}, "Type NOTE via string");
	ok(sub {HubSpot::Engagement->new(type => Hubspot::Engagement->EMAIL)}, "Type EMAIL via constant");
	ok(sub {HubSpot::Engagement->new(type => 'EMAIL')}, "Type EMAIL via string");
	ok(sub {HubSpot::Engagement->new(type => Hubspot::Engagement->CALL)}, "Type CALL via constant");
	ok(sub {HubSpot::Engagement->new(type => 'CALL')}, "Type CALL via string");
	ok(sub {HubSpot::Engagement->new(type => Hubspot::Engagement->MEETING)}, "Type MEETING via constant");
	ok(sub {HubSpot::Engagement->new(type => 'MEETING')}, "Type MEETING via string");
	ok(sub {HubSpot::Engagement->new(type => Hubspot::Engagement->TASK)}, "Type TASK via constant");
	ok(sub {HubSpot::Engagement->new(type => 'TASK')}, "Type TASK via string");
	dies_ok(sub {HubSpot::Engagement->new(type => Hubspot::Engagement->FOO)}, "Die on unknown type via constant");
	dies_ok(sub {HubSpot::Engagement->new(type => 'FOO')}, "Die on unknown type via string");
};

done_testing();
