use warnings;
use strict;
use Math::MPFR qw(:mpfr);
#use Math::NV qw(:all);

my $test_nv1 = 1.0;
my $test_nv2 = $test_nv1 + (2 ** -1000);

if($test_nv2 > $test_nv1 && Math::MPFR::_has_longdouble()) {

  my $t = 266;
  print "1..$t\n";

  Rmpfr_set_default_prec(2098);
  my $nv = (2 ** 100) + (2 ** -1060) + (2 ** -1068) + (2 ** -1074);
  my $fr = Math::MPFR->new($nv);

  if($nv == $fr) {print "ok 1\n"}
  else {
    warn "\n\$nv: $nv\n\$fr: $fr\n";
    print "not ok 1\n";
  }

  if($fr > 2 ** 100) { print "ok 2\n"}
  else {print "not ok 2\n"}

  if(!Rmpfr_cmp_ld($fr, $nv)) {print "ok 3\n"}
  else {
    warn "\n\$nv: $nv\n\$fr: $fr\n";
    print "not ok 3\n";
  }

  my $nv_redone = Rmpfr_get_ld($fr, MPFR_RNDN);

  if($nv_redone == $nv) {
    print "ok 4\n";
  }
  else {
    warn "\n\$nv: $nv\n\$nv_redone: $nv_redone\n";
    print "not ok 4\n";
  }

  my $nv_redone2 = Rmpfr_get_NV($fr, MPFR_RNDN);

  if($nv_redone2 == $nv) {
    print "ok 5\n";
  }
  else {
    warn "\n\$nv: $nv\n\$nv_redone: $nv_redone\n";
    print "not ok 5\n";
  }

  my $fr2 = Math::MPFR->new($nv + (2 ** 100));

  if(Rmpfr_cmp_ld($fr2, $nv) > 0) {print "ok 6\n"}
  else {
    warn "\n\$fr:  $fr\n\$fr2: $fr2\n";
    print "not ok 6\n";
  }

  my $set_test = Rmpfr_init();
  my $ret = Rmpfr_set_ld($set_test, $nv, MPFR_RNDN);

  if(!$ret) {print "ok 7\n"}
  else {
    warn "\n\$ret: $ret\n";
    print "not ok 7\n";
  }

  my @variants = (1,2,3,4);
  $t = 7;

# Tests 8-11 follow:

#################################
  for my $v(@variants) {
    my($ok, $count) = (1, 0);
    $t++;
    my @curr;
    @curr = ('-', '-') if $v == 1;
    @curr = ('+', '-') if $v == 2;
    @curr = ('-', '+') if $v == 3;
    @curr = ('+', '+') if $v == 4;
#################################

    for my $exp(0..10, 20, 30, 280 .. 308) {
      for my $digits(1..31) {
        my $str = $curr[0] . random_select($digits) . 'e' . $curr[1] . "$exp";
        my $nv = $str * 1.0;
        my $fr = Math::MPFR->new();
        my $tern = Rmpfr_set_ld($fr, $nv, MPFR_RNDN);

        #print "$nv ";

        if($tern) {
          warn "\n$str: $str \$tern: $tern\n"
            unless $count > 5;
          $ok = 0;
          $count++;
        }

        if($nv != $fr) {
          warn "\n$str: $str \$nv: $nv \$fr: $fr\n"
            unless $count > 5;
          $ok = 0;
          $count++;
        }

        my $nv_redone = Rmpfr_get_ld($fr, MPFR_RNDN);

        if($nv != $nv_redone) {
          warn "\n$str: $str \$nv: $nv \$nv_redone: $nv_redone\n"
            unless $count > 5;
          $ok = 0;
          $count++;
        }

      }

    }

  if($ok) {print "ok $t\n"}
  else {print "not ok $t\n"}
  }


#################################
  for my $v(@variants) {
    my($ok, $count) = (1, 0);
    $t++;
    my @curr;
    @curr = ('-', '-') if $v == 1;
    @curr = ('+', '-') if $v == 2;
    @curr = ('-', '+') if $v == 3;
    @curr = ('+', '+') if $v == 4;
#################################

    for my $exp(0..10, 20, 30, 280 .. 308) {
      for my $digits(1..31) {
        my $str = $curr[0] . '0.' . random_select($digits) . 'e' . $curr[1] . "$exp";
        my $nv = $str * 1.0;
        my $fr = Math::MPFR->new();
        my $tern = Rmpfr_set_ld($fr, $nv, MPFR_RNDN);

        if($tern) {
          warn "\n$str: $str \$tern: $tern\n"
            unless $count > 5;
          $ok = 0;
          $count++;
        }

        if($nv != $fr) {
          warn "\n$str: $str \$nv: $nv \$fr: $fr\n"
            unless $count > 5;
          $ok = 0;
          $count++;
        }

        my $nv_redone = Rmpfr_get_ld($fr, MPFR_RNDN);

        if($nv != $nv_redone) {
          warn "\n$str: $str \$nv: $nv \$nv_redone: $nv_redone\n"
            unless $count > 5;
          $ok = 0;
          $count++;
        }

      }

    }

  if($ok) {print "ok $t\n"}
  else {print "not ok $t\n"}
  }

  Rmpfr_set_default_prec(106);
  $t = 16;


  for(-305 .. -293) {
    my $str = "1e$_";
    my $f1 = Math::MPFR->new($str);

    my $nv = $str * 1.0;
    #my $nv = nv($str);
    my $f2 = Math::MPFR->new($nv);

    if($f1 != $f2) {print "ok $t\n"}
    else {
      warn "\n$str: \$f1 == \$f2\n";
      Rmpfr_dump($f1);
      Rmpfr_dump($f2);
      print "not ok $t\n";
    }
    $t++;

    if($f1 != $nv) {print "ok $t\n"}
    else {
      warn "\n$str: \$f1 == \$nv\n";
      print "not ok $t\n";
    }
    $t++;

    if($f2 == $nv) {print "ok $t\n"}
    else {
      warn "\n$str: \$f2 != $nv\n";
      print "not ok $t\n";
    }
    $t++;

    my $n1 = Rmpfr_get_ld($f1, MPFR_RNDN);
    my $n2 = Rmpfr_get_ld($f2, MPFR_RNDN);

    if($n1 == $nv) {print "ok $t\n"}
    else {
      $n1 > $nv ? warn "\n$str: \$n1 is greater than \$nv\n"
                : warn "\n$str: \$n1 is less than \$nv\n";
      print "not ok $t\n";
    }
    $t++;

    if($n2 == $nv) {print "ok $t\n"}
    else {
      $n2 > $nv ? warn "\n$str: \$n2 is greater than \$nv\n"
                : warn "\n$str: \$n2 is less than \$nv\n";
      print "not ok $t\n";
    }
    $t++;
  }

  #Rmpfr_dump($f1);
  #Rmpfr_dump($f2);

  Rmpfr_set_default_prec(2098);

  $t--; # Otherwise we don't run a test 81

  # Tests 81-88 follow

  for my $exp(298 .. 304) {
    $t++;
    my $ok = 1;
    my $str = '0.0000000009' . "e-$exp";
    my $nv = $str * 1.0;
    my $fr = Math::MPFR->new();
    my $tern = Rmpfr_set_ld($fr, $nv, MPFR_RNDN);

    if($tern) {
      warn "\n$str: Rmpfr_set_ld returned true\n";
      $ok = 0;
    }

    if($fr != $nv) {
      warn "\n$str: \$fr != \$nv\n";
      $ok = 0;
    }

    my $nv_redone = Rmpfr_get_ld($fr, MPFR_RNDN);

    if($nv != $nv_redone) {
      warn "\n$str: \$nv != \$nv_redone\n";
      $ok = 0;
    }

    if($ok) {print "ok $t\n"}
    else {print "not ok $t\n"}
  }

  # Tests 89-95 follow:

  Rmpfr_set_default_prec(106);

  for my $exp(298 .. 304) {
    $t++;
    my $ok = 1;
    my $str = '0.0000000009' . "e-$exp";
    my $nv = $str * 1.0;
    my $fr = Math::MPFR->new($nv);

    my $nv_redone = Rmpfr_get_ld($fr, MPFR_RNDN);

    if($nv != $nv_redone) {
      warn "\n$str: \$nv != \$nv_redone\n";
      $ok = 0;
    }

    if($ok) {print "ok $t\n"}
    else {print "not ok $t\n"}
  }

  my($nv1, $nv2, $nv3, $nv4) = (2 ** 1023, 2 ** 1000, 2 ** - 1074, 2 ** -1054);
  @variants = (1, 2, 3, 4);

  # Tests 96-99 follow:

  #################################
  for my $v(@variants) {
    my($ok, $count) = (1, 0);
    $t++;
    my @curr;
    @curr = ('-1', '-1') if $v == 4;
    @curr = ('+1', '-1') if $v == 2;
    @curr = ('-1', '+1') if $v == 3;
    @curr = ('+1', '+1') if $v == 1;
  #################################

  my $nv = ($nv2 + ($nv1 * $curr[0])) + ($nv4 + ($nv3 * $curr[1]));
  my $fr = Rmpfr_init();

  my $tern = Rmpfr_set_ld($fr, $nv, MPFR_RNDN);

  if(!$tern) {
    warn "\n@curr: Rmpfr_set_ld returned 0\n";
    $ok = 0;
  }

  if($fr == $nv) {
    warn "\n@curr: \$fr == $nv\n";
    $ok = 0;
  }

  my $nv_redone = Rmpfr_get_ld($fr, MPFR_RNDN);

  if($nv == $nv_redone) {
    warn "\n@curr: NV's match";
    $ok = 0;
  }


  if($ok) {print "ok $t\n"}
  else {print "not ok $t\n"}

  #############################
  } # Close "for(@variants)" loop
  #############################

  # Tests 100-103 follow:

  #################################
  for my $v(@variants) {
    my($ok, $count) = (1, 0);
    $t++;
    my @curr;
    @curr = ('-1', '-1') if $v == 4;
    @curr = ('+1', '-1') if $v == 2;
    @curr = ('-1', '+1') if $v == 3;
    @curr = ('+1', '+1') if $v == 1;
  #################################

  my $nv = ($nv2 + ($nv1 * $curr[0])) - ($nv4 + ($nv3 * $curr[1]));
  my $fr = Rmpfr_init();

  my $tern = Rmpfr_set_ld($fr, $nv, MPFR_RNDN);

  if(!$tern) {
    warn "\n@curr: Rmpfr_set_ld returned 0\n";
    $ok = 0;
  }

  if($fr == $nv) {
    warn "\n@curr: \$fr == $nv\n";
    $ok = 0;
  }

  my $nv_redone = Rmpfr_get_ld($fr, MPFR_RNDN);

  if($nv == $nv_redone) {
    warn "\n@curr: NV's match";
    $ok = 0;
  }


  if($ok) {print "ok $t\n"}
  else {print "not ok $t\n"}

  #############################
  } # Close "for(@variants)" loop
  #############################

  my @case1 = ('9007199254740991.01', '9007199254740991.04', '9007199254740991.05', '9007199254740991.06',
            '9007199254740991.09',
            '9007199254740991.02', '9007199254740991.03', '9007199254740991.07', '9007199254740991.08',
            '9007199254740991.11', '9007199254740991.14', '9007199254740991.15', '9007199254740991.16',
            '9007199254740991.10', '9007199254740991.12', '9007199254740991.13', '9007199254740991.17',
            '9007199254740991.19',
            '9007199254740991.41', '9007199254740991.44', '9007199254740991.45', '9007199254740991.46',
            '9007199254740991.40', '9007199254740991.42', '9007199254740991.43', '9007199254740991.48',
            '9007199254740991.49', '9007199254740991.4999999',
            '9007199254740991.50', '9007199254740991.51', '9007199254740991.55', '9007199254740991.56',
            '9007199254740991.52', '9007199254740991.53', '9007199254740991.57', '9007199254740991.58',
            '9007199254740991.59',
            '9007199254740991.61', '9007199254740991.64', '9007199254740991.65', '9007199254740991.66',
            '9007199254740991.69',
            '9007199254740991.91', '9007199254740991.94', '9007199254740991.95', '9007199254740991.96',
            '9007199254740991.90', '9007199254740991.94999999', '9007199254740991.92', '9007199254740991.93',
            '9007199254740991.99',
           );

  my @case2 = ('9007199254740990.01', '9007199254740990.04', '9007199254740990.05', '9007199254740990.06',
            '9007199254740990.09',
            '9007199254740990.11', '9007199254740990.14', '9007199254740990.15', '9007199254740990.16',
            '9007199254740990.19',
            '9007199254740990.41', '9007199254740990.44', '9007199254740990.45', '9007199254740990.46',
            '9007199254740990.49',
            '9007199254740990.50', '9007199254740990.51', '9007199254740990.55', '9007199254740990.56',
            '9007199254740990.59',
            '9007199254740990.61', '9007199254740990.64', '9007199254740990.65', '9007199254740990.66',
            '9007199254740990.69',
            '9007199254740990.91', '9007199254740990.94', '9007199254740990.95', '9007199254740990.96',
            '9007199254740990.99',
           );

  my @case3 = ('4503599627370495.01', '4503599627370495.04', '4503599627370495.05', '4503599627370495.06',
            '4503599627370495.09',
            '4503599627370495.11', '4503599627370495.14', '4503599627370495.15', '4503599627370495.16',
            '4503599627370495.19',
            '4503599627370495.41', '4503599627370495.44', '4503599627370495.45', '4503599627370495.46',
            '4503599627370495.49',
            '4503599627370495.50', '4503599627370495.51', '4503599627370495.55', '4503599627370495.56',
            '4503599627370495.59',
            '4503599627370495.61', '4503599627370495.64', '4503599627370495.65', '4503599627370495.66',
            '4503599627370495.69',
            '4503599627370495.91', '4503599627370495.94', '4503599627370495.95', '4503599627370495.96',
            '4503599627370495.99',
           );

  Rmpfr_set_default_prec(2098);

  # Tests 104-214 follow

  for my $str (@case1, @case2, @case3) {
    $t++;
    my $ok = 1;
    my $nv = $str + 0;
    my $fr = Rmpfr_init();

    my $tern = Rmpfr_set_ld($fr, $nv, MPFR_RNDN);

    if($tern) {
      warn "\n$str: Rmpfr_set_ld returned $tern\n";
      $ok = 0;
    }

    if($fr != $nv) {
      warn "\n$str: \$fr != \$nv\n";
      $ok = 0;
    }

    my $nv_redone = Rmpfr_get_NV($fr, MPFR_RNDN);

    if($nv != $nv_redone) {
      warn "\n$str: \$nv != \$nv_redone\n";
      $ok = 0;
    }

    if($ok) {print "ok $t\n"}
    else {print "not ok $t\n"}
  }


  # For double-doubles less than 2**-1021, 53-bits of precision and 2098 bits of precison should
  # both store the same value.

  my $fr_53 = Rmpfr_init2(53);
  my $fr_53_next = Rmpfr_init2(53);
  Rmpfr_set_ld($fr_53, 0.0, MPFR_RNDN);
  Rmpfr_set_ld($fr_53_next, 0.0, MPFR_RNDN);
  my $fr_2098 = Math::MPFR->new();
  my $fr_2098_next = Math::MPFR->new(0);
  my $ld_53_next = 0;
  my $ld_2098_next = 0;

  # Tests 215-267 follow:

  for(-1074 .. -1022) {
    $t++;
    my $ok = 1;

    my $tern = Rmpfr_set_ld($fr_53, 2 ** $_, MPFR_RNDN);
    if($tern) {
      warn "\n$_: Rmpfr_set_ld to 53 bits returned true\n";
      $ok = 0;
    }

    $tern = Rmpfr_set_ld($fr_2098, 2 ** $_, MPFR_RNDN);
    if($tern) {
      warn "\n$_: Rmpfr_set_ld to 53 bits returned true\n";
      $ok = 0;
    }

    if($fr_53 != $fr_2098) {
      warn "\n$_: \$fr_53 and \$fr_2098 are not equal\n";
      $ok = 0;
    }

    $fr_53_next += $fr_53;

    unless($fr_53_next > $fr_2098_next && $fr_2098_next < $fr_53_next) {
      warn "\n$_: \$fr_53_next/\$fr_2098_next anomaly\n";
      $ok = 0;
    }

    unless($fr_53_next > $ld_53_next && $ld_53_next < $fr_53_next) {
      warn "\n$_: \$fr_53_next/\$ld_53_next anomaly\n";
      $ok = 0;
    }

    #Rmpfr_add($fr_53_next, $fr_53_next, $fr_53, MPFR_RNDN);
    $fr_2098_next += $fr_2098;
    #Rmpfr_add($fr_2098_next, $fr_2098_next, $fr_2098, MPFR_RNDN);

    if($fr_53_next != $fr_2098_next) {
      warn "\n$_: \$fr_53_next and \$fr_2098_next are not equal\n";
      $ok = 0;
    }

    #Rmpfr_dump($fr_53_next);
    #Rmpfr_dump($fr_2098_next);
    #exit 0;

    my $ld_53 = Rmpfr_get_ld($fr_53, MPFR_RNDN);
    if($ld_53 != $fr_53) {
      warn "\n$_: \$ld_53 != \$fr_53\n";
      $ok = 0;
    }

    my $ld_2098 = Rmpfr_get_ld($fr_2098, MPFR_RNDN);
    if($ld_2098 != $fr_2098) {
      warn "\n$_: \$ld_2098 != \$fr_2098\n";
      $ok = 0;
    }

    $ld_53_next += $ld_53;
    $ld_2098_next += $ld_2098;

    if($ld_53_next != $ld_2098_next) {
      warn "\n$_: \$ld_53_next != \$ld_2098_next\n";
      $ok = 0;
    }


    if($ld_53_next != $fr_53_next) {
      warn "\n$_: \$ld_53_next != \$fr_53_next\n";
      $ok = 0;
    }


    if($fr_2098_next != $ld_2098_next) {
      warn "\n$_: \$fr_2098_next != \$ld_2098_next\n";
      $ok = 0;
    }

    if($ok) {print "ok $t\n"}
    else {print "not ok $t\n"}

  }


##############
##############
}

else {
  print "1..1\n";
  warn "\nSkipping all tests - not a Double-Double build\n";
  print "ok 1\n";
}



#############################
#############################

sub random_select {
  my $ret = '';
  for(1 .. $_[0]) {
    $ret .= int(rand(10));
  }
  return $ret;
}
