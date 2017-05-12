# $Id: tcp-poe-raw.pl,v 1.1 2009/01/17 11:29:06 dk Exp $
# An echo client-server benchmark.

use warnings;
use strict;

use Time::HiRes qw(time);
use POE;
use IO::Socket::INET;

my $CYCLES = 500;
my $port   = 11211;

# Server.  Created before starting the timer, because other benchmarks
# also do this.

{
	POE::Session->create(
		inline_states => {
			_start          => \&start_server,
			server_readable => \&accept_connection,
			client_readable => \&handle_input,
		},
	);

	sub start_server {
		my $serv_sock = IO::Socket::INET-> new(
			Listen    => 5,
			LocalPort => $port,
			Proto     => 'tcp',
			ReuseAddr => 1,
		) or die "listen() error: $!\n";

		$_[KERNEL]->select_read($serv_sock, "server_readable");
	}

	sub accept_connection {
		my $serv_sock = $_[ARG0];
		my $conn = IO::Handle->new();
		accept($conn, $serv_sock) or die "accept() error: $!";
		$_[KERNEL]->select_read($conn, "client_readable");
		$conn->blocking(1);
		$conn->autoflush(1);
	}

	sub handle_input {
		my $conn = $_[ARG0];
		my $input = <$conn>;
		if (defined $input) {
			print $conn $input;
		}
		else {
			$_[KERNEL]->select_read($conn, undef);
		}
	}
}

my $t = time;

# Client.

{
	my $connections = 0;

	POE::Session->create(
		inline_states => {
			_start   => sub { _make_connection($_[KERNEL]) },
			readable => sub {
				my $sock = $_[ARG0];
				$_[KERNEL]->select_read($sock, undef);
				if ($connections >= $CYCLES) {
					$_[KERNEL]->stop();
				}
				else {
					_make_connection($_[KERNEL]);
				}
			}
		},
	);

	# Plain helper function.
	sub _make_connection {
		my $kernel = shift;

		$connections++;
		my $x = IO::Socket::INET-> new(
			PeerAddr  => 'localhost',
			PeerPort  => $port,
			Proto     => 'tcp',
		) or die "connect() error: $!$^E\n";

		$x->autoflush(1);
		print $x "can write $connections\n";

		$kernel->select_read($x, "readable");
	}
}

POE::Kernel->run();

$t = time - $t;
printf "%.3f sec\n", $t;
exit;
