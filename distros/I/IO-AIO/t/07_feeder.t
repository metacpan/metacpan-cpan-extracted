#!/usr/bin/perl

use IO::AIO;

print "1..6\n";

my $grp = aio_group sub {
   print "ok 4\n";#d#
};

my $cn1 = 10;
my $cn2 = 0;
my $cn3 = 0;

print "ok 1\n";

limit $grp 5;
$grp->feed (sub {
   return if $cn2 >= 10;
   $cn2++;
   aioreq_pri $cn2;
   (add $grp IO::AIO::aio_busy 0)->cb (sub {
      $cn3++;
   });
});

print $cn2 == 5 ? "" : "not ", "ok 2 # $cn2 == 5\n";
print $cn3 == 0 ? "" : "not ", "ok 3 # $cn3 == 0\n";

IO::AIO::poll while IO::AIO::nreqs;

print $cn2 == 10 ? "" : "not ", "ok 5 # $cn2 == 10\n";
print $cn3 == 10 ? "" : "not ", "ok 6 # $cn2 == 10\n";

