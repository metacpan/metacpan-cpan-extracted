# Basic memory usage test case
use lib 't/lib/';

use DMTraceProviderNextMem;

$DMTraceProviderNextMem::mem = 1024;

# So the previous line is considered before END time
print "hello world\n";
