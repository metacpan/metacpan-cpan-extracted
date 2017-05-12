BEGIN {
   if (exists $ENV{AUTOMATED_TESTING}) {
      print "1..0 # Skipped: Too many broken cpan tester setups.\n";
      exit;
   }
}

BEGIN { $| = 1; print "1..30\n"; }

no warnings;
use strict;
use Socket;

use EV;

for my $it ("", 1, 2) {
   for my $i (3..5) {
      EV::once undef, 0, ($i - 3) * 0.1 + 0.2, sub {
         print $_[0] == EV::TIMER ? "" : "not ", "ok $it$i\n";
      };
   }

   socketpair my $s1, my $s2, AF_UNIX, SOCK_STREAM, PF_UNSPEC;

   EV::once $s1, EV::WRITE, 0.1, sub {
      print $_[0] & EV::WRITE ? "" : "not ", "ok ${it}2\n";
   };

   print "ok ${it}1\n";
   EV::run;
   print "ok ${it}6\n";
   EV::signal INT => sub { };
   print "ok ${it}7\n";
   EV::async sub { };
   print "ok ${it}8\n";
   EV::default_destroy;
   print "ok ${it}9\n";
   EV::default_loop;
   print "ok ", ${it}*10 + 10, "\n";
}

