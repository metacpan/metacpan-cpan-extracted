use strict;
use warnings;

use Test::More;

plan tests => 2;

use Config;

my $perlbin;

eval "require Probe::Perl";

unless ($@) {
	$perlbin = Probe::Perl->find_perl_interpreter();
}

$perlbin ||= $Config{perlpath};

# Make sure we really can detect memory changes

# Simplest case
my $output = `$perlbin -d:MemoryTrace::Light t/bin/mem_real.pl 2>&1`;

like($output, qr/^>> \d+ main, .*mem_real.pl \(8\) used \d+ bytes$/m,
	'increase detected');

like($output, qr/Hello world/m, 'program ran successfully');
