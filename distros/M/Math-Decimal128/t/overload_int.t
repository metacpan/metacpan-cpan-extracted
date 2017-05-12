use warnings;
use strict;
use Math::Decimal128 qw(:all);

print "1..6\n";

my $inf = InfD128(-1);
my $nan = NaND128();

if(int($inf) == $inf && is_InfD128(int($inf))){print "ok 1\n"}
else {print "not ok 1\n"}

if($nan != int($nan) && is_NaND128(int($nan))) {print "ok 2\n"}
else {print "not ok 2\n"}

my $ok = 1;

for my $size(1 .. 16) {
  for my $prec(0 .. 369) {
    for my $eg(1 .. 4) {
      my $man = rand_x($size);
      $man = '-' . $man if ($eg % 2);
      my $d128 = Math::Decimal128->new($man, $prec);
      if($d128 != int($d128)) {
        warn "\$d128: $d128\nint(\$d128): ", int($d128), "\n";
        $ok = 0;
      }
    }
  }
}

if($ok) {print "ok 3\n"}
else {print "not ok 3\n"}

$ok = 1;

my $z = ZeroD128(1);

for my $size(1 .. 16) {
  for my $prec(-383 .. -$size) {
    for my $eg(1 .. 4) {
      my $man = rand_x($size);
      if($man =~ /^\-/) {$man =~ s/\-//}
      else {$man = '-' . $man}
      my $d128 = Math::Decimal128->new($man, $prec);
      if($z != int($d128)) {
        warn "\$d128: $d128\nint(\$d128): ", int($d128), "\n";
        $ok = 0;
      }
    }
  }
}

if($ok) {print "ok 4\n"}
else {print "not ok 4\n"}

$ok = 1;

my $man = '1234567890123456';
my $exp = 0;

my $d128 = MEtoD128($man, $exp);
my $div = MEtoD128(-10,0);

for my $s(1 .. 16) {
  $d128 /= $div;
  chop $man;
  $man = '0' if (!$man || $man eq '-');
  if($man =~ /^\-/) {$man =~ s/\-//}
  else {$man = '-' . $man}
  if(int($d128) != MEtoD128($man, 0)) {
    $ok = 0;
    warn "int(\$d128): ", int($d128), "\nMEtoD128(\$man, 0): ", MEtoD128($man, 0), "\n";
  }
}

if($ok) {print "ok 5\n"}
else {print "not ok 5\n"}

if($d128 != MEtoD128('1234567890123456', -16) || $man != 0) {
  warn "\$d128: $d128\n\$man: $man\n";
  print "not ok 6\n";
}
else {print "ok 6\n"}


sub rand_x {
    if($_[0] > 16 || $_[0] < 0) {die "rand_x() given bad value"}
    my $ret;
    for(1 ..$_[0]) {$ret .= int(rand(10))}
    return $ret;
}


