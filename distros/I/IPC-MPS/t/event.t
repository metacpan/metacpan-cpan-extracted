use strict;
use warnings;

use Test::More;

BEGIN {
	eval { require Event };
	if ($@) {
		plan skip_all => "module Event required";
	} else {
		plan tests => 6;
		use_ok("IPC::MPS::Event");
	}
}


my $vpid = spawn { 
	receive {
		msg ping => sub {
			my ($from, $i) = @_;
			snd($from, "pong", $i + 1);
		};
		msg goal => sub {
			my ($from, $i) = @_;
			snd($from, "goal", "Goal!!!");
		};
	};
};

snd($vpid, "ping", 0);
receive {
	ok(vpid2pid($vpid), "PID");
	my $j = 0;
	msg pong => sub {
		my ($from, $i) = @_;
		is($i, ++$j, "Ping $i");
		if ($i < 3) {
			snd($from, "ping", $i);
		} else {
			is(snd_wt($vpid, "goal"), "Goal!!!", "Goal!!!");
			exit;
		}
	};
};
