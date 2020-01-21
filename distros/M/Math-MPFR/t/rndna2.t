# Essentially the same as rndna.t, but
# uses Rmpfr_round_nearest_away().

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;

print "1..130\n";

warn "\n # Minimum allowed exponent: ", Rmpfr_get_emin_min(), "\n";
warn   " # Current minimum exponent: ", Rmpfr_get_emin(), "\n";

if(Rmpfr_get_emin() <= Rmpfr_get_emin_min()) {
  Rmpfr_set_emin(Rmpfr_get_emin_min() + 1);
  warn " # Resetting minimum exponent to ", Rmpfr_get_emin(), "\n #  for this test script. (See the\n",
       " #  Rmpfr_round_nearest_away() documentation.)\n";
}

my $ok = 1;
my $have_gmpq = 0;
my $have_gmpz = 0;

eval {require Math::GMPq;};
unless($@) {$have_gmpq = 1}

eval {require Math::GMPz;};
unless($@) {$have_gmpz = 1}

for(1..10) {
  my $str = '1.';
  for(1..70) {$str .= int(rand(2));}
  $str .= '01';
  my $nstr = '-' . $str;

  my $longrop  = Rmpfr_init2(73);
  my $check    = Rmpfr_init2(72);
  my $shortrop = Rmpfr_init2(72);

  my $coderef = \&Rmpfr_set;

  my $inex = Rmpfr_set_str($longrop, $str, 2, MPFR_RNDN);

  if($inex) {die "Rmpfr_set_str falsely returned $inex"}

  my $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded up, $longrop is exact.

  unless($shortrop > $longrop && $ret > 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $str, 2);
  unless($shortrop == $check && $ret > 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n";
  }

  $longrop *= -1;

  $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded down, $longrop is exact.

  unless($shortrop < $longrop && $ret < 0) {
   $ok = 0;
   warn "\n lt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $nstr, 2);
  unless($shortrop == $check && $ret < 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
  }
}

if($ok) {print "ok 1\n"}
else    {print "not ok 1\n"}
$ok = 1;

for(1..10) {
  my $str = '1.';
  for(1..70) {$str .= int(rand(2));}
  $str .= '011';
  my $nstr = '-' . $str;

  my $longrop = Rmpfr_init2(74);
  my $check    = Rmpfr_init2(72);
  my $shortrop = Rmpfr_init2(72);

  my $coderef = \&Rmpfr_set;

  my $inex = Rmpfr_set_str($longrop, $str, 2, MPFR_RNDN);

  if($inex) {die "Rmpfr_set_str falsely returned $inex"}

  my $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded up, $longrop is exact.

  unless($shortrop > $longrop && $ret > 0) {
    $ok = 0;
    warn "\n gt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $str, 2);
  unless($shortrop == $check && $ret > 0) {
    $ok = 0;
    warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
  }

  $longrop *= -1;

  $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded down, $longrop is exact.

  unless($shortrop < $longrop && $ret < 0) {
   $ok = 0;
   warn "\n lt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $nstr, 2);
  unless($shortrop == $check && $ret < 0) {
    $ok = 0;
    warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
  }

}

if($ok) {print "ok 2\n"}
else    {print "not ok 2\n"}
$ok = 1;

for(1..10) {
  my $str = '1.';
  for(1..70) {$str .= int(rand(2));}
  $str .= '001';
  my $nstr = '-' . $str;

  my $longrop = Rmpfr_init2(74);
  my $check    = Rmpfr_init2(72);
  my $shortrop = Rmpfr_init2(72);

  my $coderef = \&Rmpfr_set;

  my $inex = Rmpfr_set_str($longrop, $str, 2, MPFR_RNDN);

  if($inex) {die "Rmpfr_set_str falsely returned $inex"}

  my $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded down, $longrop is exact.

  unless($shortrop < $longrop && $ret < 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $str, 2);
  unless($shortrop == $check && $ret < 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
  }

  $longrop *= -1;

  $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded up, $longrop is exact.

  unless($shortrop > $longrop && $ret > 0) {
   $ok = 0;
   warn "\n lt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $nstr, 2);
  unless($shortrop == $check && $ret > 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
  }

}

if($ok) {print "ok 3\n"}
else    {print "not ok 3\n"}
$ok = 1;

####################################

for my $suffix('010', '011', '110', '111') {
  for(1..10) {
    my $str = '1.';
    for(1..70) {$str .= int(rand(2));
    }
    $str .= $suffix;
    my $nstr = '-' . $str;

    my $longrop = Rmpfr_init2(74);
    my $check    = Rmpfr_init2(72);
    my $shortrop = Rmpfr_init2(72);

    my $coderef = \&Rmpfr_set;

    my $inex = Rmpfr_set_str($longrop, $str, 2, MPFR_RNDN);

    if($inex) {die "Rmpfr_set_str falsely returned $inex"}

    my $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

    # $shortrop should always be rounded up, $longrop is exact.

    unless($shortrop > $longrop && $ret > 0) {
     $ok = 0;
     warn "\n gt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
    }

    $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $str, 2);
    unless($shortrop == $check && $ret > 0) {
     $ok = 0;
     warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
    }

    $longrop *= -1;

    $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

    # $shortrop should always be rounded down, $longrop is exact.

    unless($shortrop < $longrop && $ret < 0) {
      $ok = 0;
      warn "\n lt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
    }

    $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $nstr, 2);
    unless($shortrop == $check && $ret < 0) {
      $ok = 0;
      warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
    }
  }
  if($ok) {
    print "ok 4\n" if $suffix eq '010';
    print "ok 5\n" if $suffix eq '011';
    print "ok 6\n" if $suffix eq '110';
    print "ok 7\n" if $suffix eq '111';
  }
  else    {
    print "not ok 4\n" if $suffix eq '010';
    print "not ok 5\n" if $suffix eq '011';
    print "not ok 6\n" if $suffix eq '110';
    print "not ok 7\n" if $suffix eq '111';
  }
  $ok = 1;
}

####################################
####################################

for my $suffix('001', '101') {
  for(1..10) {
    my $str = '1.';
    for(1..70) {$str .= int(rand(2));}
    $str .= $suffix;
    my $nstr = '-' . $str;

    my $longrop = Rmpfr_init2(74);
    my $check    = Rmpfr_init2(72);
    my $shortrop = Rmpfr_init2(72);

    my $coderef = \&Rmpfr_set;

    my $inex = Rmpfr_set_str($longrop, $str, 2, MPFR_RNDN);

    if($inex) {die "Rmpfr_set_str falsely returned $inex"}

    my $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

    # $shortrop should always be rounded down, $longrop is exact.

    unless($shortrop < $longrop && $ret < 0) {
      $ok = 0;
      warn "\n gt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
    }

    $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $str, 2);
    unless($shortrop == $check && $ret < 0) {
      $ok = 0;
      warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
    }

    $longrop *= -1;

    $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

    # $shortrop should always be rounded up, $longrop is exact.

    unless($shortrop > $longrop && $ret > 0) {
      $ok = 0;
      warn "\n lt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
    }

    $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $nstr, 2);
    unless($shortrop == $check && $ret > 0) {
      $ok = 0;
      warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
    }
  }
  if($ok) {
    print "ok 8\n" if $suffix eq '001';
    print "ok 9\n" if $suffix eq '101';
  }
  else    {
    print "not ok 8\n" if $suffix eq '001';
    print "not ok 9\n" if $suffix eq '101';
  }
  $ok = 1;
}

####################################
####################################
####################################

for my $suffix('000', '100') {
  for(1..10) {
    my $str = '1.';
    for(1..70) {$str .= int(rand(2));}
    $str .= $suffix;
    my $nstr = '-' . $str;

    my $longrop = Rmpfr_init2(74);
    my $check    = Rmpfr_init2(72);
    my $shortrop = Rmpfr_init2(72);

    my $coderef = \&Rmpfr_set;

    my $inex = Rmpfr_set_str($longrop, $str, 2, MPFR_RNDN);

    if($inex) {die "Rmpfr_set_str falsely returned $inex"}

    my $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

    # No rounding, result is exact.

    unless($shortrop == $longrop && $ret == 0) {
      $ok = 0;
      warn "\n gt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
    }

    $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $str, 2);
    unless($shortrop == $check && $ret == 0) {
      $ok = 0;
      warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
    }

    $longrop *= -1;

    $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

    # No rounding, result is exact

    unless($shortrop == $longrop && $ret == 0) {
      $ok = 0;
      warn "\n lt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
    }

    $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $nstr, 2);
    unless($shortrop == $check && $ret == 0) {
      $ok = 0;
      warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
    }
  }
  if($ok) {
    print "ok 10\n" if $suffix eq '000';
    print "ok 11\n" if $suffix eq '100';
  }
  else    {
    print "not ok 10\n" if $suffix eq '000';
    print "not ok 11\n" if $suffix eq '100';
  }
  $ok = 1;
}

####################################
####################################
####################################
####################################

#Rmpfr_set_emin(Rmpfr_get_emin_min());

$ok = 1;

for(1..10) {
  my $str = '0.1';
  for(1..70) {$str .= int(rand(2));}
  $str .= '01' . '@' . Rmpfr_get_emin();
  my $nstr = '-' . $str;

  my $longrop = Rmpfr_init2(73);
  my $check    = Rmpfr_init2(72);
  my $shortrop = Rmpfr_init2(72);

  my $coderef = \&Rmpfr_set;

  my $inex = Rmpfr_set_str($longrop, $str, 2, MPFR_RNDN);

  if($inex) {die "Rmpfr_set_str falsely returned $inex"}

  my $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded up, $longrop is exact.

  unless($shortrop > $longrop && $ret > 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $str, 2);
  unless($shortrop == $check && $ret > 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
  }

  $longrop *= -1;

  $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded down, $longrop is exact.

  unless($shortrop < $longrop && $ret < 0) {
   $ok = 0;
   warn "\n lt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $nstr, 2);
  unless($shortrop == $check && $ret < 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
  }

}
if($ok) {print "ok 12\n"}
else    {print "not ok 12\n"}
$ok = 1;

for(1..10) {
  my $str = '0.1';
  for(1..70) {$str .= int(rand(2));}
  $str .= '011' . '@' . Rmpfr_get_emin();
  my $nstr = '-' . $str;

  my $longrop = Rmpfr_init2(74);
  my $check    = Rmpfr_init2(72);
  my $shortrop = Rmpfr_init2(72);

  my $coderef = \&Rmpfr_set;

  my $inex = Rmpfr_set_str($longrop, $str, 2, MPFR_RNDN);

  if($inex) {die "Rmpfr_set_str falsely returned $inex"}

  my $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded up, $longrop is exact.

  unless($shortrop > $longrop && $ret > 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $str, 2);
  unless($shortrop == $check && $ret > 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
  }

  $longrop *= -1;

  $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded down, $longrop is exact.

  unless($shortrop < $longrop && $ret < 0) {
   $ok = 0;
   warn "\n lt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $nstr, 2);
  unless($shortrop == $check && $ret < 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret";
  }

}

if($ok) {print "ok 13\n"}
else    {print "not ok 13\n"}
$ok = 1;

for(1..10) {
  my $str = '0.1';
  for(1..70) {$str .= int(rand(2));}
  $str .= '001'  . '@' . Rmpfr_get_emin();
  my $nstr = '-' . $str;

  my $longrop = Rmpfr_init2(74);
  my $check    = Rmpfr_init2(72);
  my $shortrop = Rmpfr_init2(72);

  my $coderef = \&Rmpfr_set;

  my $inex = Rmpfr_set_str($longrop, $str, 2, MPFR_RNDN);

  if($inex) {die "Rmpfr_set_str falsely returned $inex"}

  my $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded down, $longrop is exact.

  unless($shortrop < $longrop && $ret < 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $str, 2);
  unless($shortrop == $check && $ret < 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
  }

  $longrop *= -1;

  $ret = Rmpfr_round_nearest_away($coderef, $shortrop, $longrop);

  # $shortrop should always be rounded up, $longrop is exact.

  unless($shortrop > $longrop && $ret > 0) {
   $ok = 0;
   warn "\n lt: \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  }

  $ret = Rmpfr_round_nearest_away(\&Rmpfr_strtofr, $check, $nstr, 2);
  unless($shortrop == $check && $ret > 0) {
   $ok = 0;
   warn "\n gt: \$shortrop: $shortrop\n \$check: $check\n \$ret: $ret\n";
  }
}

if($ok) {print "ok 14\n"}
else    {print "not ok 14\n"}
$ok = 1;

my $longrop = Rmpfr_init2(73);
my $shortrop = Rmpfr_init2(72);

my $coderef = \&Rmpfr_set;

################

Rmpfr_set_inf($longrop, 1);
my $ret = Rmpfr_round_nearest_away($coderef,$shortrop, $longrop);

if($shortrop == $longrop && $ret == 0) {
  print "ok 15\n";
}
else {
  warn "\n $shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  print "not ok 15\n";
}

################
################

Rmpfr_set_inf($longrop, -1);
$ret = Rmpfr_round_nearest_away($coderef,$shortrop, $longrop);

if($shortrop == $longrop && $ret == 0) {
  print "ok 16\n";
}
else {
  warn "\n \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  print "not ok 16\n";
}

################
################

Rmpfr_set_zero($longrop, 1);
$ret = Rmpfr_round_nearest_away($coderef,$shortrop, $longrop);

if($shortrop == $longrop && $ret == 0) {
  print "ok 17\n";
}
else {
  warn "\n \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  print "not ok 17\n";
}

################
################

Rmpfr_set_zero($longrop, -1);
$ret = Rmpfr_round_nearest_away($coderef,$shortrop, $longrop);

if($shortrop == $longrop && $ret == 0) {
  print "ok 18\n";
}
else {
  warn "\n \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  print "not ok 18\n";
}

################
################

Rmpfr_set_nan($longrop);
$ret = Rmpfr_round_nearest_away($coderef,$shortrop, $longrop);

if(Rmpfr_nan_p($shortrop) && Rmpfr_nan_p($longrop) && $ret == 0) {
  print "ok 19\n";
}
else {
  warn "\n \$shortrop: $shortrop\n \$longrop: $longrop\n \$ret: $ret\n";
  print "not ok 19\n";
}

my $small_1 = Math::MPFR->new(7.5);
my $small_2 = Math::MPFR->new(6.5);

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $small_1, 3);

if($ret > 0 && $small_1 == 8) {print "ok 20\n"}
else {
  warn "\n \$ret: $ret\n \$small_1:$small_1\n";
  print "not ok 20\n";
}

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $small_2, 3);

if($ret > 0 && $small_2 == 7) {print "ok 21\n"}
else {
  warn "\n \$ret: $ret\n \$small_2:$small_2\n";
  print "not ok 21\n";
}

####################################

# Change precision to 53.
Rmpfr_set_prec($small_1, 53);
Rmpfr_set_prec($small_2, 53);

Rmpfr_set_d($small_1, 7.4, MPFR_RNDN);
Rmpfr_set_d($small_2, 6.6, MPFR_RNDN);

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $small_1, 3);

if($ret < 0 && $small_1 == 7) {print "ok 22\n"}
else {
  warn "\n \$ret: $ret\n \$small_1:$small_1\n";
  print "not ok 22\n";
}

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $small_2, 3);

if($ret > 0 && $small_2 == 7) {print "ok 23\n"}
else {
  warn "\n \$ret: $ret\n \$small_2:$small_2\n";
  print "not ok 23\n";
}

####################################

# Change precision to 53.
Rmpfr_set_prec($small_1, 53);
Rmpfr_set_prec($small_2, 53);

Rmpfr_set_d($small_1, 7.5, MPFR_RNDN);
Rmpfr_set_d($small_2, 6.5, MPFR_RNDN);

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $small_1, 4);

if($ret == 0 && $small_1 == 7.5) {print "ok 24\n"}
else {
  warn "\n \$ret: $ret\n \$small_1:$small_1\n";
  print "not ok 24\n";
}

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $small_2, 4);

if($ret == 0 && $small_2 == 6.5) {print "ok 25\n"}
else {
  warn "\n \$ret: $ret\n \$small_2:$small_2\n";
  print "not ok 25\n";
}

####################################

# Change precision to 53.
Rmpfr_set_prec($small_1, 53);
Rmpfr_set_prec($small_2, 53);

Rmpfr_set_d($small_1, 7.25, MPFR_RNDN);
Rmpfr_set_d($small_2, 6.25, MPFR_RNDN);

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $small_1, 3);

if($ret < 0 && $small_1 == 7) {print "ok 26\n"}
else {
  warn "\n \$ret: $ret\n \$small_1:$small_1\n";
  print "not ok 26\n";
}

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $small_2, 3);

if($ret < 0 && $small_2 == 6) {print "ok 27\n"}
else {
  warn "\n \$ret: $ret\n \$small_2:$small_2\n";
  print "not ok 27\n";
}

####################################

# Change precision to 53.
Rmpfr_set_prec($small_1, 53);
Rmpfr_set_prec($small_2, 53);

Rmpfr_set_d($small_1, 7.0, MPFR_RNDN);
Rmpfr_set_d($small_2, 6.0, MPFR_RNDN);

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $small_1, 3);

if($ret == 0 && $small_1 == 7) {print "ok 28\n"}
else {
  warn "\n \$ret: $ret\n \$small_1:$small_1\n";
  print "not ok 28\n";
}

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $small_2, 3);

if($ret == 0 && $small_2 == 6) {print "ok 29\n"}
else {
  warn "\n \$ret: $ret\n \$small_2:$small_2\n";
  print "not ok 29\n";
}

####################################

my $nan  = Rmpfr_init();
my $inf  = Math::MPFR->new(1)  / Math::MPFR->new(0);
my $ninf = Math::MPFR->new(-1) / Math::MPFR->new(0);

####################################

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $nan, 2);

if(Rmpfr_get_prec($nan) == 2 && Rmpfr_nan_p($nan) && $ret == 0) {print "ok 30\n"}
else {
  warn "\n prec: ", Rmpfr_get_prec($nan), "\n \$nan: $nan\n \$ret: $ret\n";
  print "not ok 30\n";
}

####################################

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $inf, 2);

if(Rmpfr_get_prec($inf) == 2 && Rmpfr_inf_p($inf) && $ret == 0 && $inf > 0) {print "ok 31\n"}
else {
  warn "\n prec: ", Rmpfr_get_prec($inf), "\n \$inf: $inf\n \$ret: $ret\n";
  print "not ok 31\n";
}

####################################

$ret = Rmpfr_round_nearest_away(\&Rmpfr_prec_round, $ninf, 2);

if(Rmpfr_get_prec($ninf) == 2 && Rmpfr_inf_p($ninf) && $ret == 0 && $ninf < 0) {print "ok 32\n"}
else {
  warn "\n prec: ", Rmpfr_get_prec($ninf), "\n \$ninf: $ninf\n \$ret: $ret\n";
  print "not ok 32\n";
}

####################################
####################################

my $rop = Rmpfr_init();
my $min = Rmpfr_init();
my $minstring = '0.1@' . Rmpfr_get_emin();
Rmpfr_set_str($min, $minstring, 2, MPFR_RNDN);

my $mul = Math::MPFR->new(2);
Rmpfr_pow_si($mul, $mul, Rmpfr_get_emin(), MPFR_RNDN);

if($mul * 0.5 == $min) {print "ok 33\n"}
else {
  warn "\n $mul * 0.5 != $min\n Ensuing tests may fail\n";
  print "not ok 33\n";
}

print "ok 34\n";

my $inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_d, $rop, $mul, 0.25);

if($inex == 1 && $rop == 0.5 * (Math::MPFR->new(2) ** Rmpfr_get_emin())) {print "ok 35\n"}
else {
  warn "\n \$inex: $inex\n \$rop: $rop\n";
  print "not ok 35\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_d, $rop, $mul, 0.0625);

if($inex == -1 && $rop == 0) {print "ok 36\n"}

else {
  warn "\n \$inex: $inex\n \$rop: $rop\n";
  print "not ok 36\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_d, $rop, $mul, 0.75);

if($inex == 0 && $rop > $min) {print "ok 37\n"}
else {
#  Rmpfr_mul_d($rop, $mul, 0.75, MPFR_RNDA);
  warn "\n \$inex: $inex\n \$rop: $rop\n";
  print "not ok 37\n";
}

################################

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_d, $rop, $mul, -0.5);

if($inex == 0 && abs($rop) == $min) {print "ok 38\n"}
else {
#  Rmpfr_mul_d($rop, $mul, -0.5, MPFR_RNDA);
  warn "\n\$inex: $inex\n \$rop: $rop\n";
  print "not ok 38\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_d, $rop, $mul, -0.25);

if($inex == -1 && abs($rop) == $min) {print "ok 39\n"}
else {
#  Rmpfr_mul_d($rop, $mul, -0.25, MPFR_RNDA);
  warn "\n\$inex: $inex\n \$rop: $rop\n";
  print "not ok 39\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_d, $rop, $mul, -0.0625);

if($inex == 1 && $rop ==0) {print "ok 40\n"}
else {
#  Rmpfr_mul_d($rop, $mul, -0.0625, MPFR_RNDA);
  warn "\n\$inex: $inex\n \$rop: $rop\n";
  print "not ok 40\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_d, $rop, $mul, -0.75);

if($inex == 0 && $rop < $min * -1) {print "ok 41\n"}
else {
#  Rmpfr_mul_d($rop, $mul, -0.75, MPFR_RNDA);
  warn "\n\$inex: $inex\n \$rop: $rop\n";
  print "not ok 41\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_d, $rop, $mul, -0.0);

if($inex == 0 && $rop == 0 && Rmpfr_signbit($rop)) {print "ok 42\n"}
else {
#  Rmpfr_mul_d($rop, $mul, -0.0, MPFR_RNDA);
  warn "\n\$inex: $inex\n \$rop: $rop\n sign: ", Rmpfr_sgn($rop), "\n";
  print "not ok 42\n";
}

Rmpfr_set_default_prec(41);

my $ps = Math::MPFR->new();
my $ns = Math::MPFR->new();

$ok = 1;

for(1..100) {
  my $str = int(rand(2));
  my $str_check = $str;
  for(1..40) {$str .= int(rand(2))}
  my $str_keep = $str;
  $str_check = substr($str, -1, 1) if $str_check;
  my $mul = int(rand(2)) == 0 ? 1 : -1;
  my $exponent = int(rand(100));
  $exponent *= $mul;
  $str .= '@' . $exponent;
  Rmpfr_set_str($ps, $str, 2, MPFR_RNDN);
  Rmpfr_neg($ns, $ps, MPFR_RNDN);
  my $lsb = Math::MPFR::_lsb($ps);

  if(Math::MPFR::_lsb($ns) != $lsb) {$ok = 2}

  if(substr($str, 0, 1) eq '0' && "$lsb" ne '0') {
    $ok = 3;
  }

  if(substr($str_keep, 0, 1) eq '1' && substr($str_keep, -1, 1) eq '1' && "$lsb" ne '1') {
    warn "\n \$str_keep: $str_keep\n \$lsb: $lsb\n";
    $ok = 4;
  }

  if($lsb != $str_check) {$ok = 0}
}

if($ok == 1) {print "ok 43\n"}
else {
  warn "\n \$ok: $ok\n";
  print "not ok 43\n";
}

$ok = 1;

Rmpfr_set_default_prec(67);

my $ps2 = Math::MPFR->new();
my $ns2 = Math::MPFR->new();

for(1..100) {
  my $str = int(rand(2));
  my $str_check = $str;
  for(1..66) {$str .= int(rand(2))}
  my $str_keep = $str;
  $str_check = substr($str, -1, 1) if $str_check;
  my $mul = int(rand(2)) == 0 ? 1 : -1;
  my $exponent = int(rand(1000));
  $exponent *= $mul;
  $str .= '@' . $exponent;
  Rmpfr_set_str($ps2, $str, 2, MPFR_RNDN);
  Rmpfr_neg($ns2, $ps2, MPFR_RNDN);
  my $lsb = Math::MPFR::_lsb($ps2);

  if(Math::MPFR::_lsb($ns2) != $lsb) {$ok = 2}

  if(substr($str, 0, 1) eq '0' && "$lsb" ne '0') {
    $ok = 3;
  }

  if(substr($str_keep, 0, 1) eq '1' && substr($str_keep, -1, 1) eq '1' && "$lsb" ne '1') {
    warn "\n \$str_keep: $str_keep\n \$lsb: $lsb\n";
    $ok = 4;
  }

  if($lsb != $str_check) {$ok = 0}
}

if($ok == 1) {print "ok 44\n"}
else {
  warn "\n \$ok: $ok\n";
  print "not ok 44\n";
}

$ok = 1;

if(Math::MPFR::_lsb(Math::MPFR->new()) == 0) {print "ok 45\n"}
else {
  warn "\n ", Math::MPFR::_lsb(Math::MPFR->new()), "\n";
  print "not ok 45\n";
}

if(Math::MPFR::_lsb(Math::MPFR->new(1) / Math::MPFR->new(0)) == 0) {print "ok 46\n"}
else {
  warn "\n ", Math::MPFR::_lsb(Math::MPFR->new(1) / Math::MPFR->new(0)), "\n";
  print "not ok 46\n";
}

if(Math::MPFR::_lsb(Math::MPFR->new(-1) / Math::MPFR->new(0)) == 0) {print "ok 47\n"}
else {
  warn "\n ", Math::MPFR::_lsb(Math::MPFR->new(-1) / Math::MPFR->new(0)), "\n";
  print "not ok 47\n";
}

if(Math::MPFR::_lsb(Math::MPFR->new(0)) == 0) {print "ok 48\n"}
else {
  warn "\n ", Math::MPFR::_lsb(Math::MPFR->new(0)), "\n";
  print "not ok 48\n";
}

my $prop = Rmpfr_init2(5);
my $op = Math::MPFR->new(30.5);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_abs, $prop, $op);
if($inex > 0 && $prop == 31) {print "ok 49\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 49\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_abs, $prop, $op * -1);
if($inex > 0 && $prop == 31) {print "ok 50\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 50\n";
}

Rmpfr_set_d($op, 29.5, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_add, $prop, $op, Math::MPFR->new(1));
if($inex > 0 && $prop == 31) {print "ok 51\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 51\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_add, $prop, $op * -1, Math::MPFR->new(-1));
if($inex < 0 && $prop == -31) {print "ok 52\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 52\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_add_d, $prop, $op, 1.0);
if($inex > 0 && $prop == 31) {print "ok 53\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 53\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_add_d, $prop, $op * -1, -1.0);
if($inex < 0 && $prop == -31) {print "ok 54\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 54\n";
}

if($have_gmpq) {

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_add_q, $prop, $op, Math::GMPq->new(1.0));
  if($inex > 0 && $prop == 31) {print "ok 55\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 55\n";
  }

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_add_q, $prop, $op * -1, Math::GMPq->new(-1.0));
  if($inex < 0 && $prop == -31) {print "ok 56\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 56\n";
  }
}
else {
 warn "\n Skipping tests 55 & 56\n as Math::GMPq failed to load\n";
 print "ok 55\n";
 print "ok 56\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_add_si, $prop, $op, 1);
if($inex > 0 && $prop == 31) {print "ok 57\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 57\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_add_si, $prop, $op * -1, -1);
if($inex < 0 && $prop == -31) {print "ok 58\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 58\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_add_ui, $prop, $op, 1);
if($inex > 0 && $prop == 31) {print "ok 59\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 59\n";
}

if($have_gmpz) {

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_add_z, $prop, $op, Math::GMPz->new(1.0));
  if($inex > 0 && $prop == 31) {print "ok 60\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 60\n";
  }

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_add_z, $prop, $op * -1, Math::GMPz->new(-1.0));
  if($inex < 0 && $prop == -31) {print "ok 61\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 61\n";
  }
}
else {
 warn "\n Skipping tests 60 & 61\n as Math::GMPz failed to load\n";
 print "ok 60\n";
 print "ok 61\n";
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

Rmpfr_set_d($op, 15.25, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul, $prop, $op, Math::MPFR->new(2));
if($inex > 0 && $prop == 31) {print "ok 62\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 62\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul, $prop, $op * -1, Math::MPFR->new(2));
if($inex < 0 && $prop == -31) {print "ok 63\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 63\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_d, $prop, $op, 2.0);
if($inex > 0 && $prop == 31) {print "ok 64\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 64\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_d, $prop, $op * -1, 2.0);
if($inex < 0 && $prop == -31) {print "ok 65\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 65\n";
}

if($have_gmpq) {

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_q, $prop, $op, Math::GMPq->new(2.0));
  if($inex > 0 && $prop == 31) {print "ok 66\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 66\n";
  }

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_q, $prop, $op * -1, Math::GMPq->new(2.0));
  if($inex < 0 && $prop == -31) {print "ok 67\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 67\n";
  }
}
else {
 warn "\n Skipping tests 66 & 67\n as Math::GMPq failed to load\n";
 print "ok 66\n";
 print "ok 67\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_si, $prop, $op, 2);
if($inex > 0 && $prop == 31) {print "ok 68\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 68\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_si, $prop, $op, -2);
if($inex < 0 && $prop == -31) {print "ok 69\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 69\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_ui, $prop, $op, 2);
if($inex > 0 && $prop == 31) {print "ok 70\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 70\n";
}

if($have_gmpz) {

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_z, $prop, $op, Math::GMPz->new(2.0));
  if($inex > 0 && $prop == 31) {print "ok 71\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 71\n";
  }

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_mul_z, $prop, $op * -1, Math::GMPz->new(2.0));
  if($inex < 0 && $prop == -31) {print "ok 72\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 72\n";
  }
}
else {
 warn "\n Skipping tests 71 & 72\n as Math::GMPz failed to load\n";
 print "ok 71\n";
 print "ok 72\n";
}
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

my $sqr = Rmpfr_init2(4);
$inex = Rmpfr_set_d($sqr, 2.5, MPFR_RNDN);

if(!$inex) {print "ok 73\n"}
else {
  warn "\n \$inex: $inex\n";
  print "not ok 73\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sqr, $sqr, $sqr);

if($inex > 0 && $sqr == 6.5) {print "ok 74\n"}
else {
  warn "\n \$inex: $inex\n \$sqr: $sqr\n";
  print "not ok 74\n";
}

Rmpfr_set_d($sqr, 2.5, MPFR_RNDN);

$inex = Rmpfr_sqr($sqr, $sqr, MPFR_RNDN);

if($inex < 0 && $sqr == 6) {print "ok 75\n"}
else {
  warn "\n \$inex: $inex\n \$sqr: $sqr\n";
  print "not ok 75\n";
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

Rmpfr_set_d($op, 91.5, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_div, $prop, $op, Math::MPFR->new(3));
if($inex > 0 && $prop == 31) {print "ok 76\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 76\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_div, $prop, $op * -1, Math::MPFR->new(3));
if($inex < 0 && $prop == -31) {print "ok 77\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 77\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_div_d, $prop, $op, 3.0);
if($inex > 0 && $prop == 31) {print "ok 78\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 78\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_div_d, $prop, $op * -1, 3.0);
if($inex < 0 && $prop == -31) {print "ok 79\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 79\n";
}

if($have_gmpq) {

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_div_q, $prop, $op, Math::GMPq->new(3.0));
  if($inex > 0 && $prop == 31) {print "ok 80\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 80\n";
  }

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_div_q, $prop, $op * -1, Math::GMPq->new(3.0));
  if($inex < 0 && $prop == -31) {print "ok 81\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 81\n";
  }
}
else {
 warn "\n Skipping tests 80 && 81\n as Math::GMPq failed to load\n";
 print "ok 80\n";
 print "ok 81\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_div_si, $prop, $op, 3);
if($inex > 0 && $prop == 31) {print "ok 82\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 82\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_div_si, $prop, $op, -3);
if($inex < 0 && $prop == -31) {print "ok 83\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 83\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_div_ui, $prop, $op, 3);
if($inex > 0 && $prop == 31) {print "ok 84\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 84\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_div_ui, $prop, $op * -1, 3);
if($inex < 0 && $prop == -31) {print "ok 85\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 85\n";
}

if($have_gmpz) {

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_div_z, $prop, $op, Math::GMPz->new(3.0));
  if($inex > 0 && $prop == 31) {print "ok 86\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 86\n";
  }

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_div_z, $prop, $op * -1, Math::GMPz->new(3.0));
  if($inex < 0 && $prop == -31) {print "ok 87\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 87\n";
  }
}
else {
 warn "\n Skipping tests 86 & 87\n as Math::GMPz failed to load\n";
 print "ok 86\n";
 print "ok 87\n";
}

Rmpfr_set_d($op, 6.0, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_ui_div, $prop, 183, $op);
if($inex > 0 && $prop == 31) {print "ok 88\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 88\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_ui_div, $prop, 183, $op * -1);
if($inex < 0 && $prop == -31) {print "ok 89\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 89\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_si_div, $prop, 183, $op);
if($inex > 0 && $prop == 31) {print "ok 90\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 90\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_si_div, $prop, -183, $op);
if($inex < 0 && $prop == -31) {print "ok 91\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 91\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_d_div, $prop, 183.0, $op);
if($inex > 0 && $prop == 31) {print "ok 92\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 92\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_d_div, $prop, -183.0, $op);
if($inex < 0 && $prop == -31) {print "ok 93\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 93\n";
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

Rmpfr_set_d($prop, 1.5, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_add, $prop, $prop, Math::MPFR->new(29));
if($inex > 0 && $prop == 31) {print "ok 94\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 94\n";
}

Rmpfr_set_d($prop, 1.5, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_add, $prop, $prop * -1, Math::MPFR->new(-29));
if($inex < 0 && $prop == -31) {print "ok 95\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 95\n";
}

Rmpfr_set_d($prop, 2.0, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul, $prop, $prop, Math::MPFR->new(15.25));
if($inex > 0 && $prop == 31) {print "ok 96\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 96\n";
}

Rmpfr_set_d($prop, 2.0, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_mul, $prop, $prop, Math::MPFR->new(-15.25));
if($inex < 0 && $prop == -31) {print "ok 97\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 97\n";
}

Rmpfr_set_d($prop, 1.5, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sub, $prop, $prop, Math::MPFR->new(-29));
if($inex > 0 && $prop == 31) {print "ok 98\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 98\n";
}

Rmpfr_set_d($prop, 1.5, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sub, $prop, $prop, Math::MPFR->new(32));
if($inex < 0 && $prop == -31) {print "ok 99\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 99\n";
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

Rmpfr_set_d($op, 1.5, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sub, $prop, $op, Math::MPFR->new(-29));
if($inex > 0 && $prop == 31) {print "ok 100\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 100\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sub, $prop, $op * -1, Math::MPFR->new(29));
if($inex < 0 && $prop == -31) {print "ok 101\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 101\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sub_d, $prop, $op, -29.0);
if($inex > 0 && $prop == 31) {print "ok 102\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 102\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sub_d, $prop, $op * -1, 29.0);
if($inex < 0 && $prop == -31) {print "ok 103\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 103\n";
}

if($have_gmpq) {

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_sub_q, $prop, $op, Math::GMPq->new(-29));
  if($inex > 0 && $prop == 31) {print "ok 104\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 104\n";
  }

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_sub_q, $prop, $op * -1, Math::GMPq->new(29));
  if($inex < 0 && $prop == -31) {print "ok 105\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 105\n";
  }
}
else {
 warn "\n Skipping tests 104 & 105\n as Math::GMPq failed to load\n";
 print "ok 104\n";
 print "ok 105\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sub_si, $prop, $op, -29);
if($inex > 0 && $prop == 31) {print "ok 106\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 106\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sub_si, $prop, $op * -1, 29);
if($inex < 0 && $prop == -31) {print "ok 107\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 107\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sub_ui, $prop, $op * -1, 29);
if($inex < 0 && $prop == -31) {print "ok 108\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 108\n";
}

if($have_gmpz) {

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_sub_z, $prop, $op, Math::GMPz->new(-29));
  if($inex > 0 && $prop == 31) {print "ok 109\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 109\n";
  }

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_sub_z, $prop, $op * -1, Math::GMPz->new(29));
  if($inex < 0 && $prop == -31) {print "ok 110\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 110\n";
  }

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_z_sub, $prop, Math::GMPz->new(-29), $op);
  if($inex < 0 && $prop == -31) {print "ok 111\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 111\n";
  }
}
else {
 warn "\n Skipping tests 109, 110 & 111\n as Math::GMPz failed to load\n";
 print "ok 109\n";
 print "ok 110\n";
 print "ok 111\n";
}

Rmpfr_set_d($op, 29.5, MPFR_RNDN);

$inex = Rmpfr_round_nearest_away(\&Rmpfr_ui_sub, $prop, 60, $op);
if($inex > 0 && $prop == 31) {print "ok 112\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 112\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_si_sub, $prop, 60, $op);
if($inex > 0 && $prop == 31) {print "ok 113\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 113\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_si_sub, $prop, -60, $op * -1);
if($inex < 0 && $prop == -31) {print "ok 114\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 114\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_d_sub, $prop, 60.0, $op);
if($inex > 0 && $prop == 31) {print "ok 115\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 115\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_d_sub, $prop, -60.0, $op * -1);
if($inex < 0 && $prop == -31) {print "ok 116\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 116\n";
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

$inex = Rmpfr_round_nearest_away(\&Rmpfr_fac_ui, $prop, 6);

if($inex > 0 && $prop == 736) {print "ok 117\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 117\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sqrt, $prop, Math::MPFR->new(2025));

if($inex > 0 && $prop == 46) {print "ok 118\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 118\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_sqrt_ui, $prop, 2025);

if($inex > 0 && $prop == 46) {print "ok 119\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 119\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_root, $prop, Math::MPFR->new(2025), 2);

if($inex > 0 && $prop == 46) {print "ok 120\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 120\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_cbrt, $prop, Math::MPFR->new(91125));

if($inex > 0 && $prop == 46) {print "ok 121\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 121\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_set_ui, $prop, 45);

if($inex > 0 && $prop == 46) {print "ok 122\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 122\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_set_si, $prop, -45);

if($inex < 0 && $prop == -46) {print "ok 123\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 123\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_set_d, $prop, 45.0);

if($inex > 0 && $prop == 46) {print "ok 124\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 124\n";
}

if($Config{nvtype} eq '__float128' && Math::MPFR::_can_pass_float128()) {

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_set_float128, $prop, 45.0);

  if($inex > 0 && $prop == 46) {print "ok 125\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 125\n";
  }

}
else {
   warn "Skipping test 125 - __float128 not supported\n";
   print "ok 125\n";
}

if($Config{nvsize} > 8) { # Rmpfr_set_ld is unavailable when nvsize <= 8 (even if nvtype is 'long double').

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_set_ld, $prop, 45.0);

  if($inex > 0 && $prop == 46) {print "ok 126\n"}
  else {
    warn "\n \$inex: $inex\n \$prop: $prop\n";
    print "not ok 126\n";
  }

}
else {
   warn "Skipping test 126 - long double not supported\n";
   print "ok 126\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_ui_pow, $prop, 2025, Math::MPFR->new(0.5));

if($inex > 0 && $prop == 46) {print "ok 127\n"}
else {
  warn "\n \$inex: $inex\n \$prop: $prop\n";
  print "not ok 127\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_pow_si, $sqr, Math::MPFR->new(2.5), 2);

if($inex > 0 && $sqr == 6.5) {print "ok 128\n"}
else {
  warn "\n \$inex: $inex\n \$sqr: $sqr\n";
  print "not ok 128\n";
}

$inex = Rmpfr_round_nearest_away(\&Rmpfr_pow_ui, $sqr, Math::MPFR->new(2.5), 2);

if($inex > 0 && $sqr == 6.5) {print "ok 129\n"}
else {
  warn "\n \$inex: $inex\n \$sqr: $sqr\n";
  print "not ok 129\n";
}

if($have_gmpz) {

  $inex = Rmpfr_round_nearest_away(\&Rmpfr_pow_z, $sqr, Math::MPFR->new(2.5), Math::GMPz->new(2));

  if($inex > 0 && $sqr == 6.5) {print "ok 130\n"}
  else {
    warn "\n \$inex: $inex\n \$sqr: $sqr\n";
    print "not ok 130\n";
  }
}
else {
  warn "\n  Skipping test 130\n as Math::GMPz failed to load\n";
  print "ok 130\n";
}


__END__
