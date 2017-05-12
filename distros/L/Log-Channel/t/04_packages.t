#
# Test for default stderr logging in multiple packages
#

use strict;
use Test::Simple tests => 10;

use Log::Channel;

######################################################################
# redirect stderr so we can scan and validate the output

close STDERR;

my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

package One;

my $log1 = new Log::Channel;
sub msg { $log1->(@_) }

sub log (@) {
    msg @_;
}

######################################################################

package Two;

my $log2 = new Log::Channel;
sub msg { $log2->(@_) }

sub log (@) {
    msg @_;
}

######################################################################

package main;

One::log "message 01";		# should go to stderr
Two::log "message 2";		# should go to stderr

disable Log::Channel "One";

One::log "message 3";		# no
Two::log "message 4";		# yes

disable Log::Channel "Two";

One::log "message 5";		# no
Two::log "message 6";		# no

enable Log::Channel "One";

One::log "message 7";		# yes
Two::log "message 8";		# no

enable Log::Channel "Two";

One::log "message 9";		# yes
Two::log "message 10";		# yes

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

######################################################################
# Clean up

unlink $stderrfile;
