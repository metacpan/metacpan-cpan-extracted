BEGIN { $| = 1; print "1..9\n"; }

no warnings;
use strict;

use EV;

my $t0 = EV::timer -1, 0, sub { print "ok 4\n" };
my $t_ = EV::timer -1, 0, sub { print "ok 5\n" }; $t_->priority (-1);
my $t1 = EV::timer -1, 0, sub { print "ok 3\n" }; $t1->priority ( 1);

my $i2 = EV::idle sub { print EV::iteration == 1 ? "" : "not ", "ok 2\n"; $_[0]->stop }; $i2->priority (10);
my $i0 = EV::idle sub { print EV::iteration == 3 ? "" : "not ", "ok 7\n"; $_[0]->stop };
my $i1 = EV::idle sub { print EV::iteration == 2 ? "" : "not ", "ok 6\n"; $_[0]->stop }; $i1->priority ( 1);
my $i_ = EV::idle sub { print EV::iteration == 4 ? "" : "not ", "ok 8\n"; $_[0]->stop }; $i_->priority (-1);

print "ok 1\n";
EV::run;
print "ok 9\n";
