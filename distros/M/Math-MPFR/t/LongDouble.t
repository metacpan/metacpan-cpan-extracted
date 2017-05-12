
use warnings;
use strict;
use Math::MPFR qw(:mpfr);

my $t = 11;

print "1..$t\n";

eval {require Math::LongDouble;};

unless($@ || $Math::LongDouble::VERSION < 0.02) {

  my $mant_dig = Math::MPFR::_LDBL_MANT_DIG(); # expected to be either 64 or 106
  my $ldbl_dig = Math::LongDouble::ld_get_prec();

  warn "\ndefault decimal precision: $ldbl_dig\n";

  my $def_prec = 6 + $mant_dig;

  my $ld_version = $Math::LongDouble::VERSION;
  Rmpfr_set_default_prec($def_prec);
  my($ld_1, $ld_2) = (Math::LongDouble->new('1.123'), Math::LongDouble->new());
  my $fr_plus6 = Math::MPFR->new();
  my $fr_true = Rmpfr_init2($mant_dig);
  my ($man, $exp);

  Rmpfr_set_LD($fr_plus6, $ld_1, MPFR_RNDN);
  Rmpfr_get_LD($ld_2, $fr_plus6, MPFR_RNDN);

  if($ld_1 && $ld_1 == $ld_2) {print "ok 1\n"}
  else {
    warn "\$ld_1: $ld_1\n\$ld_2: $ld_2\n";
    print "not ok 1\n";
  }

  # The following binary strings represent the mantissa for 1e-37 (for varous precisions)
  # Precision = 112 or 70:
  my $str_plus6 = $mant_dig == 106
     ? '1000100000011100111010100001010001010100010111000111010101110101011111100101000011010110010000010111011111011010'
     : '1000100000011100111010100001010001010100010111000111010101110101100000';

  # Precision = 106 or 64 (but derived from the relevant above representation).
  my $m_plus6_to_actual = $mant_dig == 106
     ? '1000100000011100111010100001010001010100010111000111010101110101011111100101000011010110010000010111011111'
     : '1000100000011100111010100001010001010100010111000111010101110110';

  # Precision = 106 or 64 (actual correct 106/64-bit representation).
  my $m_actual = $mant_dig == 106
     ? '1000100000011100111010100001010001010100010111000111010101110101011111100101000011010110010000010111011111'
     : '1000100000011100111010100001010001010100010111000111010101110101';

  my $ld_check = Math::LongDouble->new('1e-37');

  Rmpfr_set_str($fr_plus6, '1@-37', 10, MPFR_RNDN);
  Rmpfr_set_str($fr_true, '1@-37', 10, MPFR_RNDN);

  ($man, $exp) = Rmpfr_deref2($fr_true, 2, $mant_dig, MPFR_RNDN);
  print "\$man:\n$man\n\n";


  #####################################################
  # $ld_2, derived from $fr_true should == $ld_check  #
  #####################################################
  Rmpfr_get_LD($ld_2, $fr_true, MPFR_RNDN);
  $man = get_man($ld_2);

  my $expected;

  if    ($ld_version < '0.16') { $expected = '1.' . ('0' x ($ldbl_dig - 1))          }
  elsif ($ldbl_dig == 17)      { $expected = '1.0000000000000001'                    }
  elsif ($ldbl_dig == 21)      { $expected = '9.99999999999999999950'                }
  elsif ($ldbl_dig == 33)      { $expected = '9.99999999999999999999999999999991'    }
  elsif ($ldbl_dig == 36)      { $expected = '9.99999999999999999999999999999999934' }
  else                         { $expected = '1.' . ('0' x ($ldbl_dig - 1))          }

  if($man eq $expected) {print "ok 2\n"}
  else {
    warn "\nexpected $expected, got $man\n";
    print "not ok 2\n";
  }
  if($ld_check == $ld_2) {print "ok 3\n"}
  else {
    warn "\n\$ld_check: $ld_check\n\$ld_2: $ld_2\n";
    print "not ok 3\n";
  }
  $man = get_manp($ld_2, $ldbl_dig + 1);

  if    ($ld_version < '0.16') { $expected = '9.' . ('9' x ($ldbl_dig))               }
  elsif ($ldbl_dig == 17)      { $expected = '1.00000000000000007'                    }
  elsif ($ldbl_dig == 21)      { $expected = '9.999999999999999999497'                }
  elsif ($ldbl_dig == 33)      { $expected = '9.999999999999999999999999999999905'    }
  elsif ($ldbl_dig == 36)      { $expected = '9.999999999999999999999999999999999344' }
  else                         { $expected = '9.' . ('9' x ($ldbl_dig))               }

  if($man eq $expected) {print "ok 4\n"}
  else {
    warn "\nexpected $expected, got $man\n";
    print "not ok 4\n";
  }

  #####################################################
  # $ld_2, derived from $fr_plus6 should != $ld_check #
  #####################################################
  Rmpfr_get_LD($ld_2, $fr_plus6, MPFR_RNDN);
  $man = get_man($ld_2);

  if    ($ld_version < '0.16') { $expected = '1.' . ('0' x ($ldbl_dig - 1))          }
  elsif ($ldbl_dig == 17)      { $expected = '1.' . ('0' x 16)                       }
  elsif ($ldbl_dig == 21)      { $expected = '1.00000000000000000005'                }
  elsif ($ldbl_dig == 33)      { $expected = '1.00000000000000000000000000000001'    }
  elsif ($ldbl_dig == 36)      { $expected = '9.99999999999999999999999999999999934' }
  else                         { $expected = '1.' . ('0' x ($ldbl_dig - 1))          }

  if($man eq $expected) {print "ok 5\n"}
  else {
    warn "\nexpected $expected, got $man\n";
    print "not ok 5\n";
  }
  if($ld_check != $ld_2) {print "ok 6\n"}
  else {
    warn "\n\$ld_check: $ld_check\n\$ld_2: $ld_2\n";
    print "not ok 6\n";
  }
  $man = get_manp($ld_2, 19);
  if($man eq '1.000000000000000000') {print "ok 7\n"}
  else {
    warn "\n\$man: $man\n";
    print "not ok 7\n";
  }

  ##################################################################################
  # Mantissa of $fr_plus6, rounded to $mant_dig bits should eq $m_plus6_to_actual  #
  ##################################################################################
  ($man, $exp) = Rmpfr_deref2($fr_plus6, 2, $mant_dig, MPFR_RNDN);
  if($man eq $m_plus6_to_actual) {print "ok 8\n"}
  else {
    warn "\n\$man: $man\n      $m_plus6_to_actual\n";
    print "not ok 8\n";
  }

  ####################################################################
  # $mant_dig-bit mantissa of $fr_true should eq $m_actual           #
  ####################################################################
  ($man, $exp) = Rmpfr_deref2($fr_true, 2, $mant_dig, MPFR_RNDN);
  if($man eq $m_actual) {print "ok 9\n"}
  else {
    warn "\n\$man: $man\n\$m_actual: $m_actual\n";
    print "not ok 9\n";
  }


  Rmpfr_set_str($fr_plus6, $str_plus6, 2, MPFR_RNDN);
  ##################################################################################
  # Mantissa of $fr_plus6, rounded to $mant_dig bits should eq $m_plus6_to_actual  #
  ##################################################################################
  ($man, $exp) = Rmpfr_deref2($fr_plus6, 2, $mant_dig, MPFR_RNDN);
  if($man eq $m_plus6_to_actual) {print "ok 10\n"}
  else {
    warn "\n\$man: $man\n      $m_plus6_to_actual\n";
    print "not ok 10\n";
  }


  Rmpfr_set_str($fr_true, $str_plus6, 2, MPFR_RNDN);
  #################################################################################
  # Mantissa of $fr_true, rounded to $mant_dig bits should eq $m_plus6_to_actual  #
  #################################################################################
  ($man, $exp) = Rmpfr_deref2($fr_true, 2, $mant_dig, MPFR_RNDN);
  if($man eq $m_plus6_to_actual) {print "ok 11\n"}
  else {
    warn "\n\$man: $man\n      $m_plus6_to_actual\n";
    print "not ok 11\n";
  }
}


else {
  warn "\nSkipping all tests - couldn't load Math-LongDouble-0.02 (or later)\n";
  for(1 .. $t) {print "ok $_\n"}
}

sub get_man {
    return (split /e/i, Math::LongDouble::LDtoSTR($_[0]))[0];
}

sub get_manp {
    return (split /e/i, Math::LongDouble::LDtoSTRP($_[0], $_[1]))[0];
}
