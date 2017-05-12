# Ensure memory gained while tracing is disabled doesn't
# show up after enabled in strange places
use Devel::MemoryTrace::Light;

use lib 't/lib/';

use DMTraceProviderNextMem;

DB::disable_trace();

$DMTraceProviderNextMem::mem += 1024;

DB::enable_trace();

$DMTraceProviderNextMem::mem += 33;

print "hello world\n";

