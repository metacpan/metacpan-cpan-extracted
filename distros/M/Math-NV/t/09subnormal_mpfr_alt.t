
# Smallest normal __float128 is:
# 3.3621031431120935062626778173217526e-4932

# Smallest normal (extended precision) long double is:
# 3.36210314311209350626e-4932

# Smallest normal double is:
# 2.2250738585072014e-308

use strict;
use warnings;
use Math::NV qw(:all);
use Config;

my ($have_atonv);

$have_atonv = Math::MPFR::MPFR_VERSION() <= 196869 ? 0 : 1;

if($have_atonv) {
  warn "\n Math::MPFR::atonv() tests enabled\n";
}
else {  warn "\n Math::MPFR::atonv() tests disabled\n"}


my $t = 9;

print "1..$t\n";

my $ok = 1;
my $exponent;

if($Math::NV::mpfr_strtofr_bug == 1) {
  warn "Skipping tests - already run  in 08subnormal_mpfr.t\n";
  print "ok $_\n" for 1..$t;
  exit 0;
}

$Math::NV::mpfr_strtofr_bug = 1; # Force use of workaround routine.

warn "\nThese tests can take a few moments to complete\n";

my($have_ld_bytes, $no_ld_bytes) = (0, '');

# The following eval{} evokes "You probably want to call Math::MPFR::_dd_bytes"
# warning on double-double builds, before setting $@ to "2nd arg to
# Math::MPFR::_ld_bytes must be 64 or 113".

eval{Math::MPFR::_ld_bytes('1e-2', Math::MPFR::LDBL_MANT_DIG)};
unless($@) {
  $have_ld_bytes = 1;
}
else {$no_ld_bytes = $@}

my($have_f128_bytes, $no_f128_bytes) = (0, '');
eval{Math::MPFR::_f128_bytes('1e-2', 113)};
unless($@) {
  $have_f128_bytes = 1;
}
else {$no_f128_bytes = $@}


my $check = Math::MPFR::Rmpfr_init2(300);

$exponent = $Config{nvtype} eq 'double' ? '-308' : '-4932';

########### Test 1 starts

# Set $str to $check (500 bits of precision)
# Check that the NV ($nv) retrieved from $check
# is the same as the NV returned by set_mpfr($str)
# and check that set_mpfr() and Math::MPFR::atonv()
# return the same value.
# Check also that that the hex dump of $nv
# matches the hex dump returned by nv_mpfr($str)

unless($Math::NV::_ld_subnormal_bug && $Config{nvtype} eq 'long double') {
  for my $count(1 .. 10000, 200000 .. 340000) {

    my $str = sprintf "%06d", $count;
    substr($str, 1, 0, '.');
    $str .= "e$exponent";

    Math::MPFR::Rmpfr_set_str($check, $str, 10, 0);
    my $nv = Math::MPFR::Rmpfr_get_NV($check, 0);

    my $set = set_mpfr($str);

    if($nv != $set) {
      warn "\n$nv != $set for $str\n";
      if($] >= '5.022') {
        warn "The former is: ", sprintf("%a\n", $nv);
        warn "The latter is: ", sprintf "%a\n", set_mpfr($str);
      }
      $ok = 0;
      last;
    }

    if($have_atonv) {
      if($set != Math::MPFR::atonv($str)) {
        warn "\n$set != ", Math::MPFR::atonv($str), " for $str\n";
        if($] >= '5.022') {
          warn "The former is: ", sprintf("%a\n", $set);
          warn "The latter is: ", sprintf "%a\n", Math::MPFR::atonv($str);
        }
        $ok = 0;
        last;
      }
    }

    my $out1 = scalar(reverse(unpack("h*", pack("F<", $nv))));

    my $out2;
    my $out = nv_mpfr($str);
    if(mant_dig() == 106) { # If NV is a double-double
      my @t = @$out;
      $out2 = $t[0] . $t[1];
    }
    else {$out2 = $out}

    unless($out1 eq $out2) {
      warn "For $str:\n $out1 ne $out2\n";
      if($] >= '5.022') {
        warn "The former is: ", sprintf("%a\n", $nv), sprintf("%.16e\n", $nv);
        warn "The latter is: ", sprintf "%a\n", unpack("F<", pack "h*", scalar reverse $out2);
      }
      $ok = 0;
     last;
    }
  }
}
else {
  warn "\n Skipping test 1 - Your version of mpfr (", Math::MPFR::MPFR_VERSION_STRING(), ")",
       "\n is buggy wrt mpfr_get_ld() and subnormal values.\n",
       " Consider upgrading mpfr to at least version 3.1.5\n";
}


$Math::NV::no_warn = 2;

if($ok) {print "ok 1\n"}
else {print "not ok 1\n"}

$ok = 1;

########### Test 1 ends
########### Test 2 starts

# Check that whenever perl and nv_mpfr() assign
# different values for a particular $str, then
# is_eq_mpfr($str) returns false.
# Check also that whenever perl and nv_mpfr()
# assign the same value for a particular $str,
# then is_eq_mpfr($str) returns true.
# So long as these conditions hold, we can be
# confident that is_eq_mpfr($str) assigns the
# same value as nv_mpfr($str)

unless($Math::NV::_ld_subnormal_bug && $Config{nvtype} eq 'long double') {
  for my $count(1 .. 10000, 200000 .. 340000) {

    my $str = sprintf "%06d", $count;
    substr($str, 1, 0, '.');
    $str .= "e$exponent";

    my $str_copy = $str;
    my $perl_nv = $str_copy + 0;
    my $out;

    if(mant_dig() == 106) { # If NV is a double-double
      my $ret = nv_mpfr($str);
      my @t = @$ret;
      my $s = $t[0] . $t[1];
      $out = unpack("F<", pack "h*", scalar reverse $s);
    }
    else { $out = unpack("F<", pack "h*", scalar reverse nv_mpfr($str));}

    if($out == $perl_nv && !is_eq_mpfr($str)) {
      warn "For $str:\nperl and nv_mpfr() agree, but is_eq_mpfr($str) returns false\n";
      if($] >= '5.022') {
        warn "Perl says that $str evaluates to: ", sprintf "%a\n", $perl_nv;
        warn "nv_mpfr() says that $str evaluates to: ", sprintf "%a\n", $out;
      }
      $ok = 0;
      last;
    }

    if($out != $perl_nv  && is_eq_mpfr($str)) {
      warn "For $str:\nperl and nv_mpfr() disagree, but is_eq_mpfr($str) returns true\n";
      if($] >= '5.022') {
        warn "Perl says that $str evaluates to: ", sprintf "%a\n", $perl_nv;
        warn "nv_mpfr() says that $str evaluates to: ", sprintf "%a\n", $out;
      }
      $ok = 0;
      last;
    }
  }
}
else {
  warn "\n Skipping test 2 - Your version of mpfr (", Math::MPFR::MPFR_VERSION_STRING(), ")",
       "\n is buggy wrt mpfr_get_ld() and subnormal values.\n",
       " Consider upgrading mpfr to at least version 3.1.5\n";
}

if($ok) {print "ok 2\n"}
else {print "not ok 2\n"}

$ok = 1;

########### Test 2 ends
########### Test 3 starts

# Check that nv_mpfr($str) calculates exactly
# the same value for double and double-double
# whenever $str represents a subnormal double
# value. If $Config{nvtype} is 'double', then
# nv_mpfr($str, 53) uses only the Math::NV
# code for the calculation.
# Otherwise Math::MPFR::_d_bytes() is called
# upon.

for my $count(1 .. 10000, 150000 .. 222507) {

  my $exp =  308 + int(rand(16));

  my $str = sprintf "%06d", $count;
  substr($str, 1, 0, '.');
  $str .= "e-$exp";

  my $out1 = nv_mpfr($str, 53);
  my $out2 = nv_mpfr($str, 106);

  my @out = @$out2;

  if($out1 ne $out[0]) {
    warn "$out1 ne $out[0]\n";
    $ok = 0;
    last;
  }

  my $lsd = unpack("d<", pack "h*", scalar reverse $out[1]);

  unless($lsd == 0) {
    warn "\n$str: lsd ($out[1]) is not 0\n";
    $ok = 0;
    last;
  }
}

if($ok) {print "ok 3\n"}
else {print "not ok 3\n"}

$ok = 1;

########### Test 3 ends
########### Test 4 starts

# Checks Math::MPFR::_dd_bytes($str, 106)
# against nv_mpfr($str, 106)

for my $count(1 .. 10000, 200000 .. 340000) {

  my $str = sprintf "%06d", $count;
  substr($str, 1, 0, '.');
  $str .= "e-308";

  my $out_a = nv_mpfr($str, 106);
  my $out_b = join '', Math::MPFR::_dd_bytes($str, 106);

  my @out1 = @$out_a;
  my @out2 = (substr($out_b, 0, 16), substr($out_b, 16, 16));

  if($out1[0] ne $out2[0]) {
    warn "msd: $out1[0] ne $out2[0]\n";
    $ok = 0;
    last;
  }

  if($out1[1] ne $out2[1]) {
    warn "lsd: $out1[1] ne $out2[1]\n";
    $ok = 0;
    last;
  }
}

if($ok) {print "ok 4\n"}
else {print "not ok 4\n"}

$ok = 1;

########### Test 4 ends
########### Test 5 starts

# Checks that a few select subnormals (and smaller)
# are evaluated correctly by set_mpfr(), nv_mpfr()
# and Math::MPFR::atonv();
# Specifically, these values are either 0, 1, 2 or 3
# bit subnormals

my $save_prec = Math::MPFR::Rmpfr_get_default_prec();

#####################
### 113-bit float ###
#####################

if(mant_dig() == 113) {
  Math::MPFR::Rmpfr_set_default_prec(113);
  my @str1 = ('0b0.1e-16494', '0b0.111111e-16494', '-0b0.1e-16494', '-0b0.111111e-16494',
              '6.47e-4966', '-6.47e-4966', '6.48e-4966', '-6.48e-4966',
              '0b0.1e-16493', '0b0.101e-16493', '0b0.11e-16493', '-0b0.11e-16493',
              '0b0.11e-16492','0b0.1101e-16492', '0b0.111e-16492',
              '0b0.101e-16491', '0b0.10101e-16491', '0b0.1011e-16491', '0b0.11101e-16491', '0b0.1101e-16491', '0b0.1111e-16491',);

  my @str2 = ('0', '0b0.1e-16493', '-0.0', '-0b0.1e-16493',
              '0b0.1e-16493', '-0b0.1e-16493', '0b0.1e-16493', '-0b0.1e-16493',
              '0b0.1e-16493', '0b0.1e-16493', '0b0.1e-16492', '-0b0.1e-16492',
              '0b0.11e-16492', '0b0.11e-16492', '0b0.10e-16491',
              '0b0.101e-16491','0b0.101e-16491', '0b0.110e-16491', '0b0.111e-16491', '0b0.11e-16491', '0b0.1e-16490');

  my $len = scalar(@str1);
  die "size mismatch" if @str1 != @str2;

  for(my $i = 0; $i < $len; $i++) {
    if(set_mpfr($str1[$i]) != set_mpfr($str2[$i])) {
      warn "\nIn set_mpfr(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": $str1[$i] != $str2[$i]\n";
      $ok = 0;
    }
  }

  if($have_atonv) {
    for(my $i = 0; $i < $len; $i++) {
      if(Math::MPFR::atonv($str1[$i]) != Math::MPFR::atonv($str2[$i])) {
        warn "\nIn Math::MPFR::atonv(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": $str1[$i] != $str2[$i]\n";
        $ok = 0;
      }
    }
  }

  for(my $i = 0; $i < $len; $i++) {
    if(nv_mpfr($str1[$i]) ne nv_mpfr($str2[$i])) {
      warn "\nIn nv_mpfr(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": $str1[$i] ne $str2[$i]\n";
      $ok = 0;
    }
  }

}

#####################
### 64-bit float  ###
#####################

elsif(mant_dig() == 64) {
  Math::MPFR::Rmpfr_set_default_prec(64);
  my @str1 = ('0b0.1e-16445', '0b0.100001e-16445', '-0b0.1e-16445', '-0b0.100001e-16445',
              '3.64e-4951', '-3.64e-4951', '3.65e-4951', '-3.65e-4951',
              '0b0.1e-16444', '0b0.101e-16444', '0b0.11e-16444', '-0b0.11e-16444',
              '0b0.11e-16443','0b0.1101e-16443', '0b0.111e-16443',
              '0b0.101e-16442', '0b0.10101e-16442', '0b0.1011e-16442', '0b0.11101e-16442', '0b0.1101e-16442', '0b0.1111e-16442',);

  my @str2 = ('0', '0b0.1e-16444', '-0.0', '-0b0.1e-16444',
              '0b0.1e-16444', '-0b0.1e-16444', '0b0.1e-16444', '-0b0.1e-16444',
              '0b0.1e-16444', '0b0.1e-16444', '0b0.1e-16443', '-0b0.1e-16443',
              '0b0.11e-16443', '0b0.11e-16443', '0b0.10e-16442',
              '0b0.101e-16442','0b0.101e-16442', '0b0.110e-16442', '0b0.111e-16442', '0b0.11e-16442', '0b0.1e-16441');

  my $len = scalar(@str1);
  die "size mismatch" if @str1 != @str2;

  if(!$Math::NV::_ld_subnormal_bug) {
    for(my $i = 0; $i < $len; $i++) {
      if(set_mpfr($str1[$i]) != set_mpfr($str2[$i])) {
        warn "\nIn set_mpfr(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": $str1[$i] != $str2[$i]\n";
        $ok = 0;
      }
    }

  if($have_atonv) {
    for(my $i = 0; $i < $len; $i++) {
      if(Math::MPFR::atonv($str1[$i]) != Math::MPFR::atonv($str2[$i])) {
        warn "\nIn Math::MPFR::atonv(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": $str1[$i] != $str2[$i]\n";
        $ok = 0;
      }
    }
  }

    for(my $i = 0; $i < $len; $i++) {
      if(nv_mpfr($str1[$i]) ne nv_mpfr($str2[$i])) {
        warn "\nIn nv_mpfr(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": $str1[$i] ne $str2[$i]\n";
        $ok = 0;
      }
    }
  }
  else {
    warn "\n Skipping test 5 - Your version of mpfr (", Math::MPFR::MPFR_VERSION_STRING(), ")",
         "\n is buggy wrt mpfr_get_ld() and subnormal values.\n",
         " Consider upgrading mpfr to at least version 3.1.5\n";
  }
}

#####################
### 53-bit float  ###
#####################

elsif(mant_dig() == 53) {
  Math::MPFR::Rmpfr_set_default_prec(53);
  my @str1 = ('0b0.1e-1074', '0b0.100001e-1074', '-0b0.1e-1074', '-0b0.100001e-1074',
              '4.94e-324', '-4.94e-324', '4.941e-324', '-4.941e-324',
              '0b0.1e-1073', '0b0.101e-1073', '0b0.11e-1073', '-0b0.11e-1073',
              '0b0.11e-1072','0b0.1101e-1072', '0b0.111e-1072',
              '0b0.101e-1071', '0b0.10101e-1071', '0b0.1011e-1071', '0b0.11101e-1071', '0b0.1101e-1071', '0b0.1111e-1071',);

  my @str2 = ('0', '0b0.1e-1073', '-0.0', '-0b0.1e-1073',
              '0b0.1e-1073', '-0b0.1e-1073', '0b0.1e-1073', '-0b0.1e-1073',
              '0b0.1e-1073', '0b0.1e-1073', '0b0.1e-1072', '-0b0.1e-1072',
              '0b0.11e-1072', '0b0.11e-1072', '0b0.10e-1071',
              '0b0.101e-1071','0b0.101e-1071', '0b0.110e-1071', '0b0.111e-1071', '0b0.11e-1071', '0b0.1e-1070');

  my $len = scalar(@str1);
  die "size mismatch" if @str1 != @str2;

  for(my $i = 0; $i < $len; $i++) {

    if(set_mpfr($str1[$i]) != set_mpfr($str2[$i])) {
      warn "\nIn set_mpfr(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": $str1[$i] != $str2[$i]\n";
      $ok = 0;
    }
  }

  for(my $i = 0; $i < $len; $i++) {
    if(nv_mpfr($str1[$i]) ne nv_mpfr($str2[$i])) {
      warn "\nIn nv_mpfr(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": $str1[$i] ne $str2[$i]\n";
      $ok = 0;
    }
  }

  if($have_atonv) {
    for(my $i = 0; $i < $len; $i++) {
      if(Math::MPFR::atonv($str1[$i]) != Math::MPFR::atonv($str2[$i])) {
        warn "\nIn Math::MPFR::atonv(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": $str1[$i] != $str2[$i]\n";
        $ok = 0;
      }
    }
  }

  for(my $i = 0; $i < $len; $i++) {
    my $x = nv_mpfr($str1[$i]);
    my $arref = nv_mpfr($str2[$i], 106);
    if($x ne $$arref[0] || $$arref[1] =~ /[^0]/ ) {
      warn "\nTesting _dd_bytes(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": Got $x and @$arref for $str1[$i] and $str2[$i]\n";
      $ok = 0;
    }
  }


}

#####################
### 106-bit float ###
#####################

else { # double-double
  my @str1 = ('0b0.1e-1074', '0b0.111111e-1074', '-0b0.1e-1074', '-0b0.100001e-1074',
              '4.94e-324', '-4.94e-324', '4.941e-324', '-4.941e-324',
              '0b0.1e-1073', '0b0.101e-1073', '0b0.11e-1073', '-0b0.11e-1073',
              '0b0.11e-1072','0b0.1101e-1072', '0b0.111e-1072',
              '0b0.101e-1071', '0b0.10101e-1071', '0b0.1011e-1071', '0b0.11101e-1071', '0b0.1101e-1071', '0b0.1111e-1071',);

  my @str2 = ('0', '0b0.1e-1073', '-0.0', '-0b0.1e-1073',
              '0b0.1e-1073', '-0b0.1e-1073', '0b0.1e-1073', '-0b0.1e-1073',
              '0b0.1e-1073', '0b0.1e-1073', '0b0.1e-1072', '-0b0.1e-1072',
              '0b0.11e-1072', '0b0.11e-1072', '0b0.10e-1071',
              '0b0.101e-1071','0b0.101e-1071', '0b0.110e-1071', '0b0.111e-1071', '0b0.11e-1071', '0b0.1e-1070');

  my $len = scalar(@str1);
  die "size mismatch" if @str1 != @str2;

  for(my $i = 0; $i < $len; $i++) {
    my $x = nv_mpfr($str1[$i], 53);
    my @x = (substr($x, 0, 16), substr($x, 16, 16));
    my $arref = nv_mpfr($str2[$i]);
    if($x[0] ne $$arref[0] || $$arref[1] =~ /[^0]/ || $x[1] =~ /[^0]/) {
      warn "\nTesting _d_bytes(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": Got $x and @$arref\n";
      $ok = 0;
    }
  }

  if($have_atonv) {
    for(my $i = 0; $i < $len; $i++) {
      if(Math::MPFR::atonv($str1[$i]) != Math::MPFR::atonv($str2[$i])) {
        warn "\nIn Math::MPFR::atonv(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], 2)), ": $str1[$i] != $str2[$i]\n";
        $ok = 0;
      }
    }
  }
}

Math::MPFR::Rmpfr_set_default_prec($save_prec);

if($ok) { print "ok 5\n" }
else {print "not ok 5\n" }

$ok = 1;

########### Test 5 ends
########### Test 6 starts

# Checks that nv_mpfr($str, 53) and
# Math::MPFR::_d_bytes($str, 53) agree.
# Not very meaningful if $Config{nvtype}
# is not 'double' because, in such a
# case, nv_mpfr() calls in _d_bytes().

$Math::NV::no_warn = 0;

for my $count(1 .. 10000, 200000 .. 340000) {

  my $str = sprintf "%06d", $count;
  substr($str, 1, 0, '.');
  $str .= "e-308";

  my $out1 = nv_mpfr($str, 53);
  my $out2 = join '', Math::MPFR::_d_bytes($str, 53);

  if($out1 ne $out2) {
    warn "$out1 ne $out2\n";
    $ok = 0;
    last;
  }
}

if($ok) {print "ok 6\n"}
else {print "not ok 6\n"}

$ok = 1;

########### Test 6 ends
########### Test 7 starts

# Checks that nv_mpfr() and
# Math::MPFR::_ld_bytes() agree. Not
# very meaningful if $Config{nvtype}
# is not 'long double' because, in
# such a case, nv_mpfr() calls
# in _ld_bytes().

if($have_ld_bytes) {
  if(!$Math::NV::_ld_subnormal_bug) {
    for my $count(1 .. 10000, 200000 .. 340000) {

      my $str = sprintf "%06d", $count;
      substr($str, 1, 0, '.');
      $str .= "e-4932";

      my $out1 = nv_mpfr($str, Math::MPFR::LDBL_MANT_DIG);

      ## Ignore irrelevant bytes ##
      if(Math::MPFR::LDBL_MANT_DIG == 64) {
        $out1 = substr($out1, -20, 20);
      }

      my $out2 = join '', Math::MPFR::_ld_bytes($str, Math::MPFR::LDBL_MANT_DIG);

      if($out1 ne $out2 && $out1 ne ('0000'. $out2) && $out1 ne ('000000000000'. $out2)) {
        warn "\nIn _ld_bytes: $out1 ne $out2 for $str\n";
        $ok = 0;
        last;
      }
    }

    if($ok) {print "ok 7\n"}
    else {print "not ok 7\n"}
  }
  else {
    warn "\n Skipping test 7 - Your version of mpfr (", Math::MPFR::MPFR_VERSION_STRING(), ") is buggy\n",
         " wrt mpfr_get_ld() and subnormal values.\n",
         " Consider upgrading mpfr to at least version 3.1.5\n";
    print "ok 7\n";
  }
}
else {
  warn "\n Skipping test 7 - no Math::MPFR::_ld_bytes()\n$no_ld_bytes\n";
  print "ok 7\n";
}

$ok = 1;

########### Test 7 ends
########### Test 8 starts

# Checks that nv_mpfr() and
# Math::MPFR::_f128_bytes() agree. Not
# very meaningful if $Config{nvtype}
# is not '__float128' because, in such
# a case, nv_mpfr() calls in _ld_bytes().

if($have_f128_bytes) {
  for my $count(1 .. 10000, 200000 .. 340000) {

    my $str = sprintf "%06d", $count;
    substr($str, 1, 0, '.');
    $str .= "e-4932";

    my $out1 = nv_mpfr($str, 113);
    my $out2 = join '', Math::MPFR::_f128_bytes($str, 113);

    if($out1 ne $out2) {
      warn "$out1 ne $out2\n";
      $ok = 0;
      last;
    }
  }

  if($ok) {print "ok 8\n"}
  else {print "not ok 8\n"}
}
else {
  warn "\n Skipping test 8 - no Math::MPFR::_f128_bytes()\n$no_f128_bytes\n";
  print "ok 8\n";
}

########### Test 8 ends
########### Test 9 starts

$ok = 1;

$save_prec = Math::MPFR::Rmpfr_get_default_prec();

#####################
### 113-bit float ###
#####################

if(mant_dig() == 113) {

  Math::MPFR::Rmpfr_set_default_prec(64);
  Math::MPFR::Rmpfr_set_default_prec(64);
  my @str1 = ('0b0.1e-16445', '0b0.100001e-16445', '-0b0.1e-16445', '-0b0.100001e-16445',
              '3.64e-4951', '-3.64e-4951', '3.65e-4951', '-3.65e-4951',
              '0b0.1e-16444', '0b0.101e-16444', '0b0.11e-16444', '-0b0.11e-16444',
              '0b0.11e-16443','0b0.1101e-16443', '0b0.111e-16443',
              '0b0.101e-16442', '0b0.10101e-16442', '0b0.1011e-16442', '0b0.11101e-16442', '0b0.1101e-16442', '0b0.1111e-16442',);

  my @str2 = ('0', '0b0.1e-16444', '-0.0', '-0b0.1e-16444',
              '0b0.1e-16444', '-0b0.1e-16444', '0b0.1e-16444', '-0b0.1e-16444',
              '0b0.1e-16444', '0b0.1e-16444', '0b0.1e-16443', '-0b0.1e-16443',
              '0b0.11e-16443', '0b0.11e-16443', '0b0.10e-16442',
              '0b0.101e-16442','0b0.101e-16442', '0b0.110e-16442', '0b0.111e-16442', '0b0.11e-16442', '0b0.1e-16441');

  my $len = scalar(@str1);
  die "size mismatch" if @str1 != @str2;

  for(my $i = 0; $i < $len; $i++) {
    my $x = nv_mpfr($str1[$i], 64);
    my $y = nv_mpfr($str2[$i], 64);
    if($x ne $y ) {
      my $p = $str1[$i] =~ /0b/ ? 2 : 10;
      warn "\nTesting _ld_bytes(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], $p)), ": Got $x and $y for $str1[$i] and $str2[$i]\n";
      $ok = 0;
    }
  }

  Math::MPFR::Rmpfr_set_default_prec(53);
  @str1 =    ('0b0.1e-1074', '0b0.100001e-1074', '-0b0.1e-1074', '-0b0.100001e-1074',
              '4.94e-324', '-4.94e-324', '4.941e-324', '-4.941e-324',
              '0b0.1e-1073', '0b0.101e-1073', '0b0.11e-1073', '-0b0.11e-1073',
              '0b0.11e-1072','0b0.1101e-1072', '0b0.111e-1072',
              '0b0.101e-1071', '0b0.10101e-1071', '0b0.1011e-1071', '0b0.11101e-1071', '0b0.1101e-1071', '0b0.1111e-1071',);

  @str2 =    ('0', '0b0.1e-1073', '-0.0', '-0b0.1e-1073',
              '0b0.1e-1073', '-0b0.1e-1073', '0b0.1e-1073', '-0b0.1e-1073',
              '0b0.1e-1073', '0b0.1e-1073', '0b0.1e-1072', '-0b0.1e-1072',
              '0b0.11e-1072', '0b0.11e-1072', '0b0.10e-1071',
              '0b0.101e-1071','0b0.101e-1071', '0b0.110e-1071', '0b0.111e-1071', '0b0.11e-1071', '0b0.1e-1070');

  $len = scalar(@str1);
  die "size mismatch" if @str1 != @str2;

  for(my $i = 0; $i < $len; $i++) {
    my $x = nv_mpfr($str1[$i], 53);
    my $y = nv_mpfr($str2[$i], 53);
    if($x ne $y ) {
      my $p = $str1[$i] =~ /0b/ ? 2 : 10;
      warn "\nTesting _d_bytes(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], $p)), ": Got $x and $y for $str1[$i] and $str2[$i]\n";
      $ok = 0;
    }
  }

}

#####################
### 64-bit float  ###
#####################

elsif(mant_dig() == 64) {

  Math::MPFR::Rmpfr_set_default_prec(53);
  my @str1 = ('0b0.1e-1074', '0b0.100001e-1074', '-0b0.1e-1074', '-0b0.100001e-1074',
              '4.94e-324', '-4.94e-324', '4.941e-324', '-4.941e-324',
              '0b0.1e-1073', '0b0.101e-1073', '0b0.11e-1073', '-0b0.11e-1073',
              '0b0.11e-1072','0b0.1101e-1072', '0b0.111e-1072',
              '0b0.101e-1071', '0b0.10101e-1071', '0b0.1011e-1071', '0b0.11101e-1071', '0b0.1101e-1071', '0b0.1111e-1071',);

  my @str2 = ('0', '0b0.1e-1073', '-0.0', '-0b0.1e-1073',
              '0b0.1e-1073', '-0b0.1e-1073', '0b0.1e-1073', '-0b0.1e-1073',
              '0b0.1e-1073', '0b0.1e-1073', '0b0.1e-1072', '-0b0.1e-1072',
              '0b0.11e-1072', '0b0.11e-1072', '0b0.10e-1071',
              '0b0.101e-1071','0b0.101e-1071', '0b0.110e-1071', '0b0.111e-1071', '0b0.11e-1071', '0b0.1e-1070');

  my $len = scalar(@str1);
  die "size mismatch" if @str1 != @str2;

  for(my $i = 0; $i < $len; $i++) {
    my $x = nv_mpfr($str1[$i], 53);
    my $y = nv_mpfr($str2[$i], 53);
    if($x ne $y ) {
      my $p = $str1[$i] =~ /0b/ ? 2 : 10;
      warn "\nTesting _d_bytes(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], $p)), ": Got $x and $y for $str1[$i] and $str2[$i]\n";
      $ok = 0;
    }
  }

  if($have_f128_bytes) {
    Math::MPFR::Rmpfr_set_default_prec(113);
  my @str1 = ('0b0.1e-16494', '0b0.111111e-16494', '-0b0.1e-16494', '-0b0.111111e-16494',
              '6.47e-4966', '-6.47e-4966', '6.48e-4966', '-6.48e-4966',
              '0b0.1e-16493', '0b0.101e-16493', '0b0.11e-16493', '-0b0.11e-16493',
              '0b0.11e-16492','0b0.1101e-16492', '0b0.111e-16492',
              '0b0.101e-16491', '0b0.10101e-16491', '0b0.1011e-16491', '0b0.11101e-16491', '0b0.1101e-16491', '0b0.1111e-16491',);

  my @str2 = ('0', '0b0.1e-16493', '-0.0', '-0b0.1e-16493',
              '0b0.1e-16493', '-0b0.1e-16493', '0b0.1e-16493', '-0b0.1e-16493',
              '0b0.1e-16493', '0b0.1e-16493', '0b0.1e-16492', '-0b0.1e-16492',
              '0b0.11e-16492', '0b0.11e-16492', '0b0.10e-16491',
              '0b0.101e-16491','0b0.101e-16491', '0b0.110e-16491', '0b0.111e-16491', '0b0.11e-16491', '0b0.1e-16490');

    my $len = scalar(@str1);
    die "size mismatch" if @str1 != @str2;

    for(my $i = 0; $i < $len; $i++) {
      my $x = nv_mpfr($str1[$i], 113);
      my $y = nv_mpfr($str2[$i], 113);
      if($x ne $y ) {
        my $p = $str1[$i] =~ /0b/ ? 2 : 10;
        warn "\nTesting _f128_bytes(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], $p)), ": Got $x and $y for $str1[$i] and $str2[$i]\n";
        $ok = 0;
      }
    }
  }
  else {warn "\n Skipping  _f128_bytes tests - not available\n$no_f128_bytes\n"}
}

#####################
### 53-bit float  ###
#####################

elsif(mant_dig() == 53) {

  Math::MPFR::Rmpfr_set_default_prec(64);
  my @str1 = ('0b0.1e-16445', '0b0.100001e-16445', '-0b0.1e-16445', '-0b0.100001e-16445',
              '3.64e-4951', '-3.64e-4951', '3.65e-4951', '-3.65e-4951',
              '0b0.1e-16444', '0b0.101e-16444', '0b0.11e-16444', '-0b0.11e-16444',
              '0b0.11e-16443','0b0.1101e-16443', '0b0.111e-16443',
              '0b0.101e-16442', '0b0.10101e-16442', '0b0.1011e-16442', '0b0.11101e-16442', '0b0.1101e-16442', '0b0.1111e-16442',
              '0.00002e-4932',);

  my @str2 = ('0', '0b0.1e-16444', '-0.0', '-0b0.1e-16444',
              '0b0.1e-16444', '-0b0.1e-16444', '0b0.1e-16444', '-0b0.1e-16444',
              '0b0.1e-16444', '0b0.1e-16444', '0b0.1e-16443', '-0b0.1e-16443',
              '0b0.11e-16443', '0b0.11e-16443', '0b0.10e-16442',
              '0b0.101e-16442','0b0.101e-16442', '0b0.110e-16442', '0b0.111e-16442', '0b0.11e-16442', '0b0.1e-16441',
              '0.00002e-4932',);

  my $len = scalar(@str1);
  die "size mismatch" if @str1 != @str2;

  if(!$Math::NV::_ld_subnormal_bug) {
    if($have_ld_bytes) {
      for(my $i = 0; $i < $len; $i++) {
        my $x = nv_mpfr($str1[$i], 64);
        my $y = nv_mpfr($str2[$i], 64);
        if($x ne $y ) {
          my $p1 = $str1[$i] =~ /0b/ ? 2 : 10;
          my $p2 = $str2[$i] =~ /0b/ ? 2 : 10;
          warn "\nTesting _ld_bytes(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], $p1)),
                                       " ",  Math::NV::get_relevant_prec(Math::MPFR->new($str2[$i], $p2)),
                                       " $str1[$i] $str2[$i] ",
                                       ": Got $x and $y for $str1[$i] and $str2[$i]\n";
          $ok = 0;
        }
      }
    }
    else {
      warn "\n Skipping _ld_bytes tests - not available\n$no_ld_bytes\n";
    }
  }


  else {
    warn "\n Skipping _ld_bytes() tests in test 8 - Your version of mpfr (", Math::MPFR::MPFR_VERSION_STRING(), ")",
         "\n is buggy wrt mpfr_get_ld() and subnormal values.\n",
         " Consider upgrading mpfr to at least version 3.1.5\n";
  }

  if($have_f128_bytes) {
    Math::MPFR::Rmpfr_set_default_prec(113);
    my @str1 = ('0b0.1e-16494', '0b0.111111e-16494', '-0b0.1e-16494', '-0b0.111111e-16494',
              '6.47e-4966', '-6.47e-4966', '6.48e-4966', '-6.48e-4966',
              '0b0.1e-16493', '0b0.101e-16493', '0b0.11e-16493', '-0b0.11e-16493',
              '0b0.11e-16492','0b0.1101e-16492', '0b0.111e-16492',
              '0b0.101e-16491', '0b0.10101e-16491', '0b0.1011e-16491', '0b0.11101e-16491', '0b0.1101e-16491', '0b0.1111e-16491',);

    my @str2 = ('0', '0b0.1e-16493', '-0.0', '-0b0.1e-16493',
              '0b0.1e-16493', '-0b0.1e-16493', '0b0.1e-16493', '-0b0.1e-16493',
              '0b0.1e-16493', '0b0.1e-16493', '0b0.1e-16492', '-0b0.1e-16492',
              '0b0.11e-16492', '0b0.11e-16492', '0b0.10e-16491',
              '0b0.101e-16491','0b0.101e-16491', '0b0.110e-16491', '0b0.111e-16491', '0b0.11e-16491', '0b0.1e-16490');

    my $len = scalar(@str1);
    die "size mismatch" if @str1 != @str2;

    for(my $i = 0; $i < $len; $i++) {
      my $x = nv_mpfr($str1[$i], 113);
      my $y = nv_mpfr($str2[$i], 113);
      if($x ne $y ) {
        my $p = $str1[$i] =~ /0b/ ? 2 : 10;
        warn "\nTesting _f128_bytes(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], $p)), ": Got $x and $y for $str1[$i] and $str2[$i]\n";
        $ok = 0;
      }
    }
  }
  else {warn "\n Skipping  _f128_bytes tests - not available\n$no_f128_bytes\n"}
}

#####################
### 106-bit float ###
#####################

else { # double-double
  my @str1 = ('0b0.1e-1074', '0b0.100001e-1074', '-0b0.1e-1074', '-0b0.100001e-1074',
              '4.94e-324', '-4.94e-324', '4.941e-324', '-4.941e-324',
              '0b0.1e-1073', '0b0.101e-1073', '0b0.11e-1073', '-0b0.11e-1073',
              '0b0.11e-1072','0b0.1101e-1072', '0b0.111e-1072',
              '0b0.101e-1071', '0b0.10101e-1071', '0b0.1011e-1071', '0b0.11101e-1071', '0b0.1101e-1071', '0b0.1111e-1071',);

  my @str2 = ('0', '0b0.1e-1073', '-0.0', '-0b0.1e-1073',
              '0b0.1e-1073', '-0b0.1e-1073', '0b0.1e-1073', '-0b0.1e-1073',
              '0b0.1e-1073', '0b0.1e-1073', '0b0.1e-1072', '-0b0.1e-1072',
              '0b0.11e-1072', '0b0.11e-1072', '0b0.10e-1071',
              '0b0.101e-1071','0b0.101e-1071', '0b0.110e-1071', '0b0.111e-1071', '0b0.11e-1071', '0b0.1e-1070');

  my $len = scalar(@str1);
  die "size mismatch" if @str1 != @str2;

  for(my $i = 0; $i < $len; $i++) {
    my $x = nv_mpfr($str1[$i], 53);
    my $y = nv_mpfr($str2[$i], 53);
    if($x ne $y ) {
      my $p = $str1[$i] =~ /0b/ ? 2 : 10;
      warn "\nTesting _d_bytes(): ", Math::NV::get_relevant_prec(Math::MPFR->new($str1[$i], $p)), ": Got $x and $y for $str1[$i] and $str2[$i]\n";
      $ok = 0;
    }
  }
}

Math::MPFR::Rmpfr_set_default_prec($save_prec);

if($ok) { print "ok 9\n" }
else {print "not ok 9\n" }

$ok = 1;

########### Test 9 ends
########### Test 10 starts


