#
# Test for commandeering Carp
#

use strict;
use Test::Simple tests => 2;

use Log::Channel;
use Log::Dispatch::File;

######################################################################

close STDERR;
my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

package One;
use Carp;

my $log = new Log::Channel;
sub msg { $log->(@_) }

sub log {
    carp $_[0];
}

######################################################################

package main;

Log::Channel->commandeer("One");
decorate Log::Channel ("One", "%t: %m\n");

One::log("Ouch!");

######################################################################
# Now check the log files

close STDERR;

open (LINES, "<$stderrfile") or die $!;
my @lines = <LINES>;
close LINES;
ok ((scalar grep { /Ouch!/ } @lines) == 1);
ok ((scalar grep { /One:/ } @lines) == 1);

######################################################################
# Clean up

unlink $stderrfile;
