# Memory tracing enabled after start=no
use lib 't/lib/';

use DMTraceProviderNextMem;

$DMTraceProviderNextMem::mem = 1024;

DB::enable_trace();

$DMTraceProviderNextMem::mem += 2048;

print "hello world\n";

