# $Id: tcp-poe-components.pl,v 1.1 2009/01/17 11:26:53 dk Exp $
# An POE::Component::{Server,Client}::TCP based echo client/server benchmark.

use warnings;
use strict;

use Time::HiRes qw(time);
use POE qw(Component::Server::TCP Component::Client::TCP);
use IO::Socket::INET;

my $CYCLES = 500;
my $port   = 11211;

# Echo server.  Created before starting the timer, because other
# benchmarks also do this.

POE::Component::Server::TCP->new(
	Address => '127.0.0.1',
	Port => $port,
	ClientInput => sub { $_[HEAP]{client}->put($_[ARG0]); },
);

my $t = time;

# Client.  Client creation is part of the benchmark.

{
	my $connections = 0;

	POE::Component::Client::TCP->new(
		RemoteAddress => '127.0.0.1',
		RemotePort => $port,
		Connected => sub {
			$connections++;
			$_[HEAP]{server}->put("can write $connections");
		},
		ServerInput => sub {
			if ($connections >= $CYCLES) {
				$_[KERNEL]->stop();
			}
			else {
				$_[KERNEL]->yield("reconnect");
			}
		},
	)
}

POE::Kernel->run();

$t = time - $t;
printf "%.3f sec\n", $t;
exit;
