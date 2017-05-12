BEGIN {
   # many testers have totally overloaded machines with virtual machines
   # running backwards in time etc. etc.
   if (exists $ENV{AUTOMATED_TESTING}) {
      print "1..0 # Skipped: Too many broken cpan tester setups.\n";
      exit;
   }
}

BEGIN { $| = 1; print "1..752\n"; }

no warnings;
use strict;

use EV;

my $l = new EV::Loop;

my $fudge = 0.02; # allow rt and monotonic clock to disagree by this much

my $id = 1;
my @timer;
my @periodic;

my $base = $l->now;
my $prev = $l->now;

for my $i (1..125) {
   my $t = $i * $i * 1.735435336; $t -= int $t;
   push @timer, $l->timer ($t, 0, sub {
      my $now = $_[0]->loop->now;

      print $now + $fudge >= $prev      ? "" : "not ", "ok ", ++$id, " # t0 $i $now + $fudge >= $prev\n";
      print $now + $fudge >= $base + $t ? "" : "not ", "ok ", ++$id, " # t1 $i $now + $fudge >= $base + $t\n";

      unless ($id % 3) {
         $t *= 0.0625;
         $_[0]->set ($t);
         $_[0]->start;
         $t = $now + $t - $base;
      }

      $prev = $now;
   });

   my $t = $i * $i * 1.375475771; $t -= int $t;
   push @periodic, $l->periodic ($base + $t, 0, 0, sub {
      my $now = $l->now;

      print $now >= $prev      ? "" : "not ", "ok ", ++$id, " # p0 $i $now >= $prev\n";
      print $now >= $base + $t ? "" : "not ", "ok ", ++$id, " # p1 $i $now >= $base + $t\n";

      unless ($id % 3) {
         $t *= 1.0625;
         $_[0]->set ($base + $t);
         $_[0]->start;
      }

      $prev = $now;
   });
}

EV::run;
print "ok 1\n";
$l->loop;
print "ok 752\n";

