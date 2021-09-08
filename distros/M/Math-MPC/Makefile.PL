use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

require 5.008008;

my $do_complex_h = 0; # Let the Makefile.PL decide whether to support the double _Complex and
                   # long double _Complex data types.
#$do_complex_h = 1; # Force inclusion of the double _Complex, long double _Complex and __float128 _Complex data types
#$do_complex_h = -1;# Force exclusion of the double _Complex, long double _Complex and __float128 _Complex data types

unless ($do_complex_h) {
  eval {require Math::Complex_C;};
  $do_complex_h = $@ ? -1 : 1;
}

unless ($do_complex_h) {
  eval {require Math::Complex_C::L;};
  $do_complex_h = $@ ? -1 : 1;
}

unless ($do_complex_h) {
  eval {require Math::Complex_C::Q;};
  $do_complex_h = $@ ? -1 : 1;
}

my $use_64_bit_int = 0; # Let perl decide whether to include 64-bit 'long long' support
my $use_long_double = 0;# Let perl decide whether to include 'long double' support

#$use_64_bit_int = -1; # Force exclusion of 64-bit 'long long' support
#$use_long_double = -1;# Force exclusion of 'long double' support

#$use_64_bit_int = 1; # Force inclusion of 64-bit 'long long' support
#$use_long_double = 1;# Force inclusion of 'long double' support

print "\nThis module requires the following C libraries:\n";
print " gmp-4.3.2 (or later)\n mpfr-2.4.2 (or later)\n mpc-0.8 (or later)\n\n";

my $defines = $] < 5.008 ? "-DOLDPERL" : "-DNEWPERL";

if($use_64_bit_int == -1) {}
elsif($use_64_bit_int == 1) {$defines .= " -DMATH_MPC_NEED_LONG_LONG_INT"}
else {
  unless($Config{ivsize} < 8 || $Config{ivtype} eq 'long') {
    $defines .= " -DMATH_MPC_NEED_LONG_LONG_INT";
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

my $have_float128 = 0;
for(@ARGV) {
  $have_float128 = 1 if $_ eq 'F128=1';
}

$defines .= " -DMPFR_WANT_FLOAT128" if $have_float128;

if($do_complex_h == 1) { $defines .= " -D_DO_COMPLEX_H"}

$defines =~ /\-DMATH_MPC_NEED_LONG_LONG_INT/ ? print "Building with 64-bit'long long' support\n" :
                                 print "Building without 64-bit 'long long' support\n";

print "If this is wrong, see the \"64-bit support\" section in the README\n\n";

($defines =~ /\-DNV_IS_LONG_DOUBLE/ || $defines =~ /\-DNV_IS_FLOAT128/)
                                 ? print "Building with 'long double' support\n"
                                 :print "Building without 'long double' support\n";

print "If this is wrong, see the \"64-bit support\" section in the README\n\n";

($defines =~ /\-DNV_IS_FLOAT128/) ? print "Building with '__float128' support (because nvtype is __float128)\n\n"
                                 : print "Building without '__float128' support (because nvtype is not __float128)\n\n";

($defines =~ /\-D_DO_COMPLEX_H/) ? print "Trying to build with 'double _Complex' & 'long double _Complex' support\n" :
                                 print "Building without 'double _Complex' & 'long double _Complex' support\n";

print "If this is wrong, see the \"_Complex C types support\" section in the README\n\n";

$defines .= " -DNV_IS_DOUBLE" if $Config{nvtype} eq 'double';

if($^O =~ /MSWin32/i && $] < 5.022) {
  $defines .= " -D_WIN32_BIZARRE_INFNAN";
}

my %options = (
  NAME => 'Math::MPC',
  AUTHOR => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  ABSTRACT => 'Perl interface to the MPC (multi precision complex) library',
  PREREQ_PM => {
                'Math::MPFR'          => '4.14',
                'ExtUtils::MakeMaker' => '6.58',
                'Test::More'          => '0.88',
               },
  DEFINE   => $defines,
  LIBS => [
    '-lmpc -lmpfr -lgmp'
  ],
  LICENSE  => 'perl',
  VERSION_FROM => 'MPC.pm',
  clean   => { FILES => 'out1.txt out2.txt out3.txt out4.txt out5.txt out6.txt out7.txt out8.txt save_child_setting.txt' },
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-mpc.git',
        web => 'https://github.com/sisyphus/math-mpc',
      },
    },
  },
);

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }

