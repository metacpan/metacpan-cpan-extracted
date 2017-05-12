$| = 1;
use strict;
use warnings;

use IPC::MPS;

my $vpid1 = spawn {

	my $vpid2 = spawn {
		receive { 
		 	msg hello2 => sub {
		 		print "Hello 2\n";
		 	};
		};
	};

	receive {
		msg hello1 => sub {
			print "Hello 1\n";
			snd($vpid2, "hello2");

			my $vpid3 = spawn {
				receive { 
					msg hello3 => sub {
						print "Hello 3\n";
					};
				};
			};

			snd($vpid3, "hello3");
			receive {};
		};
	};
};

spawn {
	sleep 1;
	print "SLEEP\n";
	snd(0, "exit");
	receive {};
};

snd($vpid1, "hello1");
receive {
	msg exit => sub {
		print "EXIT\n";
		exit;
	};
};
