# Test to make sure the provider is working
use lib 't/lib/';

use DMTraceProviderNextMem;

$DMTraceProviderNextMem::mem = 5;

for (1..5) {
	$DMTraceProviderNextMem::mem *= 2;
}

print "hello world\n";
