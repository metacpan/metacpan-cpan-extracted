BEGIN { $| = 1; print "1..11\n"; }

use Guard;

print "ok 1\n";

{
   my $guard = guard { print "ok 3\n" };
   print "ok 2\n";
}

print "ok 4\n";

{
   my $guard = guard { print "not ok 6\n" };
   print "ok 5\n";
   $guard->cancel;
}

print "ok 6\n";

{
   my $guard = guard { print "ok 9\n" };
   my $guard2 = $guard;
   print "ok 7\n";
   undef $guard;
   print "ok 8\n";
   undef $guard2;
   print "ok 10\n";
}

print "ok 11\n";

