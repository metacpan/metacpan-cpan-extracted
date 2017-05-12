#!perl

use strict;
use warnings;

use Test::More tests => 2;

use Log::Dynamic;

my $file = 'test.log';
my $log  = Log::Dynamic->open(
	file  => $file,
	mode  => 'clobber',
	ucase => 1,
);

$log->Test_1('Type should be forced to uppercase');
$log->ucase(0);
$log->Test_2('Type should have case maintained');
$log->close;

# Read our log to see if it contains both the old
# and the new entries.
open my $fh, '<', $file or die "$0: $!\n";
my ($line1, $line2) = <$fh>;
close $fh;

like($line1, qr/.*\[TEST\_1\].*/, 'Verify ucase true');
like($line2, qr/.*\[Test\_2\].*/, 'Verify ucase false');

unlink $file;

__END__
vim:set syntax=perl:
