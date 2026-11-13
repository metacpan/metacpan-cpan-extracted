#!/usr/bin/env perl

# Test the handling of the Library of Congress' JSON without needing the network

use strict;
use warnings;

use CHI;
use HTTP::Response;
use JSON::MaybeXS;
use Test::Mockingbird;
use Test::Most;

BEGIN { use_ok('Genealogy::ChroniclingAmerica') }

my $pdf = 'https://tile.loc.gov/storage-services/test/0001.pdf';
my ($searches, $empty_searches, $text, @urls) = (0, 0, 'Mr John Smith of\nIndiana died');

sub json_response
{
	my $data = shift;

	return HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], encode_json($data));
}

# A stand-in for LWP::UserAgent
mock 'Local::FakeUA::get' => sub {
	my ($self, $url) = @_;

	$url = "$url";
	push @urls, $url;

	if($url =~ m{/collections/chronicling-america}) {
		$searches++;
		if($empty_searches) {
			$empty_searches--;
			return json_response({ results => [], pagination => {} });
		}
		return json_response({ results => [{ id => 'http://www.loc.gov/resource/sn1/1900-01-01/ed-1/?sp=1' }], pagination => {} });
	}
	if($url =~ /text-service/) {
		return json_response({ '/segment.xml' => { full_text => $text } });
	}
	if($url =~ m{/resource/sn1/}) {
		return json_response({ resource => { fulltext_file => 'https://tile.loc.gov/text-service', pdf => $pdf } });
	}
	return HTTP::Response->new(404, 'Not Found');
};

sub search
{
	return Genealogy::ChroniclingAmerica->new(
		firstname => 'john',
		lastname => 'smith',
		state => 'Indiana',
		min_interval => 0.01,
		ua => bless({}, 'Local::FakeUA'),
		cache => CHI->new(driver => 'Null'),
	);
}

subtest 'Text and PDF come from the resource section' => sub {
	my $ca = search();
	is($ca->{'matches'}, 1, 'One match found');
	is($ca->get_next_entry(), $pdf, 'Returns the PDF');
	ok(!defined($ca->get_next_entry()), 'No more matches');
	ok((grep { /text-service/ } @urls), 'The text was fetched from the text service');
};

subtest 'Items not mentioning the person are skipped' => sub {
	$text = 'Nothing of interest here';
	my $ca = search();
	ok(!defined($ca->get_next_entry()), 'Text without the name is skipped');
	$text = 'Mr John Smith of\nIndiana died';
};

subtest 'An empty search is retried once' => sub {
	($searches, $empty_searches) = (0, 1);
	my $ca = search();
	is($searches, 2, 'Searched twice');
	is($ca->{'matches'}, 1, 'The retry found the match');

	($searches, $empty_searches) = (0, 5);
	$ca = search();
	is($searches, 2, 'Only retries once');
	is($ca->{'matches'}, 0, 'Reports no matches');
	ok(!defined($ca->get_next_entry()), 'Nothing to return');
};

restore_all();

done_testing();
