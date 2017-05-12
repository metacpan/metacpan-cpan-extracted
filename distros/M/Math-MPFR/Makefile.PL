use ExtUtils::MakeMaker;
use Config;
#require 5.008008;

our %args = map { split /\s*=\s*/ } @ARGV;
our $LIBS = $args{ LIBS } || "-lmpfr -lgmp";
our $INC = $args{ INC };

$use_64_bit_int = 0; # Let perl decide whether to include 64-bit 'long long' support
$use_long_double = 0;# Let perl decide whether to include 'long double' support

#$use_64_bit_int = -1; # Force exclusion of 64-bit 'long long' support
#$use_long_double = -1;# Force exclusion of 'long double' support

#$use_64_bit_int = 1; # Force inclusion of 64-bit 'long long' support
#$use_long_double = 1;# Force inclusion of 'long double' support

$have_decimal64 = 0;
for(@ARGV) {
  $have_decimal64 = 1 if $_ eq 'D64=1';
}
#$have_decimal64 = 1; # Force inclusion of _Decimal64 support
                      # This will also define MPFR_WANT_DECIMAL_FLOATS (as that needs to be defined
                      # before mpfr.h is included).

my $d64_message = $have_decimal64 ? "Attempting to build with _Decimal64 support\n"
                                  : "Building without _Decimal64 support\n";

# We want to set $have_float128 to 1 if and only if:
# the mpfr library was built with the configure option '--enable-float128' && either:
#  $Config{nvtype} is '__float128'
#   or
#  Math::Float128 has been installed.

$have_float128 = 0;
for(@ARGV) {
  $have_float128 = 1 if $_ eq 'F128=1';
}
#$have_float128 = 1; # Force inclusion of __float128 support
                      # This will also define MPFR_WANT_FLOAT128 (as that needs to be defined
                      # before mpfr.h is included).

my $float128_message = $have_float128 ? "Assuming that the mpfr library was built with __float128 support\n"
                                  : "NOT assuming that the mpfr library was built with __float128 support\n";

my $defines = $] < 5.008 ? "-DOLDPERL" : "-DNEWPERL";

if($use_64_bit_int == -1) {}
elsif($use_64_bit_int == 1) {$defines .= " -DMATH_MPFR_NEED_LONG_LONG_INT -DIVSIZE_BITS=" . (8 * $Config{ivsize})}
else {
  unless($Config{ivsize} < 8 || $Config{ivtype} eq 'long') {
    $defines .= " -DMATH_MPFR_NEED_LONG_LONG_INT -DIVSIZE_BITS=" . (8 * $Config{ivsize});
  }
}

if($use_long_double == -1) {}
elsif($use_long_double == 1) {
  $defines .= " -DNV_IS_FLOAT128" if $Config{nvtype} eq '__float128';
  $defines .= " -DNV_IS_LONG_DOUBLE" if $Config{nvtype} eq 'long double';
}
else {
  if($Config::Config{nvsize} > 8 ) {
    $defines .= " -DNV_IS_FLOAT128" if $Config{nvtype} eq '__float128';
    $defines .= " -DNV_IS_LONG_DOUBLE" if $Config{nvtype} eq 'long double';
  }
}

$defines .= " -DMPFR_WANT_DECIMAL_FLOATS" if $have_decimal64;
$defines .= " -DMPFR_WANT_FLOAT128" if $have_float128;

print "\nThis module requires the following C libraries:\n";
print " gmp-4.2.0 (or later)\n mpfr-2.4.0 (or later)\n\n";
$defines =~ /\-DMATH_MPFR_NEED_LONG_LONG_INT/ ? print "Building with 'long long' support\n" :
                                 print "Building without 'long long' support\n";

print "If this is wrong, see the \"64-bit support\" section in the README\n\n";

($defines =~ /\-DNV_IS_LONG_DOUBLE/ || $defines =~ /\-DNV_IS_FLOAT128/)
                                    ? print "Building with 'long double' support\n"
                                    : print "Building without 'long double' support\n";

print "If this is wrong, see the \"64-bit support\" section in the README\n\n";

($defines =~ /\-DNV_IS_FLOAT128/) ? print "Building with '__float128' support\n"
                                 : print "Building without '__float128' support\n";

print "If this is wrong, see the \"Float128 conversion\" section in the README\n\n";

print "\n$d64_message";
print "If this is wrong, see the \"Decimal64 conversion\" section in the README\n\n";

print "\n$float128_message";
print "If this is wrong, see the \"Float128 conversion\" section in the README\n\n";

$defines .= $Config::Config{byteorder} =~ /^1234/ ? " -DMPFR_HAVE_LENDIAN" : " -DMPFR_HAVE_BENDIAN";

if(defined $Config{longdblkind}) {
  if($Config{longdblkind} == 1 || $Config{longdblkind} == 2) {
    $defines .= " -DHAVE_IEEE_754_LONG_DOUBLE";
  }
  if($Config{longdblkind} == 3 || $Config{longdblkind} == 4) {
    $defines .= " -DHAVE_EXTENDED_PRECISION_LONG_DOUBLE";
  }
}

$defines .= " -DNV_IS_DOUBLE"
  if $Config{nvtype} eq 'double';

if($^O =~ /MSWin32/i && $] < 5.022) {
  $defines .= " -D_WIN32_BIZARRE_INFNAN";
}


my %options = (
  NAME => 'Math::MPFR',
  AUTHOR => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  ABSTRACT => 'Perl interface to the MPFR (floating point) library',
  DEFINE   => $defines,
  LIBS => [
    '-lmpfr -lgmp'
  ],
  LICENSE  => 'perl',
  VERSION_FROM => 'MPFR.pm',
  clean   => { FILES => 'out1.txt out2.txt out3.txt out4.txt out5.txt out6.txt out7.txt save_child_setting.txt p_spec.txt fpif.txt' },
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-mpfr.git',
        web => 'https://github.com/sisyphus/math-mpfr',
      },
    },
  },
);

my %prereq = ();
$prereq{'Math::Decimal64'} = '0.01' if $have_decimal64;
$prereq{'Math::Float128'}  = '0.01' if ($have_float128 && $Config{nvtype} ne '__float128');

$options{PREREQ_PM} = \%prereq;

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }

