use strict;
use warnings;
use Math::Decimal128 qw(:all);

my $t = 4;

if(d128_fmt() eq 'DPD') {
  warn "Skipping all tests for DPD format\n";
  print "1..1\n";
  print "ok 1\n";
  exit 0;
}

print "1..$t\n";

my $ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300, 6090 .. 6101) {
  for my $digits(1..34) {
    my $man = random_select($digits);
    $man =~ s/^0+//;
    $man ||= '0';
    my $d128 = MEtoD128($man, $exp);
    my($s, $e) = (get_signl($d128), get_expl($d128));

    if($s ne '+') {
      $ok = 0;
      warn "Wrong sign ($s) for ($man, $exp)\n";
    }

    $d128 *= Exp10l(-$e);

    if(get_expl($d128)) {
      warn "Exponent not set to zero (", get_expl($d128), ") for ($man, $exp)\n";
    }

    my $check = Math::Decimal128::_decode_mant($d128);
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

  }
}

#__END__

$ok ? print "ok 1\n" : print "not ok 1\n";

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..26) {
    my $man = random_select($digits);
    $man =~ s/^0+//;
    $man ||= '0';
    $man = '-' . $man;
    my $d128 = MEtoD128($man, $exp);
    my($s, $e) = (get_signl($d128), get_expl($d128));

    if($s ne '-') {
      $ok = 0;
      warn "Wrong sign ($s) for ($man, $exp)\n";
    }

    $d128 *= Exp10l(-$e);

    if(get_expl($d128)) {
      warn "Exponent not set to zero (", get_expl($d128), ") for ($man, $exp)\n";
    }

    my $check = Math::Decimal128::_decode_mant($d128 * UnityD128(-1));
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

  }
}

$ok ? print "ok 2\n" : print "not ok 2\n";

#__END__

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..26) {
    my $man = random_select($digits);
    $man =~ s/^0+//;
    $man ||= '0';
    my $d128 = MEtoD128($man, -$exp);
    my($s, $e) = (get_signl($d128), get_expl($d128));

    if($s ne '+') {
      $ok = 0;
      warn "Wrong sign ($s) for ($man, $exp)\n";
    }

    $d128 *= Exp10l(-$e);

    if(get_expl($d128)) {
      warn "Exponent not set to zero (", get_expl($d128), ") for ($man, $exp)\n";
    }

    my $check = Math::Decimal128::_decode_mant($d128);
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

  }
}

$ok ? print "ok 3\n" : print "not ok 3\n";

#__END__

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300, 6090..6100) {
  for my $digits(1..34) {
    my $man = random_select($digits);
    $man =~ s/^0+//;
    $man ||= '0';
    $man = '-' . $man;
    my $d128 = MEtoD128($man, -$exp);
    my($s, $e) = (get_signl($d128), get_expl($d128));

    if($s ne '-') {
      $ok = 0;
      warn "Wrong sign ($s) for ($man, $exp)\n";
    }

    $d128 *= Exp10l(-$e);

    if(get_expl($d128)) {
      warn "Exponent not set to zero (", get_expl($d128), ") for ($man, $exp)\n";
    }

    my $check = Math::Decimal128::_decode_mant($d128 * UnityD128(-1));
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
