use warnings;
use strict;
use Math::Decimal64 qw(:all);

eval{require Math::MPFR;};

if($@) {
  print "1..1\n";
  warn " Skipping all tests: Couldn't load Math::MPFR\n";
  print "ok 1\n";
  exit 0;
}

eval {Math::MPFR::_MPFR_WANT_DECIMAL_FLOATS();};

if($@ || !Math::MPFR::_MPFR_WANT_DECIMAL_FLOATS()) {
  print "1..1\n";
  warn " Skipping all tests: This build of Math::MPFR doesn't\n",
       " support Decimal64 conversion functions\n";
  print "ok 1\n";
  }
else {
  print "1..11\n";

  my($man, $exp, $mantissa, $exponent);

  my $smallest_pos = Math::Decimal64->new(1, -398);
  ($man, $exp) = FR64toME($smallest_pos);

  if($man == 1 && $exp == -398){print "ok 1\n"}
  else {
    warn "\$man: $man\n\$exp: $exp\n";
    print "not ok 1\n";
  }

  my $biggest_neg = Math::Decimal64->new(-1, -398);
  ($man, $exp) = FR64toME($biggest_neg);

  if($man == -1 && $exp == -398){print "ok 2\n"}
  else {
    warn "\$man: $man\n\$exp: $exp\n";
    print "not ok 2\n";
  }

  ($mantissa, $exponent) = D64toME(Math::Decimal64->new());
  ($man, $exp) = FR64toME(Math::Decimal64->new());

  if($man eq $mantissa && $exp == $exponent) {print "ok 3\n"}
    else {
      warn "\n3:mantissa: $mantissa  man: $man\n",
           "  exponent: $exponent  exp: $exp\n";
      print "not ok 3\n";
  }

  ($mantissa, $exponent) = D64toME(ZeroD64(1));
  ($man, $exp) = FR64toME(ZeroD64(1));

  if($man eq $mantissa && $exp == $exponent) {print "ok 4\n"}
    else {
      warn "\n4:mantissa: $mantissa  man: $man\n",
           "  exponent: $exponent  exp: $exp\n";
      print "not ok 4\n";
  }

  ($mantissa, $exponent) = D64toME(ZeroD64(-1));
  ($man, $exp) = FR64toME(ZeroD64(-1));

  if($man eq $mantissa && $exp == $exponent) {print "ok 5\n"}
    else {
      warn "\n5:mantissa: $mantissa  man: $man\n",
           "  exponent: $exponent  exp: $exp\n";
      print "not ok 5\n";
  }

  ($mantissa, $exponent) = D64toME(InfD64(1));
  ($man, $exp) = FR64toME(InfD64(1));

  if($man eq $mantissa && $exp == $exponent) {print "ok 6\n"}
    else {
      warn "\n6:mantissa: $mantissa  man: $man\n",
           "  exponent: $exponent  exp: $exp\n";
      print "not ok 6\n";
  }

  ($mantissa, $exponent) = D64toME(InfD64(-1));
  ($man, $exp) = FR64toME(InfD64(-1));

  if($man eq $mantissa && $exp == $exponent) {print "ok 7\n"}
    else {
      warn "\n7:mantissa: $mantissa  man: $man\n",
           "  exponent: $exponent  exp: $exp\n";
      print "not ok 7\n";
  }

  my $ok = 1;

  for my $prec(0 .. 382) { # Exponents >382 with 3-digit (integer) significands
                           # are out of bounds for MEtoD64().
    for my $eg(1 .. 10) {
      my $man = int(rand(500));
      if($eg % 2) {$man = '-' . $man}
      my $d64_1 = Math::Decimal64->new($man, $prec); # calls MEtoD64()
      my ($m, $p) = FR64toME($d64_1);
      my $d64_2 = Math::Decimal64->new($m, $p);
      if($d64_1 != $d64_2) {
        $ok = 0;
        warn "\n\$man: $man\n\$prec: $prec\n\$m: $m\n";
        defined($p) ? warn "\$p: $p\n"
                    : warn "\$p: undef\n";
      }
    }
  }

  if($ok) {print "ok 8\n"}
  else {print "not ok 8\n"}

  $ok = 1;

  for my $prec(0 .. 383) {
    for my $eg(1 .. 10) {
      my $man = int(rand(500));
      if($eg % 2) {$man = '-' . $man}
      my $d64_1 = Math::Decimal64->new($man, -$prec);
      my ($m, $p) = FR64toME($d64_1);
      my $d64_2 = Math::Decimal64->new($m, $p);
      if($d64_1 != $d64_2) {
        $ok = 0;
        warn "\n\$man: $man\n\$prec: -$prec\n\$m: $m\n";
        defined($p) ? warn "\$p: $p\n"
                    : warn "\$p: undef\n";
      }
    }
  }

  if($ok) {print "ok 9\n"}
  else {print "not ok 9\n"}

  $ok = 1;

  for my $size(1 .. 16) {
    for my $prec(0 .. 369) {
      for my $eg(1 .. 10) {
        my $man = rand_x($size);
        $man = '-' . $man if ($eg % 2);
        my $d64_1 = Math::Decimal64->new($man, $prec);
        my ($m, $p) = FR64toME($d64_1);
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

  if($ok) {print "ok 10\n"}
  else {print "not ok 10\n"}

  $ok = 1;

  for my $size(1 .. 16) {
    for my $prec(0 .. 398) {
      for my $eg(1 .. 10) {
        my $man = rand_x($size);
        $man = '-' . $man if ($eg % 2);
        my $d64_1 = Math::Decimal64->new($man, -$prec);
        my ($m, $p) = FR64toME($d64_1);
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

  if($ok) {print "ok 11\n"}
  else {print "not ok 11\n"}

}

sub rand_x {
    if($_[0] > 16 || $_[0] < 0) {die "rand_x() given bad value"}
    my $ret;
    for(1 ..$_[0]) {$ret .= int(rand(10))}
    return $ret;
}



