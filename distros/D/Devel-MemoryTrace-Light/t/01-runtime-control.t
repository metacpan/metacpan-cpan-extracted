use strict;
use warnings;

use Test::More;

plan tests => 13;

use Config;

my $perlbin;

eval "require Probe::Perl";

unless ($@) {
	$perlbin = Probe::Perl->find_perl_interpreter();
}

$perlbin ||= $Config{perlpath};

my $includes = '-I t/lib/';

my $p_arg = 'provider=DMTraceProviderNextMem:';

# Use custom provider so we control when mem increases
$ENV{MEMORYTRACE_LIGHT} = $p_arg;

# disable_trace/enable_trace
my $output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_disable_enable.pl 2>&1`;

unlike($output, qr/^>> \d+ main, .*mem_disable_enable.pl \(\d+\) used 1024 bytes$/m,
	'program was not traced with DB::disable_trace()');

like($output, qr/^>> \d+ main, .*mem_disable_enable.pl \(14\) used 2048 bytes$/m,
	'program was traced after call to DB::enable_trace(); increase detected');

like($output, qr/hello world/, 'program ran successfully');

# memory growth when tracing is disabled gets ignored
$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_disable_enable_2.pl 2>&1`;

unlike($output, qr/^>> \d+ main, .*mem_disable_enable_2.pl \(\d+\) used 1024 bytes$/m,
	'program did not incorrectly report growth immediately after enable_trace()');

like($output, qr/^>> \d+ main, .*mem_disable_enable_2.pl \(15\) used 33 bytes$/m,
	'program correctly reported growth after enable_trace() and actual growth');

like($output, qr/hello world/, 'program ran successfully');

# enable after start=no
$ENV{MEMORYTRACE_LIGHT} = "${p_arg}start=no";

$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_enable.pl 2>&1`;

unlike($output, qr/^>> \d+ main, .*mem_enable.pl \(6\) used \d+ bytes$/m,
	'program was not traced with start=no');

like($output, qr/^>> \d+ main, .*mem_enable.pl \(10\) used 2048 bytes$/m,
	'program traced after DB::enable_trace() after start=no; increase detected');

like($output, qr/hello world/, 'program ran successfully');

# Test custom callback
$ENV{MEMORYTRACE_LIGHT} = $p_arg;

$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_callback.pl 2>&1`;

like($output, qr/^>> \d+ main, .*mem_callback.pl \(12\) used 1 bytes$/m,
	'program printed default trace output');

like($output, qr/^I caught main .*mem_callback.pl 16 2 !$/m,
	'program printed custom callback output after set_callback');

like($output, qr/^>> \d+ main, .*mem_callback.pl \(20\) used 4 bytes$/m,
	'program printed default trace output after restore_callback');

like($output, qr/hello world/, 'program ran successfully');
