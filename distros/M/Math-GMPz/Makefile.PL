use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

require 5.006;

$| = 1;

our %args = map { split /\s*=\s*/ } @ARGV;
our $LIBS = $args{ LIBS } || "-lgmp";
our $INC = $args{ INC };

print "\nThis module requires gmp-4.2.0 (or later)\n\n";

my $use_64_bit_int  = 0; # Let perl decide whether to include 64-bit 'long long' support
my $use_long_double = 0; # Let perl decide whether to include 'long double' support
my $use_quadmath    = 0; # Let perl decide whether to include 'quadmath' support

my $defines = $] < 5.008 ? "-DOLDPERL" : "-DNEWPERL";

# Comment out the next line of code to turn off the optimised overloading for
# Math::BigInt objects whose value is a Math::BigInt::GMP object.
# Overloading of such objects will then fall back to the (less efficient)
# method of overloading via stringification.
$defines .= " -DENABLE_MATH_BIGINT_GMP_OVERLOAD";

unless($Config::Config{ivsize} < 8 || $Config{ivtype} eq 'long') {
  $defines .= " -DMATH_GMPZ_NEED_LONG_LONG_INT";
}

if($Config::Config{nvsize} > 8 ) {
  if($Config{nvtype} eq '__float128') {$use_quadmath = 1}
  else                                {$use_long_double = 1}
}

$defines =~ /-DMATH_GMPZ_NEED_LONG_LONG_INT/ ? print "Building with 64-bit'long long' support\n"
                                              :print "Building without 64-bit 'long long' support\n";



$use_long_double == 1 ? print "Building with 'long double' support\n"
                      : print "Building without 'long double' support\n";

$use_quadmath == 1    ? print "Building with '__float128' support\n"
                      : print "Building without '__float128' support\n";

if($^O =~ /MSWin32/i && $] < 5.022)     { $defines .= " -D_WIN32_BIZARRE_INFNAN"}

# Assume that if the next condition is
# true, then the UV can hold a value
# that will overflow mp_bitcnt_t.
if($Config{longsize} < $Config{ivsize}) { $defines .= " -D_GMP_INDEX_OVERFLOW"  }

if($Config{sizesize} < $Config{ivsize}) { $defines .= " -D_GMP_SIZE_T_OVERFLOW" }

if((2 ** 100) + (2 ** -100) > 2 ** 100) { $defines .= " -DNV_IS_DOUBLEDOUBLE";
                                          print "NV is doubledouble\n"          }

my %options = (
  NAME => 'Math::GMPz',
  AUTHOR => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  ABSTRACT => 'Perl interface to the GMP integer functions',
  DEFINE   => $defines,

  LIBS => [
    '-lgmp'
  ],

  LICENSE  => 'perl',
  VERSION_FROM => 'GMPz.pm',

  clean   => { FILES => 'out1.txt out2.txt out3.txt out4.txt out5.txt out6.txt out7.txt out21.txt out22.txt' },
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-gmpz.git',
        web => 'https://github.com/sisyphus/math-gmpz',
      },
    },
  },
);

my $prereq =  { 'Test::More' => '0.88',
                'Test::Warn' => '0.36',
                'Exporter'   => '5.58', # avoid test failures on pre perl-5.8.4
              };

if($ExtUtils::MakeMaker::VERSION < 6.64) {
  $options{PREREQ_PM} = $prereq;
}
else {
  $options{TEST_REQUIRES} = $prereq;
}

WriteMakefile(%options);

## We used to remove the Makefile dependency as it could cause problems on a few systems.
# But now we comment out the line that effected that removal. (No problems, so far.)
# sub MY::makefile { '' }

