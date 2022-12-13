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
	system $EXECUTABLE_NAME, realpath(catfile($Bin, '..', 'data', 'ex1.pl'));
} => \$stdout, \$stderr;
is($stdout, '', 'Error in standalone script - stdout.');
is($stderr, "Error.\n", 'Error in standalone script - stderr.');

# Test.
($stdout, $stderr) = ('', '');
capture sub {
	system $EXECUTABLE_NAME, realpath(catfile($Bin, '..', 'data', 'ex2.pl'));
} => \$stdout, \$stderr;
is($stdout, '', 'Error with parameter and value in standalone script - stdout.');
is($stderr, "Error.\n", 'Error with parameter and value in standalone script - stderr.');
