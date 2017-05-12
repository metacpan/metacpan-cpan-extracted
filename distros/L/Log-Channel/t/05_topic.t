#
# Test for default stderr logging in multiple packages
#

use strict;
use Test::Simple tests => 12;

use Log::Channel;

######################################################################
# redirect stderr so we can scan and validate the output

close STDERR;

my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

package One;

my $log1 = new Log::Channel "topic1";
sub msg1 { $log1->(@_) }

my $log2 = new Log::Channel "topic2";
sub msg2 { $log2->(@_) }

######################################################################

package main;

One::msg1 "message 01\n";		# should go to stderr
One::msg2 "message 2\n";		# should go to stderr

disable Log::Channel ("One", "topic1");

One::msg1 "message 3\n";		# no
One::msg2 "message 4\n";		# yes

disable Log::Channel ("One", "topic2");

One::msg1 "message 5\n";		# no
One::msg2 "message 6\n";		# no

enable Log::Channel ("One", "topic1");

One::msg1 "message 7\n";		# yes
One::msg2 "message 8\n";		# no

enable Log::Channel ("One", "topic2");

One::msg1 "message 9\n";		# yes
One::msg2 "message 10\n";		# yes

disable Log::Channel "One";

One::msg1 "message 11\n";		# no
One::msg2 "message 12\n";		# no

######################################################################
# Now check the log files

close STDERR;

open (LINES, "<$stderrfile") or die $!;
my @lines = <LINES>;
close LINES;
ok ((scalar grep { /message 01/ } @lines) == 1);
ok ((scalar grep { /message 2/ } @lines) == 1);
ok ((scalar grep { /message 3/ } @lines) == 0);
ok ((scalar grep { /message 4/ } @lines) == 1);
ok ((scalar grep { /message 5/ } @lines) == 0);
ok ((scalar grep { /message 6/ } @lines) == 0);
ok ((scalar grep { /message 7/ } @lines) == 1);
ok ((scalar grep { /message 8/ } @lines) == 0);
ok ((scalar grep { /message 9/ } @lines) == 1);
ok ((scalar grep { /message 10/ } @lines) == 1);
ok ((scalar grep { /message 11/ } @lines) == 0);
ok ((scalar grep { /message 12/ } @lines) == 0);

######################################################################
# Clean up

unlink $stderrfile;
