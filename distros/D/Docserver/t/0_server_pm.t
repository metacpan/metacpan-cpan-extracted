#!/usr/bin/perl -w

use strict;

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
	print "1..0\nNo server should be run on this machine, good.\n";
	exit;
}


print "1..1\nWill try to do use Docserver.\n";
eval 'use Docserver';
print "ok 1\n";

