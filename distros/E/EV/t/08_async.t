BEGIN { $| = 1; print "1..13\n"; }

no warnings;
use strict;

use EV;

 {
   my ($a1, $a2, $a3);

   $a3 = EV::async sub {
      print "not ok 1\n";
   };
   $a2 = EV::async sub {
      print "ok 5\n";
      $a1->cb (sub {
         print "ok 6\n";
         EV::break;
      });
      $a1->send;
   };
   $a1 = EV::async sub {
      print $a1->async_pending ? "not " : "", "ok 4\n";
      $a2->send;
   };

   print $a1->async_pending ? "not " : "", "ok 1\n";
   $a1->send;
   print $a1->async_pending ? "" : "not ", "ok 2\n";
   $a1->send;
   $a1->send;
   print "ok 3\n";
   EV::run;
   print "ok 7\n";
}

{
   my $l = new EV::Loop;
   my ($a1, $a2, $a3);

   $a3 = $l->async (sub {
      print "not ok 8\n";
   });
   $a2 = $l->async (sub {
      print "ok 11\n";
      $a1->cb (sub {
         print "ok 12\n";
         $l->break;
      });
      $a1->send;
   });
   $a1 = $l->async (sub {
      print "ok 10\n";
      $a2->send;
   });

   print "ok 8\n";
   $a1->send;
   $a1->send;
   $a1->send;
   print "ok 9\n";
   $l->run;
   print "ok 13\n";
}

