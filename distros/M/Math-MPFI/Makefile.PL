use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

require 5.008008;

our $DEFS = '';

warn "\n Version 1.5 (or later) of the mpfi C library\n",
     " (available from https://gforge.inria.fr/projects/mpfi)\n",
     " is needed to build this module\n";

my $use_64_bit_int = 0; # Let perl decide whether to include 64-bit 'long long' support
my $use_long_double = 0;# Let perl decide whether to include 'long double' support

#$use_64_bit_int = -1; # Force exclusion of 64-bit 'long long' support
#$use_long_double = -1;# Force exclusion of 'long double' support

#$use_64_bit_int = 1; # Force inclusion of 64-bit 'long long' support
#$use_long_double = 1;# Force inclusion of 'long double' support

# We want to set $have_float128 to 1 if:
# the mpfr library was built with the configure option '--enable-float128' &&
# $Config{nvtype} is '__float128'.
# To set $have_float128 to 1, we can either run 'perl Makefile.PL F128=1'
# or assign the value 1 to $have_float128 in the next line of code.

my $have_float128 = 0; # Assign 1 to force inclusion of __float128 support

# Logical thing to do is to set $have_float128 if Math::MPFR::_can_pass_float128() was set.
# So we do this in the following section.
# If there's a desire to override this, then that can be done by running 'perl Makefile.PL F128=0'.
eval{require Math::MPFR};
if(!$@ && $Math::MPFR::VERSION > 3.22) {
  $have_float128 = 1 if Math::MPFR::_can_pass_float128();
}

for(@ARGV) {
  $have_float128 = 0 if $_ eq 'F128=0';
  $have_float128 = 1 if $_ eq 'F128=1';
}

my $defines = $] < 5.008 ? "-DOLDPERL" : "-DNEWPERL";

if($use_64_bit_int == -1) {}
elsif($use_64_bit_int == 1) {$defines .= " -DMATH_MPFI_NEED_LONG_LONG_INT -DIVSIZE_BITS=" . (8 * $Config{ivsize})}
else {
  unless($Config{ivsize} < 8 || $Config{ivtype} eq 'long') {
    $defines .= " -DMATH_MPFI_NEED_LONG_LONG_INT -DIVSIZE_BITS=" . (8 * $Config{ivsize});
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

if($Config::Config{nvtype} eq 'double') {$defines .= " -DNV_IS_DOUBLE"}

$defines .= " -DMPFR_WANT_FLOAT128" if $have_float128;

print "\nThis module requires the following C libraries:\n";
print " gmp-4.2.0 (or later)\n mpfr-2.3.0 (or later)\n\n";
$defines =~ /-DMATH_MPFI_NEED_LONG_LONG_INT/ ? print "Building with 64-bit'long long' support\n" :
                                 print "Building without 64-bit 'long long' support\n";

print "If this is wrong, see the \"64-bit support\" section in the README\n\n";

$defines =~ /-DNV_IS_LONG_DOUBLE/ ? print "Building with 'long double' support\n" :
                                 print "Building without 'long double' support\n";

print "If this is wrong, see the \"64-bit support\" section in the README\n\n";

if($Config{nvtype} eq '__float128') {print "Attempting to build with __float128 support\n"}
else {print "Building without __float128 support\n"}
print "If this is wrong, see the \"Float128 conversion\" section in the README\n\n";

if($^O =~ /MSWin32/i && $] < 5.022) {
  $defines .= " -D_WIN32_BIZARRE_INFNAN";
}

####################################
# Next, we check to see whether there's some unhelpful beaviour regarding
# the setting of the POK flag - but only if $] < 5.035010.
# This typically occurs in versions of perl prior to 5.22.0, but it can
# arise elsewhere, eg:
# http://www.cpantesters.org/cpan/report/dc17e330-900b-11ec-bfc9-d1f1448276d4
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
    $defines .= " -DMPFI_PV_NV_BUG";
    $DEFS    .= " -DMPFI_PV_NV_BUG";
    print "Defining MPFI_PV_NV_BUG\n\n";
  }
  else {
    print "Not defining MPFI_PV_NV_BUG\n\n";
  }
}
else { print "Not defining MPFI_PV_NV_BUG as perl version >= 5.035010\n\n" }
####################################


my %options = (
  NAME => 'Math::MPFI',
  INC => '',
  AUTHOR => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  LIBS => '-lmpfi -lmpfr -lgmp',
  VERSION_FROM => 'MPFI.pm',
  PREREQ_PM => {'Math::MPFR' => '3.23', 'Test::More' => '0.88'},
  LICENSE  => 'perl',
  DEFINE   => $defines,
  clean   => { FILES => 'save_child_setting.txt' },
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-mpfi.git',
        web => 'https://github.com/sisyphus/math-mpfi',
      },
    },
  },
);

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
