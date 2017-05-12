#!perl -w
#______________________________________________________________________
# Solve quadratic equation.
# Mike Schilli, m@perlmeister.com, 2004
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests => 12;

 {my ($t)     = symbols(qw(t));
  my $rabbit  = 10 + 5 * $t;
  my $fox     = 7 * $t * $t;
  my ($a, $b) = @{($rabbit - $fox)->solve("t")};

  print "$a\n$b\n";

  ok("$a" eq  "1/14*sqrt(305)+5/14");
  ok("$b" eq "-1/14*sqrt(305)+5/14");
 }

#______________________________________________________________________
# Solve quadratic equation.
# PhilipRBrenan@yahoo.com, 2004
#______________________________________________________________________

$c = << 'END';
#______________________________________________________________________
# As per Mike, but with **2 and no final eval to show symbolic results.
# ($rabbit eq $fox)->solve("t")
#______________________________________________________________________
END

 {my ($t)     = symbols(qw(t));
  my $rabbit  = 10 + 5 * $t;
  my $fox     = 7 * $t ** 2;

  my ($a, $b) = @{($rabbit eq $fox)->solve("t")};

  print "\n$c\n$a\n$b\n";

  ok("$a" eq  "1/14*sqrt(305)+5/14");
  ok("$b" eq "-1/14*sqrt(305)+5/14");

$c = << 'END';
#______________________________________________________________________
# With $a->solve($b) as a synonym for $a->solve("b")
# ($rabbit eq $fox)->solve($t)
#______________________________________________________________________
END

  ($a, $b) = @{($rabbit eq $fox)->solve("t")};

  print "\n$c\n$a\n$b\n";

  ok("$a" eq  "1/14*sqrt(305)+5/14");
  ok("$b" eq "-1/14*sqrt(305)+5/14");

$c = << 'END';
#______________________________________________________________________
# With $a > "b" as a synonym for $a->solve("b")
# $rabbit eq $fox > "t"
#______________________________________________________________________
END

  ($a, $b) = @{($rabbit eq $fox) > "t"};

  print "\n$c\n$a\n$b\n";

  ok("$a" eq  "1/14*sqrt(305)+5/14");
  ok("$b" eq "-1/14*sqrt(305)+5/14");

$c = << 'END';
#______________________________________________________________________
# With $a > $b as a synonym for $a->solve($t)
# $rabbit eq $fox > $t
# Requires version 1.17
#______________________________________________________________________
END

  ($a, $b) = @{($rabbit eq $fox) > $t};

  print "\n$c\n$a\n$b\n";

  ok("$a" eq  "1/14*sqrt(305)+5/14");
  ok("$b" eq "-1/14*sqrt(305)+5/14");
 }

$c = << 'END';
#______________________________________________________________________
# In terms of variables:
#   rabbit  = rd + rv * t;
#   fox     = fa * t ** 2;
#
#  (rabbit - fox)->solve(qw(t in terms of rd rv fa));
# The resulting equation can then be reused many times.
#______________________________________________________________________
END

 {my ($t, $rd, $rv, $fa) = symbols(qw(t rd rv fa));

  my $rabbit  = $rd + $rv * $t;
  my $fox     = $fa * $t ** 2;

  my ($a, $b) = @{($rabbit eq $fox) > [qw(t in terms of rd rv fa)]};

  print "\n$c\n$a\n$b\n";
  ok($a ==  1/2/$fa*sqrt(4*$fa*$rd+$rv**2)+1/2*$rv/$fa);                        # 2016/01/20 15:40:18 Different ordering of expressions makes string comparison unviable
  ok($b ==  -1/2/$fa*sqrt(4*$fa*$rd+$rv**2)+1/2*$rv/$fa);
#  ok("$a" eq  '1/2/$fa*sqrt(4*$fa*$rd+$rv**2)+1/2*$rv/$fa');
#  ok("$b" eq '-1/2/$fa*sqrt(4*$fa*$rd+$rv**2)+1/2*$rv/$fa');
 }
