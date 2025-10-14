use warnings;
use strict;
use Config;
use Math::MPFR qw(:mpfr);
use Math::MPFR::V;

use Test::More;

#print "1..10\n";

warn "\n# Using Math::MPFR version     ", $Math::MPFR::VERSION, "\n";
warn "# MPFR_VERSION is              ", MPFR_VERSION, "\n";
warn "# Using mpfr library version   ", MPFR_VERSION_STRING, "\n";
warn "# Using gmp library version    ", Math::MPFR::gmp_v(), "\n";
warn "# GMP_LIMB_BITS is             ", Math::MPFR::_GMP_LIMB_BITS, "\n" if defined Math::MPFR::_GMP_LIMB_BITS;
warn "# GMP_NAIL_BITS is             ", Math::MPFR::_GMP_NAIL_BITS, "\n" if defined Math::MPFR::_GMP_NAIL_BITS;
warn "# __GMP__CFLAGS is             ", Math::MPFR::_gmp_cflags(), "\n";
warn "# __GMP__CC is                 ", Math::MPFR::_gmp_cc(), "\n";
warn "# sizeof mpfr_exp_t:           ", Math::MPFR::_sizeof_exp(), " bytes\n";
warn "# sizeof mpfr_prec_t:          ", Math::MPFR::_sizeof_prec(), " bytes\n";
warn "# has _WIN32_BIZARRE_INFNAN:   ", Math::MPFR::_has_bizarre_infnan(), "\n";
warn "# has MPFR_PV_NV_BUG:          ", Math::MPFR::_has_pv_nv_bug(), "\n";
warn "# has WIN32_FMT_BUG:           ", Math::MPFR::Random::_buggy(), "\n";
warn "# has _Float16                 ", Math::MPFR::_have_float16(), "\n";
warn "# has __bf16                   ", Math::MPFR::_have_bfloat16(), "\n";
warn "# MPFR_PREC_MIN                ", Math::MPFR::MPFR_PREC_MIN, "\n";

if   (pack("L", 305419897) eq pack("N", 305419897)) {warn "# Machine appears to be big-endian\n"}
elsif(pack("L", 305419897) eq pack("V", 305419897)) {warn "# Machine appears to be little-endian\n"}

warn "# Byte Order: ", $Config{byteorder}, "\n";

my($evaluate, $f128, $d64) = (0, 0, 0, 0);

eval {$evaluate = Rmpfr_buildopt_tls_p()};
if(!$@) {
  $evaluate ? warn "# mpfr library built WITH thread safety\n"
            : warn "# mpfr library built WITHOUT thread safety\n";
}

eval {$evaluate = Rmpfr_buildopt_decimal_p()};
if(!$@) {
  $evaluate ? warn "# mpfr library built WITH _Decimal64 support\n"
            : warn "# mpfr library built WITHOUT _Decimal64 support\n";

  if(262400 <= MPFR_VERSION()){
    $evaluate ? warn "# mpfr library built WITH _Decimal128 support\n"
              : warn "# mpfr library built WITHOUT _Decimal128 support\n";
  }

  $d64 = 1 if $evaluate;
}

eval {$evaluate = Rmpfr_buildopt_float128_p()};
if(!$@) {
  $evaluate ? warn "# mpfr library built WITH __float128 support\n"
            : warn "# mpfr library built WITHOUT __float128 support\n";

  $f128 = 1 if $evaluate;
}

eval {$evaluate = Rmpfr_buildopt_float16_p()};
if(!$@) {
  $evaluate ? warn "# mpfr library built WITH _Float16 support\n"
            : warn "# mpfr library built WITHOUT _Float16 support\n";
}

eval {$evaluate = Rmpfr_buildopt_bfloat16_p()};
if(!$@) {
  $evaluate ? warn "# mpfr library built WITH bfloat16 support\n"
            : warn "# mpfr library built WITHOUT bfloat16 support\n";
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

cmp_ok($Math::MPFR::VERSION, 'eq', '4.45', "Math::MPFR::VERSION ($Math::MPFR::VERSION) is as expected");

my $xs_version = Math::MPFR::_get_xs_version();
cmp_ok($xs_version, 'eq', '4.45', "Math::MPFR::_get_xs_version returns $xs_version as expected");

my $l_ver = Rmpfr_get_version();
my $h_ver = MPFR_VERSION_STRING;

cmp_ok($h_ver, 'eq', $l_ver, "Header version ($h_ver) matches Library version ($l_ver)");

my $max_base = Math::MPFR::_max_base();

if(3 <= MPFR_VERSION_MAJOR) {
  cmp_ok($max_base, '==', 62, "maximum base ($max_base) == 62");
}
else {
  cmp_ok($max_base, '==', 36, "maximum base ($max_base) == 36");
}

my $iv_bits = 8 * $Config{ivsize};

if(Math::MPFR::_has_longlong()) {
  cmp_ok(Math::MPFR::_ivsize_bits(), '==', $iv_bits, "IVSIZE_BITS set to expected value of $iv_bits");
}

cmp_ok($Math::MPFR::VERSION, 'eq',  $Math::MPFR::Random::VERSION,
       "Math::MPFR version ($Math::MPFR::VERSION) eq Math::MPFR::Random version ($Math::MPFR::Random::VERSION)");

cmp_ok($Math::MPFR::VERSION, 'eq',  $Math::MPFR::Prec::VERSION,
       "Math::MPFR version ($Math::MPFR::VERSION) eq Math::MPFR::Prec version ($Math::MPFR::Prec::VERSION)");

cmp_ok($Math::MPFR::VERSION, 'eq',  $Math::MPFR::V::VERSION,
       "Math::MPFR version ($Math::MPFR::VERSION) eq Math::MPFR::V version ($Math::MPFR::V::VERSION)");

cmp_ok(Math::MPFR::Random::_MPFR_VERSION(), '==', Math::MPFR::_MPFR_VERSION(),
       "Math::MPFR::Random::_MPFR_VERSION() == Math::MPFR::_MPFR_VERSION()");

my $v = Math::MPFR::_sis_perl_version;
my $v_check = $];
$v_check =~ s/\.//;

if($] =~ /^5\./) {
  cmp_ok($v, '==', $v_check, 'Math::MPFR::_sis_perl_version agrees with $]');
}
else {
  # $] no longer matches /^5\./
  # Just checking that Math::MPFR::_sis_perl_version > 5012000 will suffice.
  cmp_ok($v, '>', 5012000, 'Math::MPFR::_sis_perl_version > 5012000');
}

if($^O =~ /^MSWin/) {
  if(WIN32_FMT_BUG) {
    # Check that if WIN32_FMT_BUG is set, then "-D__USE_MINGW_ANSI_STDIO"
    # is missing from both __GMP_CC and __GMP_CFLAGS
    unlike(Math::MPFR::_gmp_cflags(), qr/\-D__USE_MINGW_ANSI_STDIO/, "-D__USE_MINGW_ANSI_STDIO missing from __GMP_CFLAGS");
    unlike(Math::MPFR::_gmp_cc(),     qr/\-D__USE_MINGW_ANSI_STDIO/, "-D__USE_MINGW_ANSI_STDIO missing from __GMP_CC");
  }

  if(Math::MPFR::_gmp_cflags =~ /\-D__USE_MINGW_ANSI_STDIO/ ||
     Math::MPFR::_gmp_cc()   =~ /\-D__USE_MINGW_ANSI_STDIO/ ) {
    # Check that if "-D__USE_MINGW_ANSI_STDIO" is present  in either
    # of __GMP_CC and __GMP_CFLAGS then WIN32_FMT_BUG is set to 0.
    cmp_ok(WIN32_FMT_BUG, '==', 0, "WIN32_FMT_BUG set to zero");
  }
}

cmp_ok(RMPFR_PREC_MIN, '==', Math::MPFR::MPFR_PREC_MIN, 'MPFR_PREC_MIN setting is consistent');

done_testing();


