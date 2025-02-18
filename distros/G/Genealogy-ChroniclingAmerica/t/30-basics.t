#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use LWP::UserAgent;
use JSON::MaybeXS;
use Test::MockObject;

BEGIN { use_ok('Genealogy::ChroniclingAmerica') }

subtest 'Constructor Tests' => sub {
	# Test valid object creation
	my $obj = Genealogy::ChroniclingAmerica->new({
		firstname => 'John',
		lastname => 'Doe',
		state => 'Indiana'
	});
	isa_ok($obj, 'Genealogy::ChroniclingAmerica', 'Object is created successfully');

	# Test missing mandatory parameters
	dies_ok { Genealogy::ChroniclingAmerica->new({ lastname => 'Doe', state => 'Indiana' }) } 'Dies without firstname';
	dies_ok { Genealogy::ChroniclingAmerica->new({ firstname => 'John', state => 'Indiana' }) } 'Dies without lastname';
	dies_ok { Genealogy::ChroniclingAmerica->new({ firstname => 'John', lastname => 'Doe' }) } 'Dies without state';

	# Test state abbreviation failure
	dies_ok { Genealogy::ChroniclingAmerica->new({ firstname => 'John', lastname => 'Doe', state => 'IN' }) } 'Dies with state abbreviation';

	# Test numeric input failure
	dies_ok { Genealogy::ChroniclingAmerica->new({ firstname => '123', lastname => 'Doe', state => 'Indiana' }) } 'Dies with numeric firstname';
	dies_ok { Genealogy::ChroniclingAmerica->new({ firstname => 'John', lastname => '456', state => 'Indiana' }) } 'Dies with numeric lastname';
	dies_ok { Genealogy::ChroniclingAmerica->new({ firstname => 'John', lastname => 'Doe', state => 'Indiana123' }) } 'Dies with numeric state';
};

subtest 'get_next_entry simple tests' => sub {
	my $obj = Genealogy::ChroniclingAmerica->new({
		firstname => 'John',
		lastname => 'Xyzzy',
		state => 'Indiana',
	});

	can_ok($obj, 'get_next_entry');
	is($obj->get_next_entry(), undef, 'Returns undef when no matches are found');
};

subtest 'get_next_entry thorough tests' => sub {
	my $mock_ua = Test::MockObject->new();
	$mock_ua->fake_module('LWP::UserAgent', new => sub { return shift });
	$mock_ua->mock('get', sub {
		my $site = $_[1];
		my $mock_resp = Test::MockObject->new();

		$mock_resp->mock('is_error', sub { 0 });
		$mock_resp->mock('is_success', sub { 1 });
		$mock_resp->mock('content', sub {
			if(($site eq 'http://example.com')) {
				'{"pdf":"https://nigelhorne.com"}'
			} else {
				'{"items":[{"url":"http://example.com","ocr_eng":"John Xyzzy"}],"totalItems":1,"itemsPerPage":1}'
			}
		});
		return $mock_resp;
	});

	my $obj = Genealogy::ChroniclingAmerica->new({
		firstname => 'John',
		lastname => 'Xyzzy',
		state => 'Indiana',
		ua => $mock_ua,
	});

	can_ok($obj, 'get_next_entry');
	is($obj->get_next_entry(), 'https://nigelhorne.com', 'Returns expected URL when match is found');
	is($obj->get_next_entry(), undef, 'Returns undef when no more matches');
};

done_testing();
