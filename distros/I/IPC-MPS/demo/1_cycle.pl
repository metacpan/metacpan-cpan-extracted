$| = 1;
use strict;
use warnings;

use IPC::MPS;



my $ping_pong = 5;

sub ping_pong($) {
	my $vpid = shift;
	sub {
		msg ping => sub {
			my ($from, @args) = @_;
			print "Ping ", $args[0], " from $from\n";
			snd($from, "pong", $args[0]);
			if ($args[0] < $ping_pong) {
				snd($vpid, "ping", $args[0] + 1, $$);
			}
		};
		msg pong => sub {
			my ($from, @args) = @_;
			print "Pong ", $args[0], " from $from\n";
			unless ($args[0] < $ping_pong) {
				snd(0, "exit");
			}
		};
	};
}


my ($vpid1, $vpid2, $vpid3);

$vpid1 = spawn {
	snd($vpid2, "ping", 1, $$);
	receive { ping_pong($vpid2)->() };
};

$vpid2 = spawn { 
	receive { ping_pong($vpid3)->() };
};

$vpid3 = spawn { 
	receive { ping_pong($vpid1)->() };
};


receive {
	msg exit => sub {
		print "EXIT\n";
		exit;
	};
};
