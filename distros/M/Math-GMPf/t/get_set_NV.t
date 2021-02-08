use strict;
use warnings;
use Math::GMPf qw(:mpf);
use Config;
use POSIX;

print "1..12\n";

my ($prec, $nv_max);

if($Config{nvsize} == 8) {
  # Don't assume that POSIX::DBL_MAX is available
  eval{ $nv_max = POSIX::DBL_MAX };

  # On older perl versions on x64 windows, the following
  # would assign 'Inf' to $nv_max if POSIX_DBL_MAX were
  # unavailable.
  # Luckily, in those cases POSIX::DBL_MAX has already
  # assigned the correct value.
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

if($fi == $nv) {print "ok 1\n"}
else {
  warn "\n $fi != $nv\n";
  print "not ok 1\n";
}

if($nv == Rmpf_get_NV_rndn($fi)) {print "ok 2\n"}
else {
  warn "\n $nv != ", Rmpf_get_NV_rndn($fi), "\n";
  print "not ok 2\n";
}

my $inf = 999**(999**999);
my $nan = $inf / $inf;

eval {Rmpf_set_NV($fi, $inf);};

if($@ =~ /cannot coerce an Inf to a Math::GMPf object/) {print "ok 3\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 3\n";
}

eval {Rmpf_set_NV($fi, $nan);};

if($@ =~ /cannot coerce a NaN to a Math::GMPf object/) {print "ok 4\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 4\n";
}

$nv = -123.45678;

Rmpf_set_NV($fi, $nv);

if($fi == $nv) {print "ok 5\n"}
else {
  warn "\n $fi != $nv\n";
  print "not ok 5\n";
}

if($nv == Rmpf_get_NV($fi)) {print "ok 6\n"}
else {
  warn "\n $nv != ", Rmpf_get_NV($fi), "\n";
  print "not ok 6\n";
}

$nv = -123456.78e70;

Rmpf_set_NV($fi, $nv);

if($fi == $nv) {print "ok 7\n"}
else {
  warn "\n $fi != $nv\n";
  print "not ok 7\n";
}

if($nv == Rmpf_get_NV_rndn($fi)) {print "ok 8\n"}
else {
  warn "\n $nv != ", Rmpf_get_NV($fi), "\n";
  print "not ok 8\n";
}

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

  if($ok) {print "ok 9\n"}
  else    {print "not ok 9\n"}

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

  if($ok) {print "ok 10\n"}
  else    {print "not ok 10\n"}

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

  if($ok) {print "ok 11\n"}
  else    {print "not ok 11\n"}

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

  if($ok) {print "ok 12\n"}
  else    {print "not ok 12\n"}
}

sub random_string {
  my $ret = '';
  for (1..$_[0]) {$ret .= int rand(2)}
  $ret =~ s/^0+//;
  if(int(rand(2))) {$ret =  '0.' . $ret}
  else             {$ret = '-0.' . $ret}
  return $ret;
}

sub _skipper {
  warn "\n Skipping tests 9 to 12 - $_[0]\n";
  print "ok 9\n";
  print "ok 10\n";
  print "ok 11\n";
  print "ok 12\n";
}


