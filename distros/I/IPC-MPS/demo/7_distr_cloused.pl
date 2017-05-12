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
		my ($vpid) = @_;
		unless ($NODE_CLOSED++) {
			print "NODE_CLOSED - CONNECTION\n";
			my $vpid = open_node($host, $port + 1) or die "Cannot open node: $!";
			snd($vpid, "ping", 10);
		}
	};

	snd($vpid, "ping", 0);
	receive {
		msg pong => sub {
			my ($from, $i, $pong) = @_;
			print "Ping ", $i, $pong, "\n";

			if ($i < 12) {
				snd($from, "ping", $i);
			} else {
			 	print snd_wt($from, "goal"), "\n";
			 	snd($from, "exit");
			}
		};
	};


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
