#
# Test for dispatcher behavior
#

use strict;
use Test::Simple tests => 3;

use Log::Channel;
use Log::Dispatch::File;

######################################################################

close STDERR;
my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

my $log = new Log::Channel "same";

my $log2 = new Log::Channel "same";

ok($log == $log2);

$log->("message 1");
$log2->("message ", 2);

######################################################################
# Now check the log files

close STDERR;

open (LINES, "<$stderrfile") or die $!;
my @lines = <LINES>;
close LINES;
ok ((scalar grep { /message 1/ } @lines) == 1);
ok ((scalar grep { /message 2/ } @lines) == 1);

######################################################################
# Clean up

unlink $stderrfile;
