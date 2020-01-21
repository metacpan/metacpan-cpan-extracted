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

warn "HAVE_IEEE_754_LONG_DOUBLE is ", Math::MPFR::_have_IEEE_754_long_double(), "\n";
warn "HAVE_EXTENDED_PRECISION_LONG_DOUBLE is ", Math::MPFR::_have_extended_precision_long_double(), "\n";


print "1..15\n";

my $arb = 40;
Rmpfr_set_default_prec($arb);

my $hex_53 = Math::MPFR::bytes('2.3', 53);

if($hex_53 eq '4002666666666666') { print "ok 1\n" }
else {
  warn "expected: 4002666666666666\ngot     : $hex_53\n";
  print "not ok 1\n";
}

my $hex_64;

eval { $hex_64 = Math::MPFR::bytes('2.3', 64);};

if($@) {
  if($@ =~/^Byte structure of 10-byte long double not provided/ &&
     !Math::MPFR::_have_extended_precision_long_double()) { print "ok 2\n" }
  else {
    warn "\$\@: $@";
    print "not ok 2\n";
  }
}
else {
  if($hex_64 eq '40009333333333333333') { print "ok 2\n" }
  else {
    warn "expected: 40009333333333333333\ngot     : $hex_64\n";
    print "not ok 2\n";
  }
}

my $hex_2098 = Math::MPFR::bytes('1e+127', 2098);

if($hex_2098 eq '5a4d8ba7f519c84f56e7fd1f28f89c56') { print "ok 3\n" }
else {
  warn "expected: 5a4d8ba7f519c84f56e7fd1f28f89c56\ngot     : $hex_2098\n";
  print "not ok 3\n";
}

my $hex_113;

eval { $hex_113 = Math::MPFR::bytes('2.3', 113);};

if($@) {
  if($@ =~/^Byte structure of 113-bit NV types not provided/ &&
     !Math::MPFR::_have_IEEE_754_long_double() &&
     !Math::MPFR::_MPFR_WANT_FLOAT128()) { print "ok 4\n" }
  else {
    warn "\$\@: $@";
    print "not ok 4\n";
  }
}
else {
  if($hex_113 eq '40002666666666666666666666666666') { print "ok 4\n" }
  else {
    warn "expected: 40002666666666666666666666666666\ngot     : $hex_113\n";
    print "not ok 4\n";
  }
}

eval { $hex_53 = Math::MPFR::bytes(2.3, 53);};

if($@ =~ /^1st arg to Math::MPFR::bytes must be either/) { print "ok 5\n" }
else {
  warn "\$\@: $@";
  print "not ok 5\n";
}

eval { $hex_53 = Math::MPFR::bytes('2.3', 52);};

if($@ =~ /^2nd argument given to Math::MPFR::bytes is neither/) { print "ok 6\n" }
else {
  warn "\$\@: $@";
  print "not ok 6\n";
}

my $hex_53_fr  = Rmpfr_init2(53);
my $hex_64_fr  = Rmpfr_init2(64);
my $hex_2098_fr = Rmpfr_init2(2098);
my $hex_113_fr = Rmpfr_init2(113);

Rmpfr_strtofr($hex_53_fr,  '2.3',    10, MPFR_RNDN);
Rmpfr_strtofr($hex_64_fr,  '2.3',    10, MPFR_RNDN);
Rmpfr_strtofr($hex_2098_fr, '1e+127', 10, MPFR_RNDN);
Rmpfr_strtofr($hex_113_fr, '2.3',    10, MPFR_RNDN);

$hex_53 = Math::MPFR::bytes($hex_53_fr, 53);

if($hex_53 eq '4002666666666666') { print "ok 7\n" }
else {
  warn "expected: 4002666666666666\ngot     : $hex_53\n";
  print "not ok 7\n";
}

eval { $hex_64 = Math::MPFR::bytes($hex_64_fr, 64);};

if($@) {
  if($@ =~/^Byte structure of 10-byte long double not provided/ &&
     !Math::MPFR::_have_extended_precision_long_double()) { print "ok 8\n" }
  else {
    warn "\$\@: $@";
    print "not ok 8\n";
  }
}
else {
  if($hex_64 eq '40009333333333333333') { print "ok 8\n" }
  else {
    warn "expected: 40009333333333333333\ngot     : $hex_64\n";
    print "not ok 8\n";
  }
}

$hex_2098 = Math::MPFR::bytes($hex_2098_fr, 2098);

if($hex_2098 eq '5a4d8ba7f519c84f56e7fd1f28f89c56') { print "ok 9\n" }
else {
  warn "expected: 5a4d8ba7f519c84f56e7fd1f28f89c56\ngot     : $hex_2098\n";
  print "not ok 9\n";
}

eval { $hex_113 = Math::MPFR::bytes($hex_113_fr, 113);};

if($@) {
  if($@ =~/^Byte structure of 113-bit NV types not provided/ &&
     !Math::MPFR::_have_IEEE_754_long_double() &&
     !Math::MPFR::_MPFR_WANT_FLOAT128()) { print "ok 10\n" }
  else {
    warn "\$\@: $@";
    print "not ok 10\n";
  }
}
else {
  if($hex_113 eq '40002666666666666666666666666666') { print "ok 10\n" }
  else {
    warn "expected: 40002666666666666666666666666666\ngot     : $hex_113\n";
    print "not ok 10\n";
  }
}

eval { $hex_53 = Math::MPFR::bytes(Math::MPFR->new(2.3), 53);};

if($@ =~ /^Precision of 1st arg supplied/) { print "ok 11\n" }
else {
  warn "\$\@: $@";
  print "not ok 11\n";
}

eval { $hex_64 = Math::MPFR::bytes(Math::MPFR->new(2.3), 64);};

if($@ =~ /^Precision of 1st arg supplied/ || $@ =~ /^Byte structure of/) { print "ok 12\n" }
else {
  warn "\$\@: $@";
  print "not ok 12\n";
}

eval { $hex_2098 = Math::MPFR::bytes(Math::MPFR->new(2.3), 2098);};

if($@ =~ /^Precision of 1st arg supplied/) { print "ok 13\n" }
else {
  warn "\$\@: $@";
  print "not ok 13\n";
}

eval { $hex_113 = Math::MPFR::bytes(Math::MPFR->new(2.3), 113);};

if($@ =~ /^Precision of 1st arg supplied/ || $@ =~ /^Byte structure of/) { print "ok 14\n" }
else {
  warn "\$\@: $@";
  print "not ok 14\n";
}

if(Rmpfr_get_default_prec() == $arb) { print "ok 15\n" }
else {
  warn "\nexpected: 40\ngot     : $arb\n";
  print "not ok 15\n";
}


###########################################################################################################
