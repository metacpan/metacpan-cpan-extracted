# Basic callback test case
use lib 't/lib/';

use Devel::MemoryTrace::Light;

use DMTraceProviderNextMem;

sub c_callback {
	print "I caught @_ !\n";
}

$DMTraceProviderNextMem::mem = 1;

DB::set_callback(\&c_callback);

$DMTraceProviderNextMem::mem += 2;

DB::restore_callback();

$DMTraceProviderNextMem::mem += 4;

print "hello world\n";
