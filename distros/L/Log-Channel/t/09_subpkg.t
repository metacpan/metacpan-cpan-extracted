#
# Test for default stderr logging in multiple packages
#

use strict;
use Test::Simple tests => 14;

use Log::Channel;

decorate Log::Channel "One::Subone", "%t: %m\n";

######################################################################
# redirect stderr so we can scan and validate the output

close STDERR;

my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

package One;

my $log = new Log::Channel;
sub msg { $log->(@_) }

sub log (@) {
    msg @_;
}

######################################################################

package One::Subone;

my $log11 = new Log::Channel;
sub msg { $log11->(@_) }

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

One::log "message 01\n";	# should go to stderr
Two::log "message 2\n";		# should go to stderr

disable Log::Channel "One";

One::log "message 3\n";		# no
One::Subone::log "message 11";	# no
Two::log "message 4\n";		# yes

enable Log::Channel "One::Subone";

One::log "message 12\n";	# no
One::Subone::log "message 13";	# yes

disable Log::Channel "Two";

One::log "message 5\n";		# no
Two::log "message 6\n";		# no

enable Log::Channel "One";

One::log "message 7\n";		# yes
Two::log "message 8\n";		# no

enable Log::Channel "Two";

One::log "message 9\n";		# yes
Two::log "message 10\n";	# yes

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
ok ((scalar grep { /message 13/ } @lines) == 1);

ok ((scalar grep { /One::Subone:/ } @lines) == 1);

######################################################################
# Clean up

unlink $stderrfile;
