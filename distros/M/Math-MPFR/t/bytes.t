use warnings;
use strict;
use Config;
use Math::MPFR qw(:mpfr);


print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

warn "\nbyteorder: ", $Config{byteorder}, "\n";

my $kind;

my %ldkind = (
 -1 => 'unknown',
  0 => 'double',
  1 => '"IEEE" 754 128-bit little endian',
  2 => '"IEEE" 754 128-bit big endian',
  3 => 'x86 80-bit little endian',
  4 => 'x86 80-bit big endian',
  5 => 'double-double 128-bit little endian',
  6 => 'double-double 128-bit big endian',
);

if(defined $Config{longdblkind}) {
  $kind = $Config{longdblkind};
  warn "longdblkind: $kind: $ldkind{$kind}\n";
}
else {
  warn "\$Config{longdblkind} not defined for this build of perl $]\n";
}

warn "HAVE_IEEE_754_LONG_DOUBLE defined is ", Math::MPFR::_have_IEEE_754_long_double(), "\n";
warn "HAVE_EXTENDED_PRECISION_LONG_DOUBLE is ", Math::MPFR::_have_extended_precision_long_double(), "\n";


print "1..43\n";

my $arb = 40;
Rmpfr_set_default_prec($arb);

my @bytes;
my $dd = 0;

eval {@bytes = Math::MPFR::_ld_bytes('2.3', 64);};

if($@) {

  my $mess = $@;

  my $nv1 = 1.0;
  my $nv2 = $nv1 + (2 ** -1000);
  $dd = 1 if $nv2 != $nv1;

  my $bits;
  $bits = Math::MPFR::_required_ldbl_mant_dig() == 2098 ? 106 : Math::MPFR::_required_ldbl_mant_dig();

  if((defined($Config{longdblkind}) && $Config{longdblkind} == 6) || $dd == 1) {
    warn "\ndouble-double detected\n";
    if($mess =~ /^2nd arg \(/) {print "ok 1\n"}
    else {
      warn "\n\$\@: $mess\n";
      print "not ok 1\n";
    }
  }
  elsif(64 != $bits) {
    warn "\n$bits != 64\n";
    if($mess =~ /^2nd arg \(/) {print "ok 1\n"}
    else {
      warn "\n\$\@: $mess\n";
      print "not ok 1\n";
    }
  }
  else {
    warn "\n\$\@: $mess\n";
    print "not ok 1\n";
  }

  warn "\nSkipping tests 2-4\n";
  print "ok 2\nok 3\nok 4\n";

}
else {

  my $hex = join '', @bytes;

  if($hex eq '40009333333333333333') {print "ok 1\n"}
  else {
    warn "expected 40009333333333333333, got $hex";
    print "not ok 1\n";
  }

  @bytes = Math::MPFR::_ld_bytes('2.93', 64);
  $hex = join '', @bytes;

  if($hex eq '4000bb851eb851eb851f') {print "ok 2\n"}
  else {
    warn "expected 4000bb851eb851eb851f, got $hex";
    print "not ok 2\n";
  }

  eval{Math::MPFR::_ld_bytes('2.93', 63);};

  if($@ =~ /^2nd arg to Math::MPFR::_ld_bytes must be 64/) {print "ok 3\n"}
  else {
    warn "\nIn Math::MPFR::_ld_bytes: $@\n";
    print "not ok 3\n";
  }

  eval{Math::MPFR::_ld_bytes(2.93, 64);};

  if($@ =~ /^1st arg supplied to Math::MPFR::_ld_bytes is not a string/) {print "ok 4\n"}
  else {
    warn "\nIn Math::MPFR::_ld_bytes: $@\n";
    print "not ok 4\n";
  }

}

#####################################################
#####################################################

eval {@bytes = Math::MPFR::_f128_bytes('2.3', 113);};

if($@) {

  my $mess = $@;

  if(!Math::MPFR::_MPFR_WANT_FLOAT128()) {
    if($mess =~ /^__float128 support not built into this Math::MPFR/) {print "ok 5\n"}
    else {
      warn "\n\$\@: $mess\n";
      print "not ok 5\n";
    }
  }
  elsif(113 != MPFR_FLT128_DIG) {
    my $dig = MPFR_FLT128_DIG;
    warn "\n$dig != 113\n";
    if($mess =~ /^2nd arg \(/) {print "ok 5\n"}
    else {
      warn "\n\$\@: $mess\n";
      print "not ok 5\n";
    }
  }
  else {
    warn "\n\$\@: $mess\n";
    print "not ok 5\n";
  }

  warn "\nSkipping tests 6-8\n";
  print "ok 6\nok 7\nok 8\n";

}
else {

  my $hex = join '', @bytes;

  if($hex eq '40002666666666666666666666666666') {print "ok 5\n"}
  else {
    warn "expected 40002666666666666666666666666666, got $hex";
    print "not ok 5\n";
  }

  @bytes = Math::MPFR::_f128_bytes('2.93', 113);
  $hex = join '', @bytes;

  if($hex eq '4000770a3d70a3d70a3d70a3d70a3d71') {print "ok 6\n"}
  else {
    warn "expected 4000770a3d70a3d70a3d70a3d70a3d71, got $hex";
    print "not ok 6\n";
  }

  eval{Math::MPFR::_f128_bytes('2.93', 63);};

  if($@ =~ /^2nd arg to Math::MPFR::_f128_bytes must be 113/) {print "ok 7\n"}
  else {
    warn "\nIn Math::MPFR::_f128_bytes: $@\n";
    print "not ok 7\n";
  }

  eval{Math::MPFR::_f128_bytes(2.93, 113);};

  if($@ =~ /^1st arg supplied to Math::MPFR::_f128_bytes is not a string/) {print "ok 8\n"}
  else {
    warn "\nIn Math::MPFR::_f128_bytes: $@\n";
    print "not ok 8\n";
  }

}

my $now = Rmpfr_get_default_prec();

if($now == $arb) {print "ok 9\n"}
else {
  warn "Default precision has changed from $arb to $now\n";
  print "not ok 9\n";
}

@bytes = Math::MPFR::_d_bytes('1e+129', 53);

my $hex = join '', @bytes;

my $double = Math::MPFR::Rmpfr_init2(53);
Math::MPFR::Rmpfr_set_str($double, '1e+129', 10, 0);

unless($] < 5.01) { # perl-5.8 and earlier don't understand 'pack "d<"'.

  my $hex2 = scalar reverse unpack "h*", pack "d<", Math::MPFR::Rmpfr_get_d($double, 0);

  if($hex eq $hex2) {print "ok 10\n"}
  else {
    warn "expected $hex, got $hex2\n";
    print "not ok 10\n";
  }
}
else {
  warn "\nSkipping test 10 for perl-5.9 and earlier\n";
  print "ok 10\n";
}

my @bytes2;

eval{@bytes = Math::MPFR::_d_bytes('23.75', 53);};

if(!$@) {
  @bytes2 = Math::MPFR::_d_bytes('0x17.c', 53);
  my $one = join '', @bytes;
  my $two = join '', @bytes2;
  if($one eq $two) {print "ok 11\n"}
  else {
    warn "\nexpected *$one*\n     got *$two*\n";
    print "not ok 11\n";
  }
}
else {
  warn "Skipping test 11 - $@\n";
  print "ok 11\n";
}

eval{@bytes = Math::MPFR::_ld_bytes('23.75', 64);};

if(!$@) {
  @bytes2 = Math::MPFR::_ld_bytes('0X17.C', 64);
  my $one = join '', @bytes;
  my $two = join '', @bytes2;
  if($one eq $two) {print "ok 12\n"}
  else {
    warn "\nexpected *$one*\n     got *$two*\n";
    print "not ok 12\n";
  }
}
else {
  warn "Skipping test 12 - $@\n";
  print "ok 12\n";
}

eval{@bytes = Math::MPFR::_f128_bytes('23.75', 113);};

if(!$@) {
 @bytes2 = Math::MPFR::_f128_bytes('0X17.c', 113);
  my $one = join '', @bytes;
  my $two = join '', @bytes2;
  if($one eq $two) {print "ok 13\n"}
  else {
    warn "\nexpected *$one*\n     got *$two*\n";
    print "not ok 13\n";
  }
}
else {
  warn "Skipping test 13 - $@\n";
  print "ok 13\n";
}

my $fr_breaker = Rmpfr_init2(200);
Rmpfr_set_str($fr_breaker, '1.1', 10, MPFR_RNDN);

eval {Math::MPFR::_d_bytes_fr($fr_breaker, 53);};

if($@ =~ /^Precision of 1st arg supplied to _d_bytes_fr must be 53/) {print "ok 14\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 14\n";
}

eval {Math::MPFR::_dd_bytes_fr($fr_breaker, 106);};

if($@ =~ /^Precision of 1st arg supplied to _dd_bytes_fr must be 2098/) {print "ok 15\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 15\n";
}

eval {Math::MPFR::_ld_bytes_fr($fr_breaker, 64);};


if($@ =~ /^Precision of 1st arg supplied to _ld_bytes_fr must match 2nd arg \(64\)/) {print "ok 16\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 16\n";
}

eval {Math::MPFR::_f128_bytes_fr($fr_breaker, 113);};

if($@ =~ /^Precision of 1st arg supplied to _f128_bytes_fr must be 113/ ||
   $@ =~ /^__float128 support not built into this Math::MPFR/) {print "ok 17\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 17\n";
}

my $d_fr = Rmpfr_init2(53);
Rmpfr_set_str($d_fr, '1e+127', 10, MPFR_RNDN);

my $expected = join '', Math::MPFR::_d_bytes_fr($d_fr, 53);

if($expected eq '5a4d8ba7f519c84f') {print "ok 18\n"}
else {
  warn "Expected *5a4d8ba7f519c84f*, got *$expected*\n";
  print "not ok 18\n";
}

my $dd_fr = Rmpfr_init2(2098);
Rmpfr_set_str($dd_fr, '1e+127', 10, MPFR_RNDN);

$expected = join '', Math::MPFR::_dd_bytes_fr($dd_fr, 106);

if($expected eq '5a4d8ba7f519c84f56e7fd1f28f89c56') {print "ok 19\n"}
else {
  warn "Expected *5a4d8ba7f519c84f56e7fd1f28f89c56*, got *$expected*\n";
  print "not ok 19\n";
}


my $ld_fr = Rmpfr_init2(64);
Rmpfr_set_str($ld_fr, '1e+127', 10, MPFR_RNDN);

eval {$expected = join '', Math::MPFR::_ld_bytes_fr($ld_fr, 64);};

if(Math::MPFR::_required_ldbl_mant_dig() != 64 && $@ =~ /^2nd arg \(64\) supplied to Math::MPFR::_ld_bytes_fr does not match LDBL_MANT_DIG/) {
  warn "LDBL_MANT_DIG: ", Math::MPFR::_required_ldbl_mant_dig() == 2098 ? 106 : Math::MPFR::_required_ldbl_mant_dig(), "\n";
  print "ok 20\n";
}
elsif($@) {
  warn "\$\@:$@\n";
  print "not ok 20\n";
}
elsif($expected eq '41a4ec5d3fa8ce427b00') {print "ok 20\n"}
else {
  warn "Expected *41a4ec5d3fa8ce427b00*, got *$expected*\n";
  print "not ok 20\n";
}

my $f128_fr = Rmpfr_init2(113);
Rmpfr_set_str($f128_fr, '1e+127', 10, MPFR_RNDN);

eval {$expected = join '', Math::MPFR::_f128_bytes_fr($f128_fr, 113);};

if(!Math::MPFR::_MPFR_WANT_FLOAT128()) {
  if($@ =~ /^__float128 support not built into this Math::MPFR/) {print "ok 21\n"}
  else {
    warn "\n\$\@\: $@\n";
    print "not ok 21\n";
  }
}
elsif($@) {
  warn "\$\@:$@\n";
  print "not ok 21\n";
}
elsif($expected eq '41a4d8ba7f519c84f5ff47ca3e27156a') {print "ok 21\n"}
else {
  warn "Expected *41a4d8ba7f519c84f5ff47ca3e27156a*, got *$expected*\n";
  print "not ok 21\n";
}

my $h;

eval{$h = Math::MPFR::bytes($d_fr, 'Long Double');};

if($@ =~ /^Precision of 1st arg supplied to _ld_bytes_fr must match 2nd arg \(64\)/) {print "ok 22\n"}
else {
  warn "\$\@: $@";
  print "not ok 22\n";
}

eval{$h = Math::MPFR::bytes($d_fr, 53);};

if($@ =~ /^2nd arg to Math::MPFR::bytes must be/) {print "ok 23\n"}
else {
  warn "\$\@: $@";
  print "not ok 23\n";
}

$expected = Math::MPFR::bytes($d_fr, 'Double');

if($expected eq '5a4d8ba7f519c84f') {print "ok 24\n"}
else {
  warn "Expected *5a4d8ba7f519c84f*, got *$expected*\n";
  print "not ok 24\n";
}

$expected = Math::MPFR::bytes('1e+127', 'Double');

if($expected eq '5a4d8ba7f519c84f') {print "ok 25\n"}
else {
  warn "Expected *5a4d8ba7f519c84f*, got *$expected*\n";
  print "not ok 25\n";
}

eval {$expected = Math::MPFR::bytes($ld_fr, 'Long Double');};

if(Math::MPFR::_required_ldbl_mant_dig() != 64 && $@ =~ /^2nd arg \(64\) supplied to Math::MPFR::_ld_bytes_fr does not match LDBL_MANT_DIG/) {print "ok 26\n"}
elsif($@) {
  warn "\$\@: $@\n";
  print "not ok 26\n";
}
elsif($expected eq '41a4ec5d3fa8ce427b00') {print "ok 26\n"}
else {
  warn "Expected *41a4ec5d3fa8ce427b00*, got *$expected*\n";
  print "not ok 26\n";
}

eval {$expected = Math::MPFR::bytes('1e+127', 'Long Double');};

if(Math::MPFR::_required_ldbl_mant_dig() != 64 && $@ =~ /^2nd arg \(64\) supplied to Math::MPFR::_ld_bytes does not match LDBL_MANT_DIG/) {print "ok 27\n"}
elsif($@) {
  warn "\$\@: $@\n";
  print "not ok 27\n";
}
elsif($expected eq '41a4ec5d3fa8ce427b00') {print "ok 27\n"}
else {
  warn "Expected *41a4ec5d3fa8ce427b00*, got *$expected*\n";
  print "not ok 27\n";
}

$expected = Math::MPFR::bytes($dd_fr, 'Double-Double');

if($expected eq '5a4d8ba7f519c84f56e7fd1f28f89c56') {print "ok 28\n"}
else {
  warn "Expected *5a4d8ba7f519c84f56e7fd1f28f89c56*, got *$expected*\n";
  print "not ok 28\n";
}

$expected = Math::MPFR::bytes('1e+127', 'Double-Double');

if($expected eq '5a4d8ba7f519c84f56e7fd1f28f89c56') {print "ok 29\n"}
else {
  warn "Expected *5a4d8ba7f519c84f56e7fd1f28f89c56*, got *$expected*\n";
  print "not ok 29\n";
}

eval{$expected = Math::MPFR::bytes($f128_fr, '__Float128');};

if(!Math::MPFR::_MPFR_WANT_FLOAT128()) {
  if($@ =~ /^__float128 support not built into this Math::MPFR/) {print "ok 30\n"}
  else {
    warn "\n\$\@\: $@";
    print "not ok 30\n";
  }
}
elsif($@) {
  warn "\$\@:$@\n";
  print "not ok 30\n";
}
elsif($expected eq '41a4d8ba7f519c84f5ff47ca3e27156a') {print "ok 30\n"}
else {
  warn "Expected *41a4d8ba7f519c84f5ff47ca3e27156a*, got *$expected*\n";
  print "not ok 30\n";
}

eval{$expected = Math::MPFR::bytes('1e+127', '__Float128');};

if(!Math::MPFR::_MPFR_WANT_FLOAT128()) {
  if($@ =~ /^__float128 support not built into this Math::MPFR/) {print "ok 31\n"}
  else {
    warn "\n\$\@\: $@";
    print "not ok 31\n";
  }
}
elsif($@) {
  warn "\$\@:$@\n";
  print "not ok 31\n";
}
elsif($expected eq '41a4d8ba7f519c84f5ff47ca3e27156a') {print "ok 31\n"}
else {
  warn "Expected *41a4d8ba7f519c84f5ff47ca3e27156a*, got *$expected*\n";
  print "not ok 31\n";
}

my $unity = Math::MPFR->new(1);

Rmpfr_exp($d_fr,    $unity, MPFR_RNDN);
Rmpfr_exp($dd_fr,   $unity, MPFR_RNDN);
Rmpfr_exp($ld_fr,   $unity, MPFR_RNDN);
Rmpfr_exp($f128_fr, $unity, MPFR_RNDN);

$expected = Math::MPFR::bytes($d_fr, 'double');

if($expected eq '4005bf0a8b145769') {print "ok 32\n"}
else {
  warn "expected *4005bf0a8b145769*, got *$expected*\n";
  print "not ok 32\n";
}

$expected = Math::MPFR::bytes($dd_fr, 'Double-double');

if($expected eq '4005bf0a8b1457693ca4d57ee2b1013a') {print "ok 33\n"}
else {
  warn "expected *4005bf0a8b1457693ca4d57ee2b1013a*, got *$expected*\n";
  print "not ok 33\n";
}

eval {$expected = Math::MPFR::bytes($ld_fr, 'Long double');};

if(Math::MPFR::_required_ldbl_mant_dig() != 64 && $@ =~ /^2nd arg \(64\) supplied to Math::MPFR::_ld_bytes_fr does not match LDBL_MANT_DIG/) {print "ok 34\n"}
elsif($@) {
  warn "\$\@: $@\n";
  print "not ok 34\n";
}
elsif($expected eq '4000adf85458a2bb4a9b') {print "ok 34\n"}
else {
  warn "expected *4000adf85458a2bb4a9b*, got *$expected*\n";
  print "not ok 34\n";
}

eval{$expected = Math::MPFR::bytes($f128_fr, '__float128');};

if(!Math::MPFR::_MPFR_WANT_FLOAT128()) {
  if($@ =~ /^__float128 support not built into this Math::MPFR/) {print "ok 35\n"}
  else {
    warn "\n\$\@\: $@";
    print "not ok 35\n";
  }
}
elsif($@) {
  warn "\$\@:$@\n";
  print "not ok 35\n";
}
elsif($expected eq '40005bf0a8b1457695355fb8ac404e7a') {print "ok 35\n"}
else {
  warn "expected *40005bf0a8b1457695355fb8ac404e7a*, got *$expected*\n";
  print "not ok 35\n";
}

Rmpfr_const_pi($d_fr,    MPFR_RNDN);
Rmpfr_const_pi($dd_fr,   MPFR_RNDN);
Rmpfr_const_pi($ld_fr,   MPFR_RNDN);
Rmpfr_const_pi($f128_fr, MPFR_RNDN);

$expected = Math::MPFR::bytes($d_fr, 'double');

if($expected eq '400921fb54442d18') {print "ok 36\n"}
else {
  warn "expected *400921fb54442d18*, got *$expected*\n";
  print "not ok 36\n";
}

$expected = Math::MPFR::bytes($dd_fr, 'Double-double');

if($expected eq '400921fb54442d183ca1a62633145c07') {print "ok 37\n"}
else {
  warn "expected *400921fb54442d183ca1a62633145c07*, got *$expected*\n";
  print "not ok 37\n";
}

eval {$expected = Math::MPFR::bytes($ld_fr, 'Long double');};

if(Math::MPFR::_required_ldbl_mant_dig() != 64 && $@ =~ /^2nd arg \(64\) supplied to Math::MPFR::_ld_bytes_fr does not match LDBL_MANT_DIG/) {print "ok 38\n"}
elsif($@) {
  warn "\$\@: $@\n";
  print "not ok 38\n";
}
elsif($expected eq '4000c90fdaa22168c235') {print "ok 38\n"}
else {
  warn "expected *4000c90fdaa22168c235*, got *$expected*\n";
  print "not ok 38\n";
}

eval{$expected = Math::MPFR::bytes($f128_fr, '__float128');};

if(!Math::MPFR::_MPFR_WANT_FLOAT128()) {
  if($@ =~ /^__float128 support not built into this Math::MPFR/) {print "ok 39\n"}
  else {
    warn "\n\$\@\: $@";
    print "not ok 39\n";
  }
}
elsif($@) {
  warn "\$\@:$@\n";
  print "not ok 39\n";
}
elsif($expected eq '4000921fb54442d18469898cc51701b8') {print "ok 39\n"}
else {
  warn "expected *4000921fb54442d18469898cc51701b8*, got *$expected*\n";
  print "not ok 39\n";
}

Rmpfr_set_si($d_fr,    2, MPFR_RNDN);
Rmpfr_set_si($dd_fr,   2, MPFR_RNDN);
Rmpfr_set_si($ld_fr,   2, MPFR_RNDN);
Rmpfr_set_si($f128_fr, 2, MPFR_RNDN);

Rmpfr_sqrt($d_fr,    $d_fr,    MPFR_RNDN);
Rmpfr_sqrt($dd_fr,   $dd_fr,   MPFR_RNDN);
Rmpfr_sqrt($ld_fr,   $ld_fr,   MPFR_RNDN);
Rmpfr_sqrt($f128_fr, $f128_fr, MPFR_RNDN);

$expected = Math::MPFR::bytes($d_fr, 'double');

if($expected eq '3ff6a09e667f3bcd') {print "ok 40\n"}
else {
  warn "expected *3ff6a09e667f3bcd*, got *$expected*\n";
  print "not ok 40\n";
}

$expected = Math::MPFR::bytes($dd_fr, 'Double-double');

if($expected eq '3ff6a09e667f3bcdbc9bdd3413b26456') {print "ok 41\n"}
else {
  warn "expected *3ff6a09e667f3bcdbc9bdd3413b26456*, got *$expected*\n";
  print "not ok 41\n";
}

eval {$expected = Math::MPFR::bytes($ld_fr, 'Long double');};

if(Math::MPFR::_required_ldbl_mant_dig() != 64 && $@ =~ /^2nd arg \(64\) supplied to Math::MPFR::_ld_bytes_fr does not match LDBL_MANT_DIG/) {print "ok 42\n"}
elsif($@) {
  warn "\$\@: $@\n";
  print "not ok 42\n";
}
elsif($expected eq '3fffb504f333f9de6484') {print "ok 42\n"}
else {
  warn "expected *3fffb504f333f9de6484*, got *$expected*\n";
  print "not ok 42\n";
}

eval{$expected = Math::MPFR::bytes($f128_fr, '__float128');};

if(!Math::MPFR::_MPFR_WANT_FLOAT128()) {
  if($@ =~ /^__float128 support not built into this Math::MPFR/) {print "ok 43\n"}
  else {
    warn "\n\$\@\: $@";
    print "not ok 43\n";
  }
}
elsif($@) {
  warn "\$\@:$@\n";
  print "not ok 43\n";
}
elsif($expected eq '3fff6a09e667f3bcc908b2fb1366ea95') {print "ok 43\n"}
else {
  warn "expected *3fff6a09e667f3bcc908b2fb1366ea95*, got *$expected*\n";
  print "not ok 43\n";
}


__END__

e:
4005bf0a8b145769
4000adf85458a2bb4a9b
4005bf0a8b1457693ca4d57ee2b1013a
40005bf0a8b1457695355fb8ac404e7a

pi:
400921fb54442d18
4000c90fdaa22168c235
400921fb54442d183ca1a62633145c07
4000921fb54442d18469898cc51701b8

sqrt(2):
3ff6a09e667f3bcd
3fffb504f333f9de6484
3ff6a09e667f3bcdbc9bdd3413b26456
3fff6a09e667f3bcc908b2fb1366ea95
