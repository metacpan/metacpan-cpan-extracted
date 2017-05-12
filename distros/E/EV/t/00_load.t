BEGIN { $| = 1; print "1..5\n"; }

BEGIN {
   $^W = 0; # work around some bugs in perl

   print eval { require EV            } ? "" : "not ", "ok 1 # $@\n";
   print eval { require EV::MakeMaker } ? "" : "not ", "ok 2 # $@\n";
}

my $w = EV::idle sub { print "not ok 3\n"; $_[0]->stop };
$w->feed_event (EV::CUSTOM);
$w->stop;
EV::run;
print "ok 3\n";

my $w = EV::idle sub { print "ok 4\n"; $_[0]->stop };
$w->feed_event (EV::CUSTOM);
$w->clear_pending;
EV::loop;
print "ok 5\n";
