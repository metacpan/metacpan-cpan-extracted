#!/usr/bin/perl -w

my $PIDFILE = 'docserver.pid';

if (-f $PIDFILE and open IN, $PIDFILE) {
	my $PID = <IN>;
	close IN;
	chomp $PID;

	if (kill 0, $PID) {
		print "1..1\nThere seems to be a docserver running, pid $PID.\n";

		kill 9, $PID;
		sleep 1;

		if (kill 0, $PID) {
			print "Killing it failed.\nnot ok 1\n";
		} else {
			print "Killed OK.\nok 1\n";
		}
	}
	unlink $PIDFILE;
	exit;
}

unlink $PIDFILE;
print "1..0\nNo docserver seems to be running, OK.\n";

