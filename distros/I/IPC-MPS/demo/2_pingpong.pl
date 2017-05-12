$| = 1;
use strict;
use warnings;

use IPC::MPS;

my $ping_pong = 3;

my ($vpid1, $vpid2);

$vpid1 = spawn {
	snd($vpid2, "ping", 1);
	receive { 
		msg pong => sub {
			my ($from, $i) = @_;
			print "Pong $i from $from\n";
			if ($i < $ping_pong) {
				snd($from, "ping", $i + 1);
			} else {
				snd(0, "exit");
			}
		};
	};
};

$vpid2 = spawn { 
	receive {
		msg ping => sub {
			my ($from, $i) = @_;
			print "Ping ", $i, " from $from\n";
			snd($from, "pong", $i);
		};
	};
};

receive {
	msg exit => sub {
		print "EXIT\n";
		exit;
	};
};
