use warnings;
use strict;
use Config;
use Math::MPFR qw(:mpfr);
use Math::MPFR::V;

print "1..8\n";

warn "\n# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
warn "# MPFR_VERSION is ", MPFR_VERSION, "\n";
warn "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
warn "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";
warn "# GMP_LIMB_BITS is ", Math::MPFR::_GMP_LIMB_BITS, "\n" if defined Math::MPFR::_GMP_LIMB_BITS;
warn "# GMP_NAIL_BITS is ", Math::MPFR::_GMP_NAIL_BITS, "\n" if defined Math::MPFR::_GMP_NAIL_BITS;

if   (pack("L", 305419897) eq pack("N", 305419897)) {warn "# Machine appears to be big-endian\n"}
elsif(pack("L", 305419897) eq pack("V", 305419897)) {warn "# Machine appears to be little-endian\n"}

warn "# Byte Order: ", $Config{byteorder}, "\n";

my($evaluate, $rebuild, $f128, $d64) = (0, 0, 0, 0);

eval {$evaluate = Rmpfr_buildopt_tls_p()};
if(!$@) {
  $evaluate ? warn "# mpfr library built WITH thread safety\n"
            : warn "# mpfr library built WITHOUT thread safety\n";
}

eval {$evaluate = Rmpfr_buildopt_decimal_p()};
if(!$@) {
  $evaluate ? warn "# mpfr library built WITH _Decimal64 support\n"
            : warn "# mpfr library built WITHOUT _Decimal64 support\n";

  if(!Math::MPFR::_MPFR_WANT_DECIMAL_FLOATS() && $evaluate) {$rebuild += 2}
  $d64 = 1 if $evaluate;
}

eval {$evaluate = Rmpfr_buildopt_float128_p()};
if(!$@) {
  $evaluate ? warn "# mpfr library built WITH __float128 support\n"
            : warn "# mpfr library built WITHOUT __float128 support\n";

  if(!Math::MPFR::_MPFR_WANT_FLOAT128() && $evaluate) {$rebuild += 1}
  $f128 = 1 if $evaluate;
}

eval {$evaluate = Rmpfr_buildopt_gmpinternals_p()};
if(!$@) {
  $evaluate ? warn "# mpfr library built WITH gmp internals\n"
            : warn "# mpfr library built WITHOUT gmp internals\n";
}

eval {$evaluate = Rmpfr_buildopt_sharedcache_p()};
if(!$@) {
  $evaluate ? warn "# mpfr library built WITH shared cache\n"
            : warn "# mpfr library built WITHOUT shared cache\n";
}

eval {$evaluate = Rmpfr_buildopt_tune_case()};
if(!$@) {
  $evaluate ? warn "# mpfr library thresholds file: $evaluate\n"
            : warn "# mpfr library thresholds file: $evaluate\n";
}

if($Math::MPFR::VERSION eq '4.09') {print "ok 1\n"}
else {print "not ok 1 $Math::MPFR::VERSION\n"}

if(Math::MPFR::_get_xs_version() eq '4.09') {print "ok 2\n"}
else {
  warn "Module version: $Math::MPFR::VERSION\nXS version: ", Math::MPFR::_get_xs_version(), "\n";
  print "not ok 2\n";
}

if(Rmpfr_get_version() eq MPFR_VERSION_STRING) {print "ok 3\n"}
else {print "not ok 3 - Header and Library do not match\n"}

my $max_base = Math::MPFR::_max_base();

if($max_base == 62) {
  if(3 <= MPFR_VERSION_MAJOR) {print "ok 4\n"}
  else {
    warn "\n\$max_base: $max_base\n";
    warn "VERSION_MAJOR ", MPFR_VERSION_MAJOR, "\n";
    print "not ok 4\n";
  }
}
elsif($max_base == 36) {
  if(3 > MPFR_VERSION_MAJOR) {print "ok 4\n"}
  else {
    warn "\n\$max_base: $max_base\n";
    warn "VERSION_MAJOR ", MPFR_VERSION_MAJOR, "\n";
    print "not ok 4\n";
  }
}
else {
  warn "\n\$max_base: $max_base\n";
  print "not ok 4\n";
}

if(Math::MPFR::_has_longlong() && Math::MPFR::_ivsize_bits() == (8 * $Config{ivsize})) {print "ok 5\n"}
elsif(!Math::MPFR::_has_longlong()) {print "ok 5\n"}
else {
  warn "\n _has_longlong(): ", Math::MPFR::_has_longlong(), "\n _ivsize_bits: ",
        Math::MPFR::_ivsize_bits(), "\n";
  print "not ok 5\n";
}

if($Math::MPFR::VERSION eq $Math::MPFR::Random::VERSION) {print "ok 6\n"}
else {
  warn "\$Math::MPFR::Random::VERSION: $Math::MPFR::Random::VERSION \n";
  print "not ok 6\n";
}

if($Math::MPFR::VERSION eq $Math::MPFR::Prec::VERSION) {print "ok 7\n"}
else {
  warn "\$Math::MPFR::Prec::VERSION: $Math::MPFR::Prec::VERSION \n";
  print "not ok 7\n";
}

if($Math::MPFR::VERSION eq $Math::MPFR::V::VERSION) {print "ok 8\n"}
else {
  warn "\$Math::MPFR::V::VERSION: $Math::MPFR::V::VERSION \n";
  print "not ok 8\n";
}

if($rebuild == 1) {
  if($d64) {
    warn "\nIndications are that your mpfr library was built with __float128 support\n",
         "I suggest rebuilding Math::MPFR with:\n",
         "     perl Makefile.PL D64=1 F128=1\n\n";
  }
  else {
    warn "\nIndications are that your mpfr library was built with __float128 support\n",
         "I suggest rebuilding Math::MPFR with:\n",
         "     perl Makefile.PL F128=1\n\n";
  }
}

if($rebuild == 2) {
  if($f128) {
    warn "\nIndications are that your mpfr library was built with _Decimal64 support\n",
         "I suggest rebuilding Math::MPFR with:\n",
         "     perl Makefile.PL F128=1 D64=1\n\n";
  }
  else {
    warn "\nIndications are that your mpfr library was built with _Decimal64 support\n",
         "I suggest rebuilding Math::MPFR with:\n",
         "     perl Makefile.PL D64=1\n\n";
  }
}

if($rebuild == 3) {
  warn "\nIndications are that your mpfr library was built with __float128 support\n",
       "  and with _Decimal64 support\n",
       "I suggest rebuilding Math::MPFR with:\n",
       "     perl Makefile.PL F128=1 D64=1\n\n";
}
