use warnings;
use strict;
use Math::Decimal128 qw(:all);

print "1..11\n";

my $check2 = Math::Decimal128->new(10, 0);
my $add    = Math::Decimal128->new(1, -2);

my $ok = 1;

for(0..99) {
   $check2 += $add;
   my $check3 = Math::Decimal128->new(1001 + $_, -2);
   if($check2 != $check3) {
     warn "\$check2: $check2 \$check3: $check3\n";
     $ok = 0;
   }
}

if($ok) {print "ok 1\n"}
else {print "not ok 1\n"}

my $d128_1 = Math::Decimal128->new(1123, -17);
my ($man, $exp) = D128toME($d128_1);
if($man eq '1123' && $exp == -17) {print "ok 2\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 2\n";
}

my $nan = NaND128();
($man, $exp) = D128toME($nan);
if(($man != $man || $man =~ /nan/i) && $exp == 0) {print "ok 3\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 3\n";
}

my $inf = InfD128(-1);
($man, $exp) = D128toME($inf);

if(($inf / $inf) != ($inf /$inf) && $exp == 0) {print "ok 4\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 4\n";
}

if(($man =~ /inf/i || ($man / $man) != ($man /$man)) && $exp == 0) {print "ok 5\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 5\n";
}

$ok = 1;

for my $prec(0 .. 382) { # Exponents >382 with 3-digit (integer) significands
                         # are out of bounds for MEtoD128().
  for my $eg(1 .. 10) {
    my $man = int(rand(500));
    if($eg % 2) {$man = '-' . $man}
    my $d128_1 = Math::Decimal128->new($man, $prec); # calls MEtoD128()
    my ($m, $p) = D128toME($d128_1);
    my $d128_2 = Math::Decimal128->new($m, $p);
    if($d128_1 != $d128_2) {
      $ok = 0;
      warn "\n\$man: $man\n\$prec: $prec\n\$m: $m\n";
      defined($p) ? warn "\$p: $p\n"
                  : warn "\$p: undef\n";
    }
  }
}

if($ok) {print "ok 6\n"}
else {print "not ok 6\n"}

$ok = 1;

for my $prec(0 .. 383) {
  for my $eg(1 .. 10) {
    my $man = int(rand(500));
    if($eg % 2) {$man = '-' . $man}
    my $d128_1 = Math::Decimal128->new($man, -$prec);
    my ($m, $p) = D128toME($d128_1);
    my $d128_2 = Math::Decimal128->new($m, $p);
    if($d128_1 != $d128_2) {
      $ok = 0;
      warn "\n\$man: $man\n\$prec: -$prec\n\$m: $m\n";
      defined($p) ? warn "\$p: $p\n"
                  : warn "\$p: undef\n";
    }
  }
}

if($ok) {print "ok 7\n"}
else {print "not ok 7\n"}

$ok = 1;

for my $size(1 .. 16) {
  for my $prec(0 .. 369) {
    for my $eg(1 .. 10) {
      my $man = rand_x($size);
      $man = '-' . $man if ($eg % 2);
      my $d128_1 = Math::Decimal128->new($man, $prec);
      my ($m, $p) = D128toME($d128_1);
      my $d128_2 = Math::Decimal128->new($m, $p);
      if($d128_1 != $d128_2) {
        $ok = 0;
        warn "\n\$man: $man\n\$prec: $prec\n\$m: $m\n";
        defined($p) ? warn "\$p: $p\n"
                    : warn "\$p: undef\n";
      }
    }
  }
}

if($ok) {print "ok 8\n"}
else {print "not ok 8\n"}

$ok = 1;

for my $size(1 .. 16) {
  for my $prec(0 .. 398) {
    for my $eg(1 .. 10) {
      my $man = rand_x($size);
      $man = '-' . $man if ($eg % 2);
      my $d128_1 = Math::Decimal128->new($man, -$prec);
      my ($m, $p) = D128toME($d128_1);
      my $d128_2 = Math::Decimal128->new($m, $p);
      if($d128_1 != $d128_2) {
        $ok = 0;
        warn "\n\$man: $man\n\$prec: -$prec\n\$m: $m\n";
        defined($p) ? warn "\$p: $p\n"
                    : warn "\$p: undef\n";
      }
    }
  }
}

if($ok) {print "ok 9\n"}
else {print "not ok 9\n"}

$ok = 1;

$d128_1 = Math::Decimal128->new('8069610750070607', 1);
($man, $exp) = D128toME($d128_1);
if($man eq '8069610750070607' && $exp == 1) {print "ok 10\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 10\n";
}

# Fails on my powerpc box - a bug in the compiler/libc print formatting (sprintf).
$d128_1 = Math::Decimal128->new('897', -292);
($man, $exp) = D128toME($d128_1);
if($man eq '897' && $exp == -292) {print "ok 11\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 11\n";
}


sub rand_x {
    if($_[0] > 16 || $_[0] < 0) {die "rand_x() given bad value"}
    my $ret;
    for(1 ..$_[0]) {$ret .= int(rand(10))}
    return $ret;
}


