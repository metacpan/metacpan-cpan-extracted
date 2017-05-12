use strict;
use warnings;

use Test::More;

plan tests => 11;

use Config;

my $perlbin;

eval "require Probe::Perl";

unless ($@) {
	$perlbin = Probe::Perl->find_perl_interpreter();
}

$perlbin ||= $Config{perlpath};

my $includes = '-I t/lib/';

# Use custom provider so we control when mem increases
$ENV{MEMORYTRACE_LIGHT} = 'provider=DMTraceProviderFork';

# Simplest case
my $output = `$perlbin $includes -d:MemoryTrace::Light t/bin/mem_fork.pl 2>&1`;

like($output, qr/^>> \d+ main, .*mem_fork.pl \(8\) used 1024 bytes$/m,
	'increase detected');

like($output, qr/hello world/m, 'program ran successfully');

my ($parent) = $output =~ /^Parent pid: (\d+)$/m;
ok($parent, 'Got parent pid');

my ($child) = $output =~ /^Child pid: (\d+)$/m;
ok($child, 'Got child pid');

my ($forked) = $output =~ /^Forked main: (\d+)$/m;
is($forked, 0, "Provider's forked() method not called yet");

($forked) = $output =~ /^Forked parent: (\d+)$/m;
is($forked, 0, "Provider's forked() method not called after fork() in parent");

($forked) = $output =~ /^Forked child: (\d+)$/m;
is($forked, 1, "Provider's forked() method called after fork() in child");

like($output, qr/^>> $parent main, .*mem_fork.pl \(17\) used 100 bytes$/m,
	'increase reported correctly in parent');

unlike($output, qr/^>> $child main, .*mem_fork.pl \(17\) used 100 bytes$/m,
	'increase in parent not reported by child');

like($output, qr/^>> $child main, .*mem_fork.pl \(23\) used 50 bytes$/m,
	'increase reported correctly in child');

unlike($output, qr/^>> $parent main, .*mem_fork.pl \(23\) used 50 bytes$/m,
	'increase in child not reported by parent');


