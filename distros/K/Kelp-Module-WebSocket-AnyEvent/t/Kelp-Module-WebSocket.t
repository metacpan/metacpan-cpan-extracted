use strict;
use warnings;

use Test::More;
use Test::TCP;
use Plack::Loader;
use LWP::UserAgent;
use HTTP::Request;
use AnyEvent::WebSocket::Client;
use AnyEvent;

{
	package WebSocket::Test;
	use Kelp::Less;

	module "Symbiosis";
	module "WebSocket::AnyEvent";

	my $closed;
	my $ws = app->websocket;
	$ws->add(open => sub { shift->send("opened") });
	$ws->add(message => sub {
		my ($conn, $message) = @_;
		$conn->send("got message: $message");
	});
	$ws->add(close => sub {
		$closed = 1;
	});

	app->symbiosis->mount("/ws", $ws);

	route "/kelp" => sub {
		"kelp still there";
	};

	route "/closed" => sub {
		$closed ? "yes" : "no";
	};

	sub get_app
	{
		return app;
	}

	1;
}

my $app = WebSocket::Test::get_app();
my $condvar = AnyEvent->condvar;

my $server = Test::TCP->new(
	code => sub {
		my ($port) = @_;

		my $server = Plack::Loader->load('Twiggy', port => $port, host => "127.0.0.1");
		$server->run($app->run_all);
	},
);

my @expected_messages = (
	["opened" => undef],
	["got message: test" => "test"],
	["got message: websocket operating" => "websocket operating"],
);

my $client = AnyEvent::WebSocket::Client->new;
$client->connect("ws://127.0.0.1:" . $server->port . "/ws")->cb(sub {
	our $connection = eval { shift->recv };
	if ($@) {
		fail $@;
		return;
	}

	$connection->on(each_message => sub {
		my ($connection, $message) = @_;
		if (@expected_messages) {
			my $t = shift @expected_messages;
			is $message->{body}, $t->[0], "message matches";
		}
		if (!@expected_messages) {
			$connection->close;
			note "Closing connection";
			$condvar->send;
		}
	});

	for my $t (@expected_messages) {
		$connection->send($t->[1])
			if defined $t->[1];
	}
});

my $w = AnyEvent->timer(after => 5, cb => sub {
	fail "event loop was not stopped";
	$condvar->send;
});

$condvar->recv;
undef $w;

my $agent = LWP::UserAgent->new;
my $base_addr = "http://127.0.0.1:" . $server->port;
my @cases = (
	["$base_addr/kelp", 1, "kelp still there"],
	[$base_addr, 0],
	["$base_addr/closed", 1, "yes"],
);

for my $case_ref (@cases) {
	my $request = HTTP::Request->new(GET => $case_ref->[0]);
	my $response = $agent->request($request);
	ok 0+ $response->is_success == 0+ $case_ref->[1], "$case_ref->[0] request ok";
	if (defined $case_ref->[2]) {
		is $response->decoded_content, $case_ref->[2], "returns valid response";
	}
}

undef $server;
done_testing;
