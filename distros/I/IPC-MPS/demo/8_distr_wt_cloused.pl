
$| = 1;
use strict;
use warnings;

use IPC::MPS;
my ($host, $port) = ("127.0.0.1", 9000);

if (fork) {
	sleep 1;
	my $vpid = open_node($host, $port) or die "Cannot open node: $!";

	my $NODE_CLOSED;
	msg NODE_CLOSED => sub { 
		unless ($NODE_CLOSED++) {
			print "NODE_CLOSED - CONNECTION\n";
			$vpid = open_node($host, $port + 1) or die "Cannot open node: $!";
		}
	};

	foreach (0 .. 6) {
		snd($vpid, "ping", $_);
		print "Ping ", wt($vpid, "pong"), "\n";
	}

	print snd_wt($vpid, "goal"), "\n";
	snd_wt($vpid, "exit");

} else {
	if (fork) {
		server($host, $port);
	} else {
		server($host, $port + 1);
		exit;
	}
	exit;
}

sub server {
	my ($host, $port) = @_;
	listener($host, $port);
	receive {
		my $j = 0;
		msg ping => sub {
			my ($from, $i) = @_;
			snd($from, "pong", $i + 1, " - Pong from $$");
			exit if ++$j > 3;
		};
		msg goal => sub {
			my ($from, $i) = @_;
			snd($from, "goal", "Goal!!!");
		};
		msg exit => sub {
			print "EXIT\n";
			exit;
		};
	};
}
