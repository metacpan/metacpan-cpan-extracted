#
# Test for default stderr logging only
#

use strict;
use Test::Simple tests => 4;

use Log::Channel;

my $log = new Log::Channel "main";
sub msg { $log->(@_) }

######################################################################
# redirect stderr so we can scan and validate the output

close STDERR;

my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

msg "message 1";		# should go to stderr

disable Log::Channel "main";

msg "message 2";		# should not go anywhere

enable Log::Channel "main";

msg "message 3";		# should go to stderr

disable Log::Channel "main";

msg "message 4";		# should not go anywhere

######################################################################
# Now check the log files

close STDERR;

open (LINES, "<$stderrfile") or die $!;
my @lines = <LINES>;
close LINES;
ok ((scalar grep { /message 1/ } @lines) == 1);
ok ((scalar grep { /message 2/ } @lines) == 0);
ok ((scalar grep { /message 3/ } @lines) == 1);
ok ((scalar grep { /message 4/ } @lines) == 0);

######################################################################
# Clean up

unlink $stderrfile;
