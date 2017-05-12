

use strict;
use Test::Simple tests => 4;

use Log::Channel;

close STDERR;
my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

package p1::b;

use strict;
use Carp;

sub new {
    print "new p1b\n";
}

sub complain {
    carp "p1b says yeeow!";
}

######################################################################

package p1;

use strict;
use Carp;

#use p1b;

sub new {
    print "new p1\n";
}

sub complain {
    carp "p1 sez waaah!";
    p1::b::complain;
}

######################################################################

package p2;

use strict;
use Carp;

sub new {
    print "new p2\n";
}

sub complain {
    carp "p2 sez yarg!";
}

######################################################################

package main;

enable Log::Channel "p1";
enable Log::Channel "p2";

Log::Channel::commandeer("p1", "p2");

p1::complain;
p2::complain;

close STDERR;

open (LINES, "<$stderrfile") or die $!;
my @lines = <LINES>;
close LINES;
print STDERR "x";
ok ((scalar @lines == 3), 'line count');
ok ((scalar grep { "waaah!" } @lines == 1), 'p1 complain');
ok ((scalar grep { "yeeow!" } @lines == 1), 'p1b complain');
print STDERR "x";
ok ((scalar grep { "yarg!" } @lines == 1), 'p2 complain');

print STDERR "x";
unlink $stderrfile;
print STDERR "x";
