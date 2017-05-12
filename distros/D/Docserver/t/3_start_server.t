#!/usr/bin/perl -w

use strict;

my $PIDFILE = 'docserver.pid';

unlink $PIDFILE;

my $run_server = 'n';
if (open CONFIG, "testcfg") {
	while (<CONFIG>) {
		if (/^run_server\s*:\s*(y|n)/) {
			$run_server = $1;
		}	
	}
	close CONFIG;
}

if ($run_server eq 'n') {
	print "1..0\nNo server should be run on this machine.\n";
	exit;
}


print "1..2\nWill run bin/docserver.pl\n";

# This did not detach correctly because it inherited filehandles,
# so we use Win32::Process::Create instead.
# system "start $^X -Ilib bin/docserver.pl";

eval 'use Win32::Process;';

my $process;
Win32::Process::Create($process, 
	$^X,
	qq!$^X -Ilib bin/docserver.pl!,
	0,
	&CREATE_NEW_CONSOLE(),
	'.');

for (my $i = 0 ; $i < 16 ; $i++) {
	if (-f $PIDFILE) {
		last;
	}
	if ($i == 15) {
		print "The server didn't start in 15 seconds.\nnot ok 1\n";
		exit;
	}
	sleep 1;
}

print "ok 1\n";
print "The docserver seems to have started OK.\n";

if (open IN, $PIDFILE) {
	my $PID = <IN>;
	close IN;
	chomp $PID;

	print "The pid seems to be $PID\n";
	if (kill 0, $PID) {
		print "The process is running alright.\nok 2\n";
	} else {
		print "But the process doesn't seem to run.\nnot ok 2\n";
	}
} else {
	print "But the pidfile $PIDFILE is not readable.\nnot ok 2.\n";
}

