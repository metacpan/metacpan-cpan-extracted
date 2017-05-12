$| = 1;
use strict;
use warnings;

use IPC::MPS;
my ($host, $port) = ("127.0.0.1", 9000);

if (fork) {
	sleep 1;
	my $vpid = open_node($host, $port) or die "Cannot open node: $!";
	my $j = 0;
	snd($vpid, "ping", 0);
	receive {
		msg pong => sub {
			my ($from, $i) = @_;
			is($i, ++$j, "Ping $i");
			if ($i < 3) {
				snd($from, "ping", $i);
			} else {
				is(snd_wt($vpid, "goal"), "Goal!!!", "Goal!!!");
				snd($from, "exit");
			}
		};
	};
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

sub is { print $_[0] eq $_[1] ? "" : "not ", "ok - ", $_[2], "\n" }
