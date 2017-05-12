# Make sure  provider doesn't skew results
use lib 't/lib/';

use DMTraceProviderNextMem;

use Devel::MemoryTrace::Light;

sub _report {
	my ($pkg, $file, $line, $mem) = @_;

	printf(">> $$ $pkg, $file ($line) used %d bytes\n", $mem);

	$DMTraceProviderNextMem::mem += 100;
}

DB::set_callback(\&_report);

$DMTraceProviderNextMem::mem += 1024;

$DMTraceProviderNextMem::mem += 0;

$DMTraceProviderNextMem::mem += 1024;

# So the previous line is considered before END time
print "hello world\n";
