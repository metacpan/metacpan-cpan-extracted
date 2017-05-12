#
# Test for dispatcher behavior
#

use strict;
use Test::Simple tests => 5;

use Log::Channel;

######################################################################

close STDERR;
my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

my $log = new Log::Channel "main";
sub msg { $log->(@_) }

decorate Log::Channel "main", "%t %d: %m\n";

msg "message 1";

decorate Log::Channel "main", "%F (%L): %m\n";

msg "message 2";

decorate Log::Channel "main", "%d{%y%m%d %H%M%S}: %m\n";

msg "message 3";

Log::Channel->set_priority ("main", "warn");
decorate Log::Channel "main", "%p: %m\n";

msg "message 4";

Log::Channel->set_context ("main", "123");
decorate Log::Channel "main", "%t (%x): %m\n";

msg "message 5";

msg "message 6";

######################################################################
# Now check the log files

close STDERR;

open (LINES, "<$stderrfile") or die $!;
my @lines = <LINES>;
close LINES;
ok ((scalar grep { /^main ... ... .. .* \d\d\d\d: message 1/ } @lines) == 1);
ok ((scalar grep { /^t\/.*.t \(27\): message 2/ } @lines) == 1);
ok ((scalar grep { /^\d\d\d\d\d\d \d\d\d\d\d\d: message 3/ } @lines) == 1);
ok ((scalar grep { /^warn: message 4/ } @lines) == 1);
ok ((scalar grep { /^main \(123\): message 5/ } @lines) == 1);

######################################################################
# Clean up

unlink $stderrfile;
