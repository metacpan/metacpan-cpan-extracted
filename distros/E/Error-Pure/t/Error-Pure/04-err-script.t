use strict;
use warnings;

use Cwd qw(realpath);
use English;
use File::Spec::Functions qw(catfile);
use FindBin qw($Bin);
use IO::CaptureOutput qw(capture);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my ($stdout, $stderr);
capture sub {
	system $EXECUTABLE_NAME, realpath(catfile($Bin, '..', 'data', 'ex5.pl'));
} => \$stdout, \$stderr;
is($stdout, '', 'Error in standalone script - stdout.');
like($stderr, qr{^Error\.\s+at\s+.*\s+line\s+14\.$},
	'Error in standalone script - stderr.');

# Test.
($stdout, $stderr) = ('', '');
capture sub {
	system $EXECUTABLE_NAME, realpath(catfile($Bin, '..', 'data', 'ex6.pl'));
} => \$stdout, \$stderr;
is($stdout, '', 'Error with parameter and value in standalone script - stdout.');
like($stderr, qr{^Error\.ParameterValue\s+at\s+.*\s+line\s+14\.$},
	'Error with parameter and value in standalone script (tests issue in Error::Pure < 0.28) - stderr.');
