use strict;
use warnings;
use Math::Decimal64 qw(:all);

my $t = 4;

if(d64_fmt() eq 'DPD') {
  warn "Skipping all tests for DPD format\n";
  print "1..1\n";
  print "ok 1\n";
  exit 0;
}

print "1..$t\n";

my $ok = 1;

for my $exp(0..10, 20, 30, 350 .. 360) {
  for my $digits(1..16) {
    my $man = random_select($digits);
    $man =~ s/^0+//;
    $man ||= '0';
    my $d64 = MEtoD64($man, $exp);
    my $d64_orig = $d64;
    my($s, $e) = (get_sign($d64), get_exp($d64));

    if($s ne '+') {
      $ok = 0;
      warn "Wrong sign ($s) for ($man, $exp)\n";
    }

    $d64 *= Exp10(-$e);

    my $check = Math::Decimal64::_decode_mant($d64);
    $check =~ s/^0+//;


    while($exp > $e) {
      $check =~ s/0$//;
      $e++;
    }

    $check ||= '0';

    $s = '' unless $s eq '-';

    if($s . $check ne $man) {
      $ok = 0;
      warn "\$man ($man) returned as ", $s . $check, "(\$s . \$check)\n";
    }

    my $d64_new = MEtoD64($s . $check, $e);
    if($d64_new != $d64_orig) {
      $ok = 0;
      warn "\n \$d64_orig: $d64_orig\n \$d64_new: $d64_new\n";
    }

  }
}

$ok ? print "ok 1\n" : print "not ok 1\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 360) {
  for my $digits(1..16) {
    my $man = random_select($digits);
    $man =~ s/^0+//;
    $man ||= '0';
    $man = '-' . $man;
    my $d64 = MEtoD64($man, $exp);
    my $d64_orig = $d64;
    my($s, $e) = (get_sign($d64), get_exp($d64));

    if($s ne '-') {
      $ok = 0;
      warn "Wrong sign ($s) for ($man, $exp)\n";
    }

    $d64 *= Exp10(-$e);

    my $check = Math::Decimal64::_decode_mant($d64 * UnityD64(-1));
    $check =~ s/^0+//;

    while($exp > $e) {
      $check =~ s/0$//;
      $e++;
    }

    $check ||= '0';

    $s = '' unless $s eq '-';

    if($s . $check ne $man) {
      $ok = 0;
      warn "\$man ($man) returned as ", $s . $check, "(\$s . \$check)\n";
    }

    my $d64_new = MEtoD64($s . $check, $e);
    if($d64_new != $d64_orig) {
      $ok = 0;
      warn "\n \$d64_orig: $d64_orig\n \$d64_new: $d64_new\n";
    }

  }
}

$ok ? print "ok 2\n" : print "not ok 2\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 360) {
  for my $digits(1..16) {
    my $man = random_select($digits);
    $man =~ s/^0+//;
    $man ||= '0';
    my $d64 = MEtoD64($man, -$exp);
    my $d64_orig = $d64;
    my($s, $e) = (get_sign($d64), get_exp($d64));

    if($s ne '+') {
      $ok = 0;
      warn "Wrong sign ($s) for ($man, $exp)\n";
    }

    $d64 *= Exp10(-$e);

    my $check = Math::Decimal64::_decode_mant($d64);
    $check =~ s/^0+//;

    while($exp < $e) {
      $check =~ s/0$//;
      $e--;
    }

    $s = '' unless $s eq '-';

    $check ||= '0';

    if($s . $check ne $man) {
      $ok = 0;
      warn "\$man ($man) returned as ", $s . $check, "(\$s . \$check)\n";
    }

    my $d64_new = MEtoD64($s . $check, $e);
    if($d64_new != $d64_orig) {
      $ok = 0;
      warn "\n \$d64_orig: $d64_orig\n \$d64_new: $d64_new\n";
    }

  }
}

$ok ? print "ok 3\n" : print "not ok 3\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 360) {
  for my $digits(1..16) {
    my $man = random_select($digits);
    $man =~ s/^0+//;
    $man ||= '0';
    $man = '-' . $man;
    my $d64 = MEtoD64($man, -$exp);
    my $d64_orig = $d64;
    my($s, $e) = (get_sign($d64), get_exp($d64));

    if($s ne '-') {
      $ok = 0;
      warn "Wrong sign ($s) for ($man, $exp)\n";
    }

    $d64 *= Exp10(-$e);

    my $check = Math::Decimal64::_decode_mant($d64 * UnityD64(-1));
    $check =~ s/^0+//;

    while($exp < $e) {
      $check =~ s/0$//;
      $e--;
    }

    $check ||= '0';

    $s = '' unless $s eq '-';

    if($s . $check ne $man) {
      $ok = 0;
      warn "\$man ($man) returned as ", $s . $check, "(\$s . \$check)\n";
    }

    my $d64_new = MEtoD64($s . $check, $e);
    if($d64_new != $d64_orig) {
      $ok = 0;
      warn "\n \$d64_orig: $d64_orig\n \$d64_new: $d64_new\n";
    }

  }
}

$ok ? print "ok 4\n" : print "not ok 4\n";

sub random_select {
  my $ret = '';
  for(1 .. $_[0]) {
    $ret .= int(rand(10));
  }
  return "$ret";
}
