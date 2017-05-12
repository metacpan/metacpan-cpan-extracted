# Basic memory usage test case
use lib 't/lib/';

use DMTraceProviderFork;

print "Parent pid: $$\n";

$DMTraceProviderNextMem::mem = 1024;

print "Forked main: $DMTraceProviderFork::forked\n";

my $pid = fork;

if (! defined $pid) {
	die "Failed to fork: $!\n";
} elsif ($pid) {
	$DMTraceProviderNextMem::mem += 100;

	print "Forked parent: $DMTraceProviderFork::forked\n";
} else {
	print "Child pid: $$\n";

	$DMTraceProviderNextMem::mem += 50;

	print "Forked child: $DMTraceProviderFork::forked\n";
}


print "hello world\n";
