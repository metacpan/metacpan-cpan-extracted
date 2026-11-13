#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use HTTP::Response;
use Test::Mockingbird;
use Test::Most;
use Test::Needs { 'warnings::unused' => '0.04' };

# The constructor does a search, so give it an empty result set
mock 'Local::FakeUA::get' => sub {
	return HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], '{"results":[],"pagination":{}}');
};

use_ok('Genealogy::ChroniclingAmerica');
new_ok('Genealogy::ChroniclingAmerica' => [{
	firstname => 'John',
	lastname => 'Doe',
	state => 'Indiana',
	min_interval => 1,
	ua => bless({}, 'Local::FakeUA'),	# No need for the network
}]);
restore_all();

plan(tests => 2);
