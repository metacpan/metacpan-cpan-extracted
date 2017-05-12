BEGIN { $| = 1; print "1..10\n"; }

use Guard;

print "ok 1\n";

our $global = 0;

{
   scope_guard {
      print "ok 3\n"
   };
   local $global = 1;
   print "ok 2\n";
}

print "ok 4\n";

{
   scope_guard { print "ok 6\n" };
   print "ok 5\n";
   last;
}

print "ok 7\n";

{
   scope_guard { print "ok 9\n" };
   print "ok 8\n";
   exit;
}

END {
   print "ok 10\n";
}
