
$| = 1;
use strict;
use warnings;

use IPC::MPS;
my ($host, $port) = ("127.0.0.1", 9000);

if (fork) {
	sleep 1;
	my $vpid = open_node($host, $port) or die "Cannot open node: $!";

	my $n = 2;
	snd($vpid, "ping", $_)                 foreach 0 .. $n;
	print "Ping ", wt($vpid, "pong"), "\n" foreach 0 .. $n;

	print snd_wt($vpid, "goal"), "\n";
	snd_wt($vpid, "exit");

} else {
	listener($host, $port);
	receive {
		msg ping => sub {
			my ($from, $i) = @_;
			snd($from, "pong", $i + 1);
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
	exit;
}
