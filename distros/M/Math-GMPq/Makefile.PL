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

unless($Config{ivsize} < 8 || $Config{ivtype} eq 'long') {
  $defines .= " -DMATH_GMPQ_NEED_LONG_LONG_INT";
}


if($Config::Config{nvsize} > 8 ) {
    if($Config{nvtype} eq '__float128') {$use_quadmath = 1}
    else {$use_long_double = 1}
}


$defines =~ /-DMATH_GMPQ_NEED_LONG_LONG_INT/ ? print "Building with 64-bit'long long' support\n" :
                                 print "Building without 64-bit 'long long' support\n";

$use_long_double == 1 ? print "Building with 'long double' support\n" :
                               print "Building without 'long double' support\n";

$use_quadmath == 1    ? print "Building with '__float128' support\n" :
                                 print "Building without '__float128' support\n";


if($^O =~ /MSWin32/i && $] < 5.022) {$defines .= " -D_WIN32_BIZARRE_INFNAN"}

# Next, we check to see whether there's some unhelpful beaviour regarding
# the setting of the POK flag.
# This typically occurs in versions of perl prior to 5.22.0, but it can
# arise elsewhere, eg:
# http://www.cpantesters.org/cpan/report/dc52fbe6-900b-11ec-bfc9-d1f1448276d4
# This procedure is stolen from:
# https://metacpan.org/release/HAARG/Sub-Quote-2.006006/source/t/quotify.t
# Thank you, Haarg.

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

####################################

if($pv_nv_bug) {
  print "\n Defining GMPQ_PV_NV_BUG\n\n";
  $defines .= " -DGMPQ_PV_NV_BUG";
  $DEFS    .= " -DGMPQ_PV_NV_BUG";
}
else {
  print "\n Not defining GMPQ_PV_NV_BUG\n\n";
}

my %options = (
  NAME => 'Math::GMPq',
  AUTHOR => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  ABSTRACT => 'Perl interface to the GMP rational functions',
  DEFINE   => $defines,
  LIBS => [
    '-lgmp'
  ],
  LICENSE  => 'perl',
  VERSION_FROM => 'GMPq.pm',
  PREREQ_PM => {'Exporter' => '5.58', 'Test::More' => '0.88'},
  clean   => { FILES => 'out1.txt out2.txt out3.txt out4.txt out5.txt out6.txt out7.txt out21.txt out22.txt' },
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-gmpq.git',
        web => 'https://github.com/sisyphus/math-gmpq',
      },
    },
  },
);

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
# sub MY::makefile { '' }

