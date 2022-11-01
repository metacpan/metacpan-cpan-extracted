use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

require 5.006;

$| = 1;

our %args = map { split /\s*=\s*/ } @ARGV;
our $LIBS = $args{ LIBS } || "-lgmp";
our $INC = $args{ INC };
our $DEFS = '';

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

my $ld_broken = 0;
# use of "%.0Lf" formatting is unreliable on Cygwin -Duselongdouble
# builds of perl so we need to workaround that in mpz_set_NV.
# The workaround is to use "%.0Qf" (libquadmath) formatting.
$ld_broken = 1 if $^O =~ /cygwin/i && $Config{nvtype} eq 'long double' &&
  sprintf("%.0f", 2 ** 1000) ne '10715086071862673209484250490600018105614048117055336074437503883703510511249361224931983788156958581275946729175531468251871452856923140435984577574698574803934567774824230985421074605062371141877954182153046474983581941267398767559165543946077062914571196477686542167660429831652624386837205668069376';

########################################################
# If $ld_broken is true then we need to ensure
# that libquadmath will be found

if($ld_broken) {
  print "\nProbing (perhaps noisily) to see whether libquadmath is available:\n";
  my($mycc, $mklib, $mkinc, $mylibpth) = ('', '', '', '') ;

  if(@ARGV) {
    for my $arg(@ARGV) {
      $mycc   = (split /=/, $arg)[1] if $arg =~ /^cc=/i;
      $mklib = (split /=/, $arg)[1] if $arg =~ /^libs=/i;
    }
  }

  unless($mycc) {
    $mycc = defined($Config{cc}) ? $Config{cc} : 'cc';
  }

  my @libpth = split /\s+/, $Config{libpth};
  for(@libpth) { $mylibpth .= " -L$_" }
  $mylibpth .= " -lquadmath";

  my $mylibs = $mklib . " " . $mylibpth;

  my $out = `$mycc -o f128.exe -x c f128.in $mylibs 2>&1`;

  if(-e 'f128.exe') {
    $out = $^O =~ /MSWin32/i ? `f128.exe` : `./f128.exe`;
  }

  unless($out =~ /^quadmath is GO!!/) {
    print "Looking for the quadmath library resulted in:\n$out\n";
    print "Not defining LD_PRINTF_BROKEN because I cannot find the quadmath library";
    $ld_broken = 0;
  }
  else {
    print "Building with -DLD_PRINTF_BROKEN\n";
  }
}
########################################################

$defines .= ' -DLD_PRINTF_BROKEN' if $ld_broken;

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

my $libopts = '-lgmp';
$libopts    = '-lquadmath -lgmp'
  if ($^O eq 'cygwin' && ($use_quadmath || $ld_broken));

my %options = (
  NAME => 'Math::GMPz',
  AUTHOR => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  ABSTRACT => 'Perl interface to the GMP integer functions',
  DEFINE   => $defines,

  LIBS => [
    $libopts
  ],

  LICENSE  => 'perl',
  VERSION_FROM => 'GMPz.pm',
  clean        => { FILES => '*.exe *.txt' },
  META_MERGE   => {
   'meta-spec' => { version => 2 },
    resources  => {
      repository => {
        type => 'git',
        url  => 'https://github.com/sisyphus/math-gmpz.git',
        web  => 'https://github.com/sisyphus/math-gmpz',
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

# Next, we check to see whether there's some unhelpful beaviour regarding
# the setting of the POK flag - but only if $] < 5.035010.
# This typically occurs in versions of perl prior to 5.22.0, but it can
# arise elsewhere, eg:
# http://www.cpantesters.org/cpan/report/dc4f8aec-900b-11ec-bfc9-d1f1448276d4
# This procedure is stolen from:
# https://metacpan.org/release/HAARG/Sub-Quote-2.006006/source/t/quotify.t
# Thank you, Haarg.

if($] < 5.035010) {
  use B qw(svref_2object);

  my %flags;
  {
    no strict 'refs';
    for my $flag (qw(
      SVf_IOK
      SVf_NOK
      SVf_POK
      SVp_IOK
      SVp_NOK
      SVp_POK
              )) {
      if (defined &{'B::'.$flag}) {
       $flags{$flag} = &{'B::'.$flag};
      }
    }
  }

  sub flags {
    my $flags = B::svref_2object(\($_[0]))->FLAGS;
    join ' ', sort grep $flags & $flags{$_}, keys %flags;
  }

  my $pv_nv_bug = 0;
  my $test_nv = 1.3;
  my $buggery = "$test_nv";
  my $f = flags($test_nv);

  if($f =~ /SVf_POK/) {
    print "Dealing with unhelpful setting of POK flag\n";
    $pv_nv_bug = 1;
  }

  if($pv_nv_bug) {
    print "\n Defining GMPZ_PV_NV_BUG\n\n";
    $options{DEFINE} .= " -DGMPZ_PV_NV_BUG";
    $DEFS    .= " -DGMPZ_PV_NV_BUG";
  }
  else {
    print "\n Not defining GMPZ_PV_NV_BUG\n\n";
  }
}
else { print "Not defining GMPZ_PV_NV_BUG as perl version >= 5.035010\n\n" }

####################################

WriteMakefile(%options);

## We used to remove the Makefile dependency as it could cause problems on a few systems.
# But now we comment out the line that effected that removal. (No problems, so far.)
# sub MY::makefile { '' }


