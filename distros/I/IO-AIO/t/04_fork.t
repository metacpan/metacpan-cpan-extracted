#!/usr/bin/perl

BEGIN {
   if ($^O eq "MSWin32") {
      print qq{1..0 # SKIP perl broken beyond repair\n};
      exit 0;
   }
}

use Test;
use IO::AIO;

# this is a lame test, but....

BEGIN { plan tests => 10 }

IO::AIO::min_parallel 2;

IO::AIO::aio_nop sub {
   print "ok 6\n";
};

IO::AIO::aio_busy 1, sub {
   print "ok 8\n";

};

print "ok 1\n";

if (open FH, "-|") {
   print while <FH>;
   aio_stat "/", sub {
      print "ok 7\n";
   };
   print "ok 5\n";
   IO::AIO::poll while IO::AIO::nreqs;
   print "ok 9\n";
} else {
   IO::AIO::reinit;
   print "ok 2\n";
   aio_stat "/", sub {
      print "ok 3\n";
   };
   IO::AIO::poll while IO::AIO::nreqs;
   print "ok 4\n";
   exit;
}

print "ok 10\n";

