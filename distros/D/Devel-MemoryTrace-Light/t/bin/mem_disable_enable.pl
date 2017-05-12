# Basic disable/enable test
use Devel::MemoryTrace::Light;

use lib 't/lib/';

use DMTraceProviderNextMem;

DB::disable_trace();

$DMTraceProviderNextMem::mem += 1024;

DB::enable_trace();

$DMTraceProviderNextMem::mem += 2048;

print "hello world\n";
