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

# Bad 'provider' (not found)
$ENV{MEMORYTRACE_LIGHT} = 'provider=NoSuChModUleExisTs';

my $output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_simple.pl 2>&1`;

like($output, qr/^Custom provider \(NoSuChModUleExisTs\) failed to load:.*$/m,
	'bad ENV value for provider detected');

unlike($output, qr/^>> \d+ main, .*mem_simple.pl \(\d+\) used \d+ bytes$/m,
	'program died without tracing');

# Bad 'provider' (get_mem() missing)
$ENV{MEMORYTRACE_LIGHT} = 'provider=DMTraceBadProviderNoGetMem';

$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_simple.pl 2>&1`;

like($output, qr/^Custom provider \(DMTraceBadProviderNoGetMem\) failed to load: No get_mem\(\) method found$/m,
	'bad ENV value for provider detected');

unlike($output, qr/^>> \d+ main, .*mem_simple.pl \(\d+\) used \d+ bytes$/m,
	'program died without tracing');

# Bad 'provider' (didn't return an integer)
$ENV{MEMORYTRACE_LIGHT} = 'provider=DMTraceBadProviderGetMemReturnsBadData';

$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_simple.pl 2>&1`;

like($output, qr/^Custom provider \(DMTraceBadProviderGetMemReturnsBadData\) failed to load: get_mem\(\) didn't return an integer$/m,
	'bad ENV value for provider detected');

unlike($output, qr/^>> \d+ main, .*mem_simple.pl \(\d+\) used \d+ bytes$/m,
	'program died without tracing');

# Good provider
$ENV{MEMORYTRACE_LIGHT} = 'provider=DMTraceProviderNextMem';

$output = `$perlbin $includes -d:MemoryTrace::Light t/bin/test_provider.pl 2>&1`;

like($output, qr/^>> \d+ main, .*test_provider.pl \(6\) used 5 bytes$/m, 'correct memory reported');

like($output, qr/^>> \d+ main, .*test_provider.pl \(9\) used 5 bytes$/m, 'correct memory reported in loop');
like($output, qr/^>> \d+ main, .*test_provider.pl \(9\) used 10 bytes$/m, 'correct memory reported in loop');
like($output, qr/^>> \d+ main, .*test_provider.pl \(9\) used 20 bytes$/m, 'correct memory reported in loop');
like($output, qr/^>> \d+ main, .*test_provider.pl \(9\) used 40 bytes$/m, 'correct memory reported in loop');
like($output, qr/^>> \d+ main, .*test_provider.pl \(9\) used 80 bytes$/m, 'correct memory reported in loop');

like($output, qr/hello world/m, 'program ran successfuly');

