package TwiggyTester;

use strict;
use warnings;
use Exporter qw(import);
use Test::More;
use Test::TCP;
use Plack::Loader;
use AnyEvent::WebSocket::Client;
use AnyEvent;
use Try::Tiny;

our @EXPORT = qw(twiggy_test);

sub twiggy_test
{
	my ($app, $messages_ref, $expected_results_ref, $count) = @_;
	$count //= 1;
	my @results;

	my $condvar = AE::cv;
	my $server = Test::TCP->new(
		code => sub {
			my ($port) = @_;

			my $server = Plack::Loader->load('Twiggy', port => $port, host => "127.0.0.1");
			$server->run($app->run_all);
		},
	);

	my @clients;
	my @connections;
	my $open_count = $count;
	for my $cnt (1 .. $count) {
		my $data = [
			[@$messages_ref],
			[],
		];
		push @results, $data;

		my $client = AnyEvent::WebSocket::Client->new;
		push @clients, $client;

		my $this_connection;
		push @connections, \$this_connection;

		$client->connect("ws://127.0.0.1:" . $server->port . "/ws")->cb(
			sub {
				my $arg = shift;
				my $err;
				try {
					$this_connection = $arg->recv
				}
				catch {
					my $err = $_;
					fail $err;
				};

				return if $err;

				$this_connection->on(
					each_message => sub {
						my ($connection, $message) = @_;
						push @{$data->[1]}, $message->{body};

						if (@{$data->[0]}) {
							$connection->send(shift @{$data->[0]});
						}
						else {
							$connection->close;
							note "Closing connection";
							if (--$open_count == 0) {
								$condvar->send;
							}
						}
					}
				);

				my $first_message = shift @{$data->[0]};
				$this_connection->send($first_message)
					if defined $first_message;
			}
		);
	}

	my $w = AE::timer 10, 0, sub {
		fail "event loop was not stopped";
		$condvar->send;
	};

	$condvar->recv;
	undef $w;

	is scalar @results, $count, 'count ok';
	for my $res (@results) {
		is scalar @{$res->[0]}, 0, 'all messages sent ok';
		is scalar @{$res->[1]}, scalar @{$expected_results_ref}, 'results count ok';
		for my $data (@{$expected_results_ref}) {
			my $result = shift @{$res->[1]};
			if (ref $data eq 'Regexp') {
				like $result, $data, 'message like ok';
			}
			else {
				is $result, $data, 'message is ok';
			}
		}
	}

	return $server;
}

1;
