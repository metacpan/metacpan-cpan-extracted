# $Id: tcp-poe-optimized.pl,v 1.1 2009/01/15 09:45:40 dk Exp $
# An echo client-server benchmark.
#
# An optimized version, thanks to Rocco Caputo

use warnings;
use strict;

use Time::HiRes qw(time);
use POE qw(Wheel::ReadWrite Wheel::ListenAccept);
use IO::Socket::INET;

my $CYCLES = 500;
my $port   = 11211;

# Server.  Created before starting the timer, because other benchmarks
# also do this.

{
	POE::Session->create(
		inline_states => {
			_start          => \&start_server,
			client_accepted => \&start_reader,
			client_input    => \&handle_input,
			client_flushed  => \&handle_flush,
		},
	);

	sub start_server {
		my $serv_sock = IO::Socket::INET-> new(
			Listen    => 5,
			LocalPort => $port,
			Proto     => 'tcp',
			ReuseAddr => 1,
		) or die "listen() error: $!\n";
		$_[HEAP]{listener} = POE::Wheel::ListenAccept->new(
			Handle      => $serv_sock,
			AcceptEvent => "client_accepted",
		);
	}

	sub start_reader {
		my $readwrite = POE::Wheel::ReadWrite->new(
			Handle     => $_[ARG0],
			InputEvent => "client_input",
			FlushedEvent => "client_flushed",
		);
		$_[HEAP]{reader}{$readwrite->ID} = $readwrite;
	}

	sub handle_input {
		my ($input, $reader_id) = @_[ARG0, ARG1];
		$_[HEAP]{reader}{$reader_id}->put($input);
	}

	sub handle_flush {
		my $reader_id = $_[ARG0];
		delete $_[HEAP]{reader}{$reader_id};
	}
}

my $t = time;

# Client.

{
	my $connections = 0;

	POE::Session->create(
		inline_states => {
			_start   => sub { _make_connection($_[HEAP]) },
			readable => sub {
				delete $_[HEAP]{reader};
				if ($connections >= $CYCLES) {
					$_[KERNEL]->stop();
				}
				else {
					_make_connection($_[HEAP]);
				}
			}
		},
	);

	# Plain helper function.
	sub _make_connection {
		my $heap = shift;

		$connections++;

		my $x = IO::Socket::INET-> new(
			PeerAddr  => 'localhost',
			PeerPort  => $port,
			Proto     => 'tcp',
		) or die "connect() error: $!\n";

		my $reader = $heap->{reader} = POE::Wheel::ReadWrite->new(
			Handle => $x,
			InputEvent => "readable",
		);

		$reader->put("can write $connections");
	}
}

POE::Kernel->run();

$t = time - $t;
printf "%.3f sec\n", $t;
exit;
