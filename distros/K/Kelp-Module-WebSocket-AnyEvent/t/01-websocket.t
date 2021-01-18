use strict;
use warnings;

use Test::More;
use LWP::UserAgent;
use HTTP::Request;

use lib 't/lib';
use TwiggyTester;
use WebSocketTest;

my $app = WebSocketTest->new(mode => 'no_serializer');
my @messages = (
	undef,
	'test',
	'websocket operating',
	'count',
	'count',
	'count'
);

my @expected_results = (
	'opened',
	'got message: "test"',
	'got message: "websocket operating"',
	0,
	1,
	2
);

# will do all the websocket testing
my $server = twiggy_test($app, \@messages, \@expected_results, 5);

my $agent = LWP::UserAgent->new;
my $base_addr = "http://127.0.0.1:" . $server->port;
my @cases = (
	["$base_addr/kelp", 1, "kelp still there"],
	[$base_addr, 0],
	["$base_addr/closed", 1, 5],
);

for my $case_ref (@cases) {
	my $request = HTTP::Request->new(GET => $case_ref->[0]);
	my $response = $agent->request($request);
	ok 0 + $response->is_success == 0 + $case_ref->[1], "$case_ref->[0] request ok";
	if (defined $case_ref->[2]) {
		is $response->decoded_content, $case_ref->[2], "returns valid response";
	}
}

undef $server;
done_testing;
