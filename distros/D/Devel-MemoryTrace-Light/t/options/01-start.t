use strict;
use warnings;

use Test::More;

plan tests => 6;

use Config;

my $perlbin;

eval "require Probe::Perl";

unless ($@) {
	$perlbin = Probe::Perl->find_perl_interpreter();
}

$perlbin ||= $Config{perlpath};

my $includes = '-I t/lib/';

# Need custom provider
my $p_arg = 'provider=DMTraceProviderNextMem:';

# Bad 'start'
$ENV{MEMORYTRACE_LIGHT} = "${p_arg}start=fake";

my $output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_simple.pl 2>&1`;

like($output, qr/^Ignoring unknown value \(fake\) for 'start'\n/m,
	'bad ENV value for start detected');

like($output, qr/^>> \d+ main, .*mem_simple.pl \(6\) used 1024 bytes$/m,
	'program still traced; increase detected');

# Good 'start' = 'no'
$ENV{MEMORYTRACE_LIGHT} = "${p_arg}start=no";

$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_simple.pl 2>&1`;

unlike($output, qr/^>> \d+ main, .*mem_simple.pl \(\d+\) used \d+ bytes$/m,
	'program not traced with start=no');

like($output, qr/hello world/m, 'program ran successfuly');

# Good 'start' = 'begin'
$ENV{MEMORYTRACE_LIGHT} = "${p_arg}start=begin";

$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_at_compile_time.pl 2>&1`;

like($output, qr/^>> \d+ DMTraceMemIncAtCompile, .*DMTraceMemIncAtCompile.pm \(10\) used 4096 bytes$/m,
	'program traced at compile-time with start=begin');

like($output, qr/hello world/m, 'program ran successfuly');
