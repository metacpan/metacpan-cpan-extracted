BEGIN { $| = 1; print "1..14\n"; }

no warnings;
use strict;

use File::Temp;

use EV;

my $fh = new File::Temp UNLINK => 1;

my $w = EV::stat "$fh", 0.1, sub {
   print "ok 5\n";
   print 1 == $_[0]->prev ? "" : "not ", "ok 6\n";
   print 13 == scalar (() = $_[0]->prev) ? "" : "not ", "ok 7\n";
   print "0" eq -s _ ? "" : "not ", "ok 8\n";
   print 1 == ($_[0]->prev)[3] ? "" : "not ", "ok 9\n";

   print 0 == $_[0]->attr ? "" : "not ", "ok 10\n";
   print 0 == ($_[0]->attr)[3] ? "" : "not ", "ok 11\n";

   print 0 == $_[0]->stat ? "" : "not ", "ok 12\n";
   print 0 == ($_[0]->stat)[3] ? "" : "not ", "ok 13\n";
   EV::break;
};

my $t = EV::timer 0.2, 0, sub {
   print "ok 2\n";
   EV::break;
};

print $w->stat ? "" : "not ", "ok 1\n";
EV::run;
print "ok 3\n";

# delete the file, as windows will not update any stats otherwise :(
undef $fh;

my $t = EV::timer 0.2, 0, sub {
   print "no ok 5\n";
   EV::break;
};

print "ok 4\n";
EV::run;
print "ok 14\n";

