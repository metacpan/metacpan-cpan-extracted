BEGIN {
   if (exists $ENV{AUTOMATED_TESTING}) {
      print "1..0 # Skipped: Too many broken cpan tester setups.\n";
      exit;
   }
}

BEGIN { $| = 1; print "1..8\n"; }

no warnings;
use strict;

use EV;

my $timer = EV::timer_ns 1, 0.3, sub { print "ok 7\n"; $_[0]->stop };

$timer->keepalive (1);

print "ok 1\n";
EV::run;
print "ok 2\n";

$timer->start;

$timer->keepalive (0);

$timer->again;
$timer->stop;
$timer->start;

my $timer2 = EV::timer -1, 0, sub { print "ok 4\n" };
$timer2->keepalive (0);

print "ok 3\n";
EV::run;
print "ok 5\n";

$timer->keepalive (1);

print "ok 6\n";
EV::run;
print "ok 8\n";

