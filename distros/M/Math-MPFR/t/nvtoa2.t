# Additional nvtoa() testing.

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;
use Test::More;

# We'll check a list of 10000 randomly derived NV values.
# The mantissa of each NV will be between 1 and $MAX_DIG decimal digits.
# Neither the first nor last mantissa digit will be zero
# The exponent will be in the range -$MAX_POW..$MAX_POW
# Exponents will alternate between -ve and +ve
# Every third mantissa will be negative.
# We call nvtoa_test() to check that nvtoa() has returned the correct value.
#
# In this script we test the correctness of nvtoa() differently, depending upon
# whether perl is prone to mis-assignment of values, or not.
#
# For perls whose NV is the "Double-Double" long double or for perls running on Cygwin, perl
# is prone to mis-assignment and $reliable is set to false, irrespective of the value of $].
#
# All perl's whose nvtype is __float128 (except those running on Cygwin) assign correctly and
# $reliable is set to true for them, irrespective of the value of $] ... except that on MS
# Windows and (apparently) at least one instance of i686 linux (see
# http://www.cpantesters.org/cpan/report/11de736c-0cd6-11ec-aef5-c3a30c210c3d), assignment of
# subnormal values (within a specific range) is unreliable.
#
# For all other builds of perl, $reliable will be set to true if and only if:
# 1) $] >= 5.03 && $Config{nvtype} eq 'double' && defined($Config{d_strtod})
# OR
# 2) $] >= 5.03 && $Config{nvtype} eq 'long double' && defined($Config{d_strtold})
#
# $reliable is set to false for all remaining perls that have not been specified above.
#
# If $reliable is true, we simply assign the values using perl - otherwise we assign them
# using Math::MPFR's atonv() function, which is also deemed reliable.

if(MPFR_VERSION_MAJOR < 3 || (MPFR_VERSION_MAJOR() == 3  && MPFR_VERSION_PATCHLEVEL < 6)) {
  plan skip_all => "nvtoa2.t utilizes Math::MPFR functionality that requires mpfr-3.1.6\n";
  exit 0;
}

my $MAX_DIG;
my $MAX_POW;
my $ok = 1;

if   ($Math::MPFR::NV_properties{bits} == 53)  { $MAX_DIG = 17;
                                                 $MAX_POW = 350;
                                               }
elsif($Math::MPFR::NV_properties{bits} == 64)  { $MAX_DIG = 21;
                                                 $MAX_POW = 5000;
                                               }
elsif($Math::MPFR::NV_properties{bits} == 113) { $MAX_DIG = 36;
                                                 $MAX_POW = 5000;
                                               }
else                                           { $MAX_DIG = 34;   # NV is Double-Double
                                                 $MAX_POW = 350;
                                               }

my $reliable = 0;

my $subnormal_issue = 0;

if($Config{nvtype} eq '__float128') {
 $subnormal_issue = 1 if $^O =~/MSWin/;

 # If 803e-4944 is mis-assigned to the value given below,
 # then, until evidence to the contrary is provided, we assume
 # that we are facing the bug with subnormals described at:
 # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=94756
 $subnormal_issue = 1 if sprintf('%a', 803e-4944) eq '0x1.069b16b796df96f69cf7p-16414';
}

if(
   $^O !~/cygwin/i
   && (
       $Config{nvtype} eq '__float128'
       ||
       ($] > 5.029005 && $Config{nvtype} eq 'double' && defined($Config{d_strtod}))
       ||
       ($] > 5.029005 && $Config{nvtype} eq 'long double' && defined($Config{d_strtold}) && $MAX_DIG != 34)
      )
  ) {

  if( $subnormal_issue ) {
    warn "\n Using perl for string to NV assignment ... unless the NV's\n",
         " absolute value is in the range:\n",
         "  0x1p-16414 .. 0x1.ffffffffffffffffffffp-16414\n",
         "  or\n",
         "  0x1.00000318p-16446 .. 0x1.ffffffffffffp-16446\n",
         " See https://gcc.gnu.org/bugzilla/show_bug.cgi?id=94756\n";
  }
  else {
    warn "Using perl for string to NV assignment. (Perl deemed reliable)\n";
  }

  $reliable = 1;
}
else {
  warn "Avoiding perl for string to NV assignment. (Perl is UNRELIABLE)\n";
}

my $count = 10000;

while(1) {
  $count--;
  last if $count < 0;
  my $mantissa_sign = $count % 3 ? '' : '-';
  my $mantissa = 1 + int(rand(9));
  my $exponent = int(rand($MAX_POW));

  # Skew the exponent towards the more usual values that are typically used.
  # nvtoa() calculations are relatively expensive on long double and __float128
  # builds for NVs whose exponents are a long way from zero.
  $exponent = int(rand(10)) if ($exponent > 50 && $exponent < $MAX_POW / 1.5);
  $exponent = '-' . $exponent if ($count & 1);

  my $len = int(rand($MAX_DIG));

  while(length($mantissa) < $len) { $mantissa .= int(rand(10)) }
  $mantissa .= 1 +int(rand(9)) if $len;

  my $str = $mantissa_sign . $mantissa . 'e' . $exponent;
  my $s_copy = $mantissa_sign . $mantissa . 'e' . $exponent;
  my $float128_subnormal_issue = 0;
  if($subnormal_issue) {
    $float128_subnormal_issue = float128_subnormal_problem($s_copy * 1.0);
  }
  my $nv;

  if($reliable && !$float128_subnormal_issue) {
    $nv = $str * 1.0;
  }
  else {
    $nv = atonv($str);
  }

  my $nvtoa = nvtoa($nv);

  ok(nvtoa_test($nvtoa, $nv) == 7, "$str");

}

done_testing();

sub float128_subnormal_problem {

  # Values inside these ranges are not assigned correctly on MS Windows.
  # See https://gcc.gnu.org/bugzilla/show_bug.cgi?id=94756
  if( (abs($_[0]) <= 1.56560127768297377334100959207326356e-4941 && abs($_[0]) >= 2 ** -16414)
        ||
      (abs($_[0]) <= 3.64519953188246812735328649559430889e-4951 && abs($_[0]) >= 1.82260010203204199023661059308858291e-4951  )
 ) {
  return 1; # problem exists
  }
return 0;   # no problem
}

__END__
