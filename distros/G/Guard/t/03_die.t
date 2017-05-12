BEGIN { $| = 1; print "1..11\n"; }

use Guard;

print "ok 1\n";

$Guard::DIED = sub {
   print $@ =~ /^x1 at / ? "" : "not ", "ok 3 # $@\n";
};

eval {
   scope_guard { die "x1" };
   print "ok 2\n";
};

print $@ ? "not " : "", "ok 4 # $@\n";

$Guard::DIED = sub {
   print $@ =~ /^x2 at / ? "" : "not ", "ok 6 # $@\n";
};

eval {
   scope_guard { die "x2" };
   print "ok 5\n";
   die "x3";
};

print $@ =~ /^x3 at /s ? "" : "not ", "ok 7 # $@\n";

our $x4 = 1;

$SIG{__DIE__} = sub {
   if ($x4) {
      print "not ok 9\n";
   } else {
      print $_[0] =~ /^x5 at / ? "" : "not ", "ok 11 # $_[0]\n";
   }
   exit 0;
};

{
   $Guard::DIED = sub {
      print $@ =~ /^x4 at / ? "" : "not ", "ok 9 # $@\n";
   };

   scope_guard { die "x4" };
   print "ok 8\n";
};

$x4 = 0;
print "ok 10\n";

die "x5";

