use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

#require 5.008008;

our %args = map { split /\s*=\s*/ } @ARGV;
our $LIBS = $args{ LIBS } || "-lmpfr -lgmp";
our $INC = $args{ INC };

my $use_64_bit_int  = 0;     # Let perl decide whether to include 64-bit 'long long' support
my $use_long_double = 0;     # Let perl decide whether to include 'long double' support
my $have_decimal64  = undef; # Default value
my $have_decimal128 = undef; # Default value
my $have_float128   = undef; # Default value
my $want_float128   = undef; # Default value
my $checklib        = 1;     # Check for availability of mpfr and gmp libraries.

#$checklib = 0;         # Uncomment to skip check of availability of mpfr and gmp libraries.
#$use_64_bit_int  = -1; # Uncomment to Force exclusion of 64-bit 'long long' support
#$use_long_double = -1; # Uncomment to Force exclusion of 'long double' support
#$have_decimal64  = -1; # Uncomment to Force exclusion of _Decimal64 support
#$have_decimal128 = -1; # Uncomment to Force exclusion of _Decimal128 support
#$have_float128   = -1; # Uncomment to Force exclusion of __float128/_Float128 support

#$use_64_bit_int  = 1; # Uncomment to Force inclusion of 64-bit 'long long' support
#$use_long_double = 1; # Uncomment to Force inclusion of 'long double' support
#$have_decimal64  = 1; # Uncomment to Force inclusion of _Decimal64 support
#$have_decimal128 = 1; # Uncomment to Force inclusion of _Decimal128 support
#$have_float128   = 1; # Uncomment to Force inclusion of __float128/_Float128 support

my $SAVE;
my $save = open $SAVE, '>', 'save_config.txt';

warn "Couldn't open save_config.txt for writing: $!" unless $save;

my($mycc, $mklib, $mkinc, $mylibpth) = ('', '', '', '') ;


if(@ARGV) {
  for my $arg(@ARGV) {
    $mycc   = (split /=/, $arg)[1] if $arg =~ /^cc=/i;
    $mklib = (split /=/, $arg)[1] if $arg =~ /^libs=/i;
    $mkinc  = (split /=/, $arg)[1] if $arg =~ /^inc=/i;
    $checklib = 0 if $arg =~ /^check=0/i;
  }
}

unless($mycc) {
  $mycc = defined($Config{cc}) ? $Config{cc} : 'cc';
}

my @libpth = split /\s+/, $Config{libpth};
for(@libpth) { $mylibpth .= " -L$_" }
$mylibpth .= " -lmpfr -lgmp";

###############################################################
# Check that -lmpfr and -lgmp can be found. Don't worry about #
# checking for mpfr.h and gmp.h - if they can't be found when #
# needed by a smoker then it won't be reported as a FAIL      #
###############################################################

if($checklib) {

  my $mylibs = $mklib . " " . $mylibpth;

  my $out = `$mycc -o checklib.exe -x c checklib.in $mylibs 2>&1`;

  if($out) {
    print "$out\n";
    if($save) {print $SAVE "checklib build: $out\n"}
  }

  if(-e 'checklib.exe') {
    $out = $^O =~ /MSWin32/i ? `checklib.exe` : `./checklib.exe`;
    if($save) {print $SAVE "checklib.exe: $out\n"}
  }
  else {
    warn "\n  Could not resolve '-lmpfr' and/or '-lgmp'\n",
         "  If this is incorrect please see the 'Checklib' section in the README\n",
         "  Aborting the build of Math::MPFR\n";
    exit 0;
  }
}

############################################
# Whether to build with _Decimal64 support #
############################################

if($have_decimal64) {$have_decimal64++} # $have_decimal64 is now either 0 or 2, depending
                                        # upon which of the above lines was uncommented

else { # we still need to determine whether_Decimal64 should be supported

  for(@ARGV) {
    $have_decimal64 = 1 if $_ eq 'D64=1';
    $have_decimal64 = 0 if $_ eq 'D64=0';
  }

  if(!defined($have_decimal64)) { # _Decimal64 support still undetermined

    my $mylibs = $mklib . " " . $mylibpth;

    my $out = `$mycc -o have_d64.exe -x c have_d64.in 2>&1`;

    if($out) {
      print "$out\n";
      if($save) {print $SAVE "try_64 build: $out\n"}
    }

    unless(-e 'have_d64.exe') {$have_decimal64 = 0}

    else { # _Decimal64 support still undetermined

      my $out = `$mycc -o try_dec64.exe -x c try_dec64.in $mkinc $mylibs 2>&1`;

      if($out) {
        print "$out\n";
        if($save) {print $SAVE "try_dec64 build: $out\n"}
      }

      if(-e 'try_dec64.exe') {
        $out = $^O =~ /MSWin32/i ? `try_dec64.exe` : `./try_dec64.exe`;
        if($out == 42) {$have_decimal64 = 1}
        if($save) {print $SAVE "try_dec64.exe: $out\n"}
      }
    }
  }
}

my $d64_message = $have_decimal64 ? "Attempting to build with Math::Decimal64 support\n"
                                  : "Building without Math::Decimal64 support\n";

#############################################



#############################################
# Whether to build with _Decimal128 support #
#############################################

if($have_decimal128) {$have_decimal128++} # $have_decimal128 is now either 0 or 2, depending
                                          # upon which of the above lines was uncommented

else { # we still need to determine whether_Decimal128 should be supported

  for(@ARGV) {
    $have_decimal128 = 1 if $_ eq 'D128=1';
    $have_decimal128 = 0 if $_ eq 'D128=0';
  }

  if(!defined($have_decimal128)) { # _Decimal128 support still undetermined

    my $mylibs = $mklib . " " . $mylibpth;

    my $out = `$mycc -o have_d128.exe -x c have_d128.in 2>&1`;

    if($out) {
      print "$out\n";
      if($save) {print $SAVE "try_128 build: $out\n"}
    }

    unless(-e 'have_d128.exe') {$have_decimal128 = 0}

    else { # _Decimal128 support still undetermined

      my $out = `$mycc -o try_dec128.exe -x c try_dec128.in $mkinc $mylibs 2>&1`;

      if($out) {
        print "$out\n";
        if($save) {print $SAVE "try_dec128 build: $out\n"}
      }

      if(-e 'try_dec128.exe') {
        $out = $^O =~ /MSWin32/i ? `try_dec128.exe` : `./try_dec128.exe`;
        if($out == 128) {$have_decimal128 = 1}
        if($save) {print $SAVE "try_dec128.exe: $out\n"}
      }
    }
  }
}

my $d128_message = $have_decimal128 ? "Attempting to build with Math::Decimal128 support\n"
                                    : "Building without Math::Decimal128 support\n";

###########################################



###########################################
# Whether to build with __foat128 support #
###########################################

if($have_float128) {$have_float128++} # $have_float128 is now either 0 or 2, depending
                                      # upon which of the above lines was uncommented

else { # we still need to determine whether__float128 should be supported.

  for(@ARGV) {
    $have_float128 = 1 if $_ eq 'F128=1';
    $have_float128 = 0 if $_ eq 'F128=0';
  }

  if(!defined($have_float128)) { # __float128 support still undetermined

    print $SAVE "\n\n" if $save;

    my $mylibs = $mklib . " " . $mylibpth . " -lquadmath";

    my $out = `$mycc -o have_f128.exe -x c have_f128.in 2>&1`;

    if($out) {
      print "$out\n";
      if($save) {print $SAVE "have_f128 build: $out\n"}
    }

    unless(-e 'have_f128.exe') {$have_float128 = 0}

    else {
      my $out = `$mycc -o try_flt128.exe -x c try_flt128.in $mkinc $mylibs 2>&1`;

      if($out) {
        print "$out\n";
        if($save) {print $SAVE "try_flt128 build: $out\n"}
      }

      if(-e 'try_flt128.exe') {
        $out = $^O =~ /MSWin32/i ? `try_flt128.exe` : `./try_flt128.exe`;
        if($out == 42) {$have_float128 = 1}
        if($save) {print $SAVE "try_flt128.exe: $out\n"}
      }
    }
  }
}

my $float128_message = $have_float128 ? "Attempting to build with Math::Float128 support\n"
                                      : "Building without Math::Float128 support\n";

####################################

close $SAVE or warn "Couldn't close save_config.txt";

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


$defines .= " -DMPFR_WANT_DECIMAL_FLOATS" if ($have_decimal64 || $have_decimal128);
$defines .= " -DMPFR_WANT_DECIMAL64"  if $have_decimal64;
$defines .= " -DMPFR_WANT_DECIMAL128" if $have_decimal128;
$defines .= " -DMPFR_WANT_FLOAT128"   if $have_float128;

print "\nThis module requires the following C libraries:\n";
print " gmp-4.2.0 (or later)\n mpfr-3.0.0 (or later)\n\n";
$defines =~ /\-DMATH_MPFR_NEED_LONG_LONG_INT/ ? print "Building with 'long long' support\n" :
                                 print "Building without 'long long' support\n";

print "If this is wrong, see the \"64-bit-int and long double support\" section in the README\n\n";

($defines =~ /\-DNV_IS_LONG_DOUBLE/ || $defines =~ /\-DNV_IS_FLOAT128/)
                                    ? print "Building with 'long double' support\n"
                                    : print "Building without 'long double' support\n";

print "If this is wrong, see the \"64-bit-int and long double support\" section in the README\n\n";

($defines =~ /\-DNV_IS_FLOAT128/) ? print "Building with support for a __float128 NV\n"
                                  : print "Building without support for a __float128 NV\n";

print "If this is wrong, see the \"__float128 NV\" conversion section in the README\n\n";

print "\n$d64_message";
print "If this is wrong, see the \"Decimal64 and Decimal128 conversion\" section in the README\n\n";

print "\n$d128_message";
print "If this is wrong, see the \"Decimal64 and Decimal128 conversion\" section in the README\n\n";

print "\n$float128_message";
print "If this is wrong, see the \"Math::Float128 conversion\" section in the README\n\n";

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

if($Config{nvsize} == 8) {
  my $fallback_notify = 1;
  for(@ARGV) {
    $fallback_notify = 0 if $_ eq "FB=0";
  }

  if($fallback_notify) {
    $defines .= " -DFALLBACK_NOTIFY";
    print "\ndoubletoa() fallback notification ENABLED (default)\n\n";
  }
  else { print "\ndoubletoa() fallback notification DISABLED\n\n" }
}

# The following defines serve as debugging
# aids for nvtoa() and doubletoa()
for(@ARGV) {
  $defines .= ' -DNVTOA_DEBUG'  if $_ =~ /NVTOA_DEBUG/i;  # prints out (to STDERR) intermediate
                                                          # values in nvtoa().
  $defines .= ' -DDTOA_ASSERT'   if $_ =~ /DTOA_ASSERT/i; # runs checks at various points in doubletoa()
                                                          # and croaks whenever a check fails.
}

# NOTE: The '-lquadmath' link we provide below
#       to 'LIBS' is generally not needed.
#       It is, however, currently needed on at
#       least some quadmath Cygwin builds.
#             Jan 8 2018.

my %options = (
  NAME         => 'Math::MPFR',
  AUTHOR       => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  ABSTRACT     => 'Perl interface to the MPFR (floating point) library',
  DEFINE       => $defines,
  LIBS         => [ '-lmpfr -lgmp -lquadmath' ],
  PREREQ_PM    => { 'Test::More' => '0.88', },
  #OBJECT       => '$(O_FILES)', # set below if $Config{nvsize} == 8
  LICENSE      => 'perl',
  VERSION_FROM => 'MPFR.pm',
  clean        => { FILES => '*.exe *.txt' },
  META_MERGE   => {
    'meta-spec'  => { version => 2 },
    resources    => {
      repository   => {
        type         => 'git',
        url          => 'https://github.com/sisyphus/math-mpfr.git',
        web          => 'https://github.com/sisyphus/math-mpfr',
      },
    },
  },
);

# Invlolve grisu3.h and grisu3.c if $Config{nvsize} == 8.
# Otherwise they're not needed :

$options{OBJECT} = '$(O_FILES)'
  if $Config{nvsize} == 8;

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }

