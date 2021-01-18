package WebSocketTest;

use strict;
use warnings;
use parent 'Kelp';

use Test::More;

sub build
{
	my $self = shift;
	my $closed = 0;

	my $r = $self->routes;
	my $ws = $self->websocket;

	$r->add(
		"/kelp" => sub {
			"kelp still there";
		}
	);

	$r->add(
		"/closed" => sub {
			$closed;
		}
	);

	my $last_connected = 1;
	$ws->add(
		open => sub {
			my $conn = shift;
			$conn->data->{counter} = 0;

			isa_ok $conn, 'Kelp::Module::WebSocket::AnyEvent::Connection';
			isa_ok $conn->manager, 'Kelp::Module::WebSocket::AnyEvent';
			is $conn->id, $last_connected++, 'autoincrement id ok - ' . $conn->id;

			$conn->send("opened");
		}
	) unless $self->mode eq 'serializer_json';

	$ws->add(
		message => sub {
			my ($conn, $message) = @_;
			if (ref $message eq ref {}) {
				$conn->send({got => $message});
			}
			else {
				if ($message eq 'count') {
					$conn->send($conn->data->{counter}++);
				}
				else {
					$message = $self->json->encode($message);
					$conn->send("got message: $message");
				}
			}
		}
	);

	$ws->add(
		malformed_message => sub {
			my ($conn, $message, $err) = @_;
			$conn->send({error => $err, message => $message});
		}
	);

	$ws->add(
		close => sub {
			$closed += 1;
		}
	);

	$self->symbiosis->mount("/ws", $ws);
}

1;
