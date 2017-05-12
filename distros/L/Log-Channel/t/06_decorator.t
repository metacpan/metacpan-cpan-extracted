#
# Test for dispatcher behavior
#

use strict;
use Test::Simple tests => 4;

use Log::Channel;
use Log::Dispatch::File;

my $log = new Log::Channel "main";
sub msg { $log->(@_) }

decorate Log::Channel "main", "%t %d: %m\n";

######################################################################

close STDERR;
my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

enable Log::Channel "main";

msg "message 1";

msg "message 2";

msg "message 3";

######################################################################
# Now check the log files

close STDERR;

open (LINES, "<$stderrfile") or die $!;
my @lines = <LINES>;
close LINES;
ok ((scalar grep { /message 1/ } @lines) == 1);
ok ((scalar grep { /message 2/ } @lines) == 1);
ok ((scalar grep { /message 3/ } @lines) == 1);
ok ((scalar grep { /main / } @lines) == 3);

######################################################################
# Clean up

unlink $stderrfile;
