#
# Test for dispatcher behavior
#

use strict;
use Test::Simple tests => 12;

use Log::Channel;
use Log::Dispatch::File;

close STDERR;

my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

my $log1 = new Log::Channel "main";
sub msg1 { $log1->(@_) }

decorate Log::Channel "main", "%t %d: %m\n";

######################################################################

my $filename = "/tmp/logchan$$.log";
my $file = Log::Dispatch::File->new( name      => 'file1',
				     min_level => 'info',
				     filename  => $filename,
				     mode      => 'append' );

######################################################################

msg1 "message 1";		# should go to stderr

disable Log::Channel "main";

msg1 "message 2";		# should not go anywhere

enable Log::Channel "main";

msg1 "message 3";		# should go to stderr

dispatch Log::Channel "main", $file;

msg1 "message 4";		# should go to the log file but not stderr

disable Log::Channel "main";

msg1 "message 5";		# should not go anywhere

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
ok ((scalar grep { /message 5/ } @lines) == 0);
ok ((scalar grep { /^main / } @lines) == 2);

open (LINES, "<$filename") or die $!;
@lines = <LINES>;
close LINES;
ok ((scalar grep { /message 1/ } @lines) == 0);
ok ((scalar grep { /message 2/ } @lines) == 0);
ok ((scalar grep { /message 3/ } @lines) == 0);
ok ((scalar grep { /message 4/ } @lines) == 1);
ok ((scalar grep { /message 5/ } @lines) == 0);
ok ((scalar grep { /^main / } @lines) == 1);

######################################################################
# Clean up

unlink $stderrfile;
unlink $filename;
