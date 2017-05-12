use strict;
use warnings;
use IO::CaptureOutput qw/capture/;

my ($stdout, $stderr);

capture sub {
    print "This prints to STDOUT\n";
    print STDERR "This prints to STDERR\n";
} => \$stdout, \$stderr;

print "STDOUT was:\n$stdout\n";

print "STDERR was:\n$stderr\n";

