use strict;
use warnings;
use Math::GMPf qw(:mpf IOK_flag NOK_flag POK_flag);
use Config;
use POSIX;

#print "1..12\n";

use Test::More;

my ($prec, $nv_max);

if($Config{nvsize} == 8) {
  # Don't assume that POSIX::DBL_MAX is available
  eval{ $nv_max = POSIX::DBL_MAX };

  # On older perl versions on x64 windows, assigning
  # 1.7976931348623157e308 to $nv_max would
  # result in $nv_max being set to 'Inf'.
  # Luckily, on those perls, POSIX::DBL_MAX is available
  # and has already assigned the correct value.

  $nv_max = 1.7976931348623157e308
     unless $nv_max;
}
else {
  # Don't assume that POSIX::LDBL_MAX is available
  eval{ $nv_max = POSIX::LDBL_MAX }
    if($Config{nvtype} eq 'long double');

  unless($nv_max) {
    # Initially assume __float128 or IEEE-754 128-bit long double.
    $nv_max = 1.18973149535723176508575932662800702e4932;
    #Adjust to 80-bit extended precision LDBL_MAX if $nv_max is Inf
    $nv_max = 1.18973149535723176502e4932
      if $nv_max == 99 ** (99 ** 99);
  }
}

$prec = 128; # Cover precisions of all NV's

Rmpf_set_default_prec ($prec);

my $nv = 1.2345678e-53;

my $fi = Rmpf_init();

Rmpf_set_NV($fi, $nv);

cmp_ok($fi, '==', $nv, "1: Math::GMPf obj == given NV");

cmp_ok($nv, '==', Rmpf_get_NV_rndn($fi), "1: NV successfully retrieved from Math::GMPf object");

my $inf = 999**(999**999);
my $nan = $inf / $inf;
eval {Rmpf_set_NV($fi, $inf);};

like($@, qr/cannot coerce an Inf to a Math::GMPf object/, "Cannot assign Inf to a Math::GMPf object");

eval {Rmpf_set_NV($fi, $nan);};

like($@, qr/cannot coerce a NaN to a Math::GMPf object/, "Cannot assign NaN to a Math::GMPf object");

$nv = -123.45678;

Rmpf_set_NV($fi, $nv);

cmp_ok($fi, '==', $nv, "2: Math::GMPf obj == given NV");

cmp_ok($nv, '==', Rmpf_get_NV_rndn($fi), "2: NV successfully retrieved from Math::GMPf object");

$nv = -12345678.78e70;

Rmpf_set_NV($fi, $nv);

cmp_ok($fi, '==', $nv, "3: Math::GMPf obj == given NV");

cmp_ok($nv, '==', Rmpf_get_NV_rndn($fi), "3: NV successfully retrieved from Math::GMPf object");

my $have_mpfr = 0;

eval {require Math::MPFR;};

if($@) {
  _skipper ("couldn't load Math::MPFR");
}
elsif($Math::MPFR::VERSION < 3.36) {
  _skipper ("need at least version 3.36 of Math::MPFR, have only $Math::MPFR::VERSION");
}
elsif(Math::MPFR::MPFR_VERSION() <= 196868 && $Config{nvtype} ne 'double') { # less than 3.1.5
   # MPFR library doesn't round subnormal long doubles reliably
   _skipper("mpfr-" . Math::MPFR::MPFR_VERSION_STRING() . " not reliable for these tests, need at least 3.1.5");
}
else {

  my $ok = 1;

  Math::MPFR::Rmpfr_set_default_prec($prec);

  my $print_err = 0;

  for my $bits(128, 117, 110, 68, 57) {
    for(-16500..-16350, -1100..-950, -200..200, 900..1050, 16400..16600) {
      my $str = random_string($bits) . "e$_";

      my $mpf  = Math::GMPf->new($str, -2);
      my $mpfr = Math::MPFR->new($str,  2);

      my $mpf_d  = Rmpf_get_NV_rndn($mpf);

      my $mpfr_d = Math::MPFR::Rmpfr_get_NV($mpfr, 0);  # Round towards nearest, ties to even.

      if($mpf_d != $mpfr_d) {
        $ok = 0;
        my $mpf_d_pack   = scalar reverse unpack "h*", pack "F", $mpf_d;
        my $mpfr_d_pack  = scalar reverse unpack "h*", pack "F", $mpfr_d;
        if($print_err < 6) { # give specifics for first 6 errors only.
          warn "$str\nGMPf: $mpf_d_pack\nMPFR: $mpfr_d_pack\n";
          if($Config{nvtype} eq 'double') {
            printf "GMPf: %a\n", $mpf_d;
            printf "MPFR: %a\n", $mpfr_d;
          }
          else {
            printf "GMPf: %La\n", $mpf_d;
            printf "MPFR: %La\n", $mpfr_d;
          }
          warn  "Difference: ",$mpf_d - $mpfr_d, "\n";
          my @args = Rmpf_deref2($mpf, 2, $prec);
          my $rndaz = Math::GMPf::_rndaz(@args, $prec, 1);
          Math::MPFR::Rmpfr_dump($mpfr);
          print $rndaz, "\n";
          $print_err++;
        }
      }
    }
  }

  cmp_ok($ok, '==', 1, "Test 9");

  $ok = 1;

  $print_err = 0;

  for my $bits(128, 117, 110, 68, 57) {
    for(-16500..-16350, -1100..-950, -200..200, 900..1050, 16400..16600) {
      my $str = random_string($bits) . "e$_";

      my $mpf  = Math::GMPf->new($str, -2);
      my $mpfr = Math::MPFR->new();
      Math::MPFR::Rmpfr_set_str($mpfr, $str, 2, 1); # Round towards zero.

      my $mpf_d  = Rmpf_get_NV($mpf);

      my $mpfr_d = Math::MPFR::Rmpfr_get_NV($mpfr, 1);  # Round towards zero.

      # For nvtype eg 'double' or 'long double', finite mpfr values gt $nv_max or lt $nv_max * -1
      # require special handling for the sake of these tests. Under RNDZ, mpfr_get_d will always
      # return $nv_max for such values, but mpf_get_d will always return the infinity.

      if($Config{nvtype} eq 'double' || $Config{nvtype} eq 'long double') {
        if($mpfr > $nv_max) {
          Math::MPFR::Rmpfr_set_inf($mpfr, 1);
          $mpfr_d = Math::MPFR::Rmpfr_get_NV($mpfr, 0); # set $mpfr_d to Inf
        }
        if($mpfr < $nv_max * -1.0) {
          Math::MPFR::Rmpfr_set_inf($mpfr, -1);
          $mpfr_d = Math::MPFR::Rmpfr_get_NV($mpfr, 0); # set $mpfr_d to -Inf
        }
      }

      if($mpf_d != $mpfr_d) {
        $ok = 0;
        my $mpf_d_pack   = scalar reverse unpack "h*", pack "F", $mpf_d;
        my $mpfr_d_pack  = scalar reverse unpack "h*", pack "F", $mpfr_d;
        if($print_err < 6) { # give specifics for first 6 errors only.
          warn "GMPf: $mpf_d\nMPFR: $mpfr_d\n";
          warn "$str\nGMPf: $mpf_d_pack\nMPFR: $mpfr_d_pack\n";
          if($Config{nvtype} eq 'double') {
            printf "GMPf: %a\n", $mpf_d;
            printf "MPFR: %a\n", $mpfr_d;
          }
          else {
            printf "GMPf: %La\n", $mpf_d;
            printf "MPFR: %La\n", $mpfr_d;
          }
          warn  "Difference: ",$mpf_d - $mpfr_d, "\n";
          Math::MPFR::Rmpfr_dump($mpfr);
          $print_err++;
        }
      }
    }
  }

  cmp_ok($ok, '==', 1, "Test 10");

  $ok = 1;

  $prec = 64;

  Rmpf_set_default_prec ($prec);
  Math::MPFR::Rmpfr_set_default_prec($prec);

  $print_err = 0;

  for(-16500..-16350, -1100..-950, -200..200, 900..1050, 16400..16600) {
    my $str = random_string($prec) . "e$_";
    my $mpf  = Math::GMPf->new($str, -2);
    my $mpfr = Math::MPFR->new($str,  2);

    my $mpf_d  = Rmpf_get_NV_rndn($mpf);

    my $mpfr_d = Math::MPFR::Rmpfr_get_NV($mpfr, 0);  # Round towards nearest, ties to even.

    if($mpf_d != $mpfr_d) {
      $ok = 0;
      my $mpf_d_pack   = scalar reverse unpack "h*", pack "F", $mpf_d;
      my $mpfr_d_pack  = scalar reverse unpack "h*", pack "F", $mpfr_d;
      if($print_err < 6) { # give specifics for first 6 errors only.
        warn "GMPf: $mpf_d\nMPFR: $mpfr_d\n";
        warn "$str\nGMPf: $mpf_d_pack\nMPFR: $mpfr_d_pack\n";
        if($Config{nvtype} eq 'double') {
          printf "GMPf: %a\n", $mpf_d;
          printf "MPFR: %a\n", $mpfr_d;
        }
        else {
          printf "GMPf: %La\n", $mpf_d;
          printf "MPFR: %La\n", $mpfr_d;
        }
        warn  "Difference: ",$mpf_d - $mpfr_d, "\n";
        my @args = Rmpf_deref2($mpf, 2, $prec);
        my $rndaz = Math::GMPf::_rndaz(@args, $prec, 1);
        Math::MPFR::Rmpfr_dump($mpfr);
        print $rndaz, "\n";
        $print_err++;
      }
    }
  }

  cmp_ok($ok, '==', 1, "Test 11");

  $ok = 1;

  $print_err = 0;

  for(-16500..-16350, -1100..-950, -200..200, 900..1050, 16400..16600) {
    my $str = random_string($prec) . "e$_";

    my $mpf  = Math::GMPf->new($str, -2);
    my $mpfr = Math::MPFR->new($str,  2);

    my $mpf_d  = Rmpf_get_NV($mpf);

    my $mpfr_d = Math::MPFR::Rmpfr_get_NV($mpfr, 1);  # Round towards zero.

    # For nvtype eg 'double' or 'long double', finite mpfr values gt $nv_max or lt $nv_max * -1
    # require special handling for the sake of these tests. Under RNDZ, mpfr_get_d will always
    # return $nv_max for such values, but mpf_get_d returns the infinity.

    if($Config{nvtype} eq 'double' || $Config{nvtype} eq 'long double') {
      if($mpfr > $nv_max) {
        Math::MPFR::Rmpfr_set_inf($mpfr, 1);
        $mpfr_d = Math::MPFR::Rmpfr_get_NV($mpfr, 0); # set $mpfr_d to Inf
      }
      if($mpfr < $nv_max * -1.0) {
        Math::MPFR::Rmpfr_set_inf($mpfr, -1);
        $mpfr_d = Math::MPFR::Rmpfr_get_NV($mpfr, 0); # set $mpfr_d to Inf
      }
    }

    if($mpf_d != $mpfr_d) {
      $ok = 0;
      my $mpf_d_pack   = scalar reverse unpack "h*", pack "F", $mpf_d;
      my $mpfr_d_pack  = scalar reverse unpack "h*", pack "F", $mpfr_d;
      if($print_err < 6) { # give specifics for first 6 errors only.
        warn "$str\nGMPf: $mpf_d_pack\nMPFR: $mpfr_d_pack\n";
        if($Config{nvtype} eq 'double') {
          printf "GMPf: %a\n", $mpf_d;
          printf "MPFR: %a\n", $mpfr_d;
        }
        else {
          printf "GMPf: %La\n", $mpf_d;
          printf "MPFR: %La\n", $mpfr_d;
        }
        warn  "Difference: ",$mpf_d - $mpfr_d, "\n";
        Math::MPFR::Rmpfr_dump($mpfr);
        $print_err++;
      }
    }
  }

  cmp_ok($ok, '==', 1, "Test 12");

  $ok = 1;

  for(-300..300) {
    my $str = random_dec_string() . "e$_";
    my $s = $str;
    my $nv = $s + 0; # don't mess with the $str flags

    # Provide sufficient precision to MPFR and GMPf
    # objects such that no rounding will occur when
    # the NV is assigned and retrieved.

    my $mpfr = Math::MPFR::Rmpfr_init2(2098);
    my $mpf  =             Rmpf_init2 (2098);

    # On Math-MPFR-4.17 and earlier,Rmpfr_set_NV will croak if
    # $nv is detected as something other than an NV.
    # We therefore skip further testing of this $nv if this
    # condition is met:

    next if !NOK_flag($nv);

    Math::MPFR::Rmpfr_set_NV($mpfr, $nv, 0);
                Rmpf_set_NV ($mpf,  $nv);

    cmp_ok(Math::MPFR::Rmpfr_cmp_f($mpfr, $mpf), '==', 0, "$s:\nRmpfr_set_NV and Rmpf_set_NV agree");

    my $mpfr_nv = Math::MPFR::Rmpfr_get_NV($mpfr, 0);
    my $mpf_nv  =             Rmpf_get_NV ($mpf);

    cmp_ok($mpf_nv, '==', $mpfr_nv, "$s:\nRetrieved NVs are equivalent");

  }

}

done_testing();

sub random_string {
  my $ret = '';
  for (1..$_[0]) {$ret .= int rand(2)}
  $ret =~ s/^0+//;
  if(int(rand(2))) {$ret =  '0.' . $ret}
  else             {$ret = '-0.' . $ret}
  return $ret;
}

sub random_dec_string {
  my $ret = '1.';
  for (1..36) {$ret .= int rand(10)}
  $ret =  '-' . $ret if(int(rand(2)));
  return $ret;
}

sub _skipper {
  warn "\n Skipping remaining test - $_[0]\n";
}


