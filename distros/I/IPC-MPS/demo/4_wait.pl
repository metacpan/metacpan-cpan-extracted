$| = 1;
use strict;
use warnings;

use IPC::MPS;

my $vpid = spawn {
	receive { 
		msg foo => sub {
			my ($from, $text) = @_;
			print "foo: $text\n";

			snd(0, "too", 1);
			print "too -> baz\n";

			my $rv = wt(0, "baz");
			print "baz: $rv\n";

			my @rv = snd_wt(0, "sugar", $rv);
			print "sugar: $rv[0]\n";

			my $n = 2;
			snd(0, "sugar", $_)                                       foreach (0 .. $n);
			print "wt multy: ",    scalar wt(0, "sugar"),"\n"         foreach (0 .. $n);
			print "sugar multy: ", scalar snd_wt(0, "sugar", $_),"\n" foreach (0 .. $n);

			exit;
		};
	};
};


snd($vpid, "foo", "Hello, wait");

receive {
	msg too => sub {
		my ($from, $i) = @_;
		print "too: $i\n";
		snd($from, "baz", ++$i);
	};
	msg sugar => sub {
		my ($from, $i) = @_;
		snd($from, "sugar", ++$i);
	};
};
