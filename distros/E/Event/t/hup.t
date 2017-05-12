#!./perl -w

BEGIN {
    if ($^O eq 'MSWin32') {
	print "1..0 # skipped; Win32 is too strange\n";
	exit;
    }
}

# contributed by Gisle Aas <aas@gaustad.sys.sol.no>

use Test; plan test => 1;
use Event qw(loop unloop);

$| = 1;
my $pid = open(PIPE, "-|");
die unless defined $pid;
unless ($pid) {
    # child
    for (1..100) { print "."; }
    print "\n";
    exit;
}

my $bytes = 0;
Event->io(poll => "r",
          fd   => \*PIPE,
          cb   => sub {
             my $e = shift;
	     my $buf;
             my $n = sysread(PIPE, $buf, 10);
             $bytes += $n;
             #print "Got $n bytes\n";
             unloop() unless $n;
          });

loop();

ok $bytes, 101;
