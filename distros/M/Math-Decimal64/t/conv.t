use warnings;
use strict;
use Math::Decimal64 qw(:all);

print "1..14\n";

my $check2 = Math::Decimal64->new(10, 0);
my $add    = Math::Decimal64->new(1, -2);

my $ok = 1;

for(0..99) {
   $check2 += $add;
   my $check3 = Math::Decimal64->new(1001 + $_, -2);
   if($check2 != $check3) {
     warn "\$check2: $check2 \$check3: $check3\n";
     $ok = 0;
   }
}

if($ok) {print "ok 1\n"}
else {print "not ok 1\n"}

my $d64_1 = Math::Decimal64->new(1123, -17);
my ($man, $exp) = D64toME($d64_1);
if($man eq '1123' && $exp == -17) {print "ok 2\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 2\n";
}

my $nan = NaND64();
($man, $exp) = D64toME($nan);
if(($man != $man || $man =~ /nan/i) && $exp == 0) {print "ok 3\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 3\n";
}

my $inf = InfD64(-1);
($man, $exp) = D64toME($inf);
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
                         # are out of bounds for MEtoD64().
  for my $eg(1 .. 10) {
    my $man = int(rand(500));
    if($eg % 2) {$man = '-' . $man}
    my $d64_1 = Math::Decimal64->new($man, $prec); # calls MEtoD64()
    my ($m, $p) = D64toME($d64_1);
    my $d64_2 = Math::Decimal64->new($m, $p);
    if($d64_1 != $d64_2) {
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
    my $d64_1 = Math::Decimal64->new($man, -$prec);
    my ($m, $p) = D64toME($d64_1);
    my $d64_2 = Math::Decimal64->new($m, $p);
    if($d64_1 != $d64_2) {
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
      my $d64_1 = Math::Decimal64->new($man, $prec);
      my ($m, $p) = D64toME($d64_1);
      my $d64_2 = Math::Decimal64->new($m, $p);
      if($d64_1 != $d64_2) {
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
      my $d64_1 = Math::Decimal64->new($man, -$prec);
      my ($m, $p) = D64toME($d64_1);
      my $d64_2 = Math::Decimal64->new($m, $p);
      if($d64_1 != $d64_2) {
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

$d64_1 = Math::Decimal64->new('8069610750070607', 1);
($man, $exp) = D64toME($d64_1);
if($man eq '8069610750070607' && $exp == 1) {print "ok 10\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 10\n";
}

# Used to fail on my powerpc box - a bug in the compiler/libc print formatting (sprintf).
$d64_1 = Math::Decimal64->new('897', -292);
($man, $exp) = D64toME($d64_1);
if($man eq '897' && $exp == -292) {print "ok 11\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 11\n";
}

$d64_1 = Math::Decimal64->new('-897', -292);
($man, $exp) = D64toME($d64_1);
if($man eq '-897' && $exp == -292) {print "ok 12\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 12\n";
}

# Used to fail on my powerpc box - a bug in the compiler/libc print formatting (sprintf).
$d64_1 = Math::Decimal64->new('78284', -294);
($man, $exp) = D64toME($d64_1);
if($man eq '78284' && $exp == -294) {print "ok 13\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 13\n";
}

$d64_1 = Math::Decimal64->new('-78284', -294);
($man, $exp) = D64toME($d64_1);
if($man eq '-78284' && $exp == -294) {print "ok 14\n"}
else {
  warn "\$man: $man \$exp: $exp\n";
  print "not ok 14\n";
}


sub rand_x {
    if($_[0] > 16 || $_[0] < 0) {die "rand_x() given bad value"}
    my $ret;
    for(1 ..$_[0]) {$ret .= int(rand(10))}
    return $ret;
}


