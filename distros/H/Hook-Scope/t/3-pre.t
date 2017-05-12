

use strict;
use Hook::Scope qw(PRE);
print "1..5\n";
sub ok {
  print "ok $_[0]\n";
}

{
  my $foo;
  ok($foo);
  PRE { ok(1);$foo = 2 };
  {
    ok(4);
    PRE { ok(3) };
  }
  ok(5);
}



