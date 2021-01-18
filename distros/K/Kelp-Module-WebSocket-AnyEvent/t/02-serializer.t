use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TwiggyTester;
use WebSocketTest;

my $app = WebSocketTest->new(mode => 'serializer_json');
my $json = $app->json;

my @messages = (
	$json->encode({"a msg" => 1}),
	$json->encode({hash => \1}),
	'["this is not a json"',
);

my @expected_results = (
	'{"got":{"a msg":1}}',
	'{"got":{"hash":true}}',
	qr{"error":".*"message":"\[\\"this is not a json\\""}i,
);

# will do all the websocket testing
my $server = twiggy_test($app, \@messages, \@expected_results, 3);
undef $server;

done_testing;
