use strict;
use warnings;

use Test::More;

plan tests => 7;

use Config;

my $perlbin;

eval "require Probe::Perl";

unless ($@) {
	$perlbin = Probe::Perl->find_perl_interpreter();
}

$perlbin ||= $Config{perlpath};

my $includes = '-I t/lib/';

# Use custom provider so we control when mem increases
$ENV{MEMORYTRACE_LIGHT} = 'provider=DMTraceProviderNextMem';

# Simplest case
my $output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_simple.pl 2>&1`;

like($output, qr/^>> \d+ main, .*mem_simple.pl \(6\) used 1024 bytes$/m,
	'increase detected');

# Memory growth at end of program
$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_at_end.pl 2>&1`;

like($output, qr/^>> \d+ main, .*mem_at_end.pl \(6\) used 1024 bytes$/m,
	'increase detected');

# By default, compile-time is not traced
$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_at_compile_time.pl 2>&1`;

unlike($output, qr/>> \d+ DBMTraceMemIncAtCompile.*/,
	'compile-time tracing did not happen by default');

like($output, qr/hello world/m, 'program ran successfully');

# Callbacks that leak memory should not skew results
$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_leaky_callback.pl 2>&1`;

like($output, qr/^>> \d+ main, .*mem_leaky_callback.pl \(18\) used 1024 bytes$/m,
	'increase detected');
unlike($output, qr/^>> \d+ main, .*mem_leaky_callback.pl \(20\) used \d+ bytes$/m,
	'leaky callback did not skew results on next line');
like($output, qr/^>> \d+ main, .*mem_leaky_callback.pl \(22\) used 1024 bytes$/m,
	'increase detected with correct ammount');

