
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

if($Config{cc} eq 'cl') {
  warn "\n  WARNING: The sqrt and ** (pow) overloading can be buggy\n",
       "             on MSVC-built perls. (See the README file.)\n\n";
}

my $defines = '';
my $log = './myconfig.log';
my $open = open WR, '>', $log;
print "Couldn't open $log for writing: $!\n" unless $open;

###############################################

# Try to detect fatal linking error with erfl() ahead of time. If we detect
# that this linking problem exists, we then abort the Makefile.PL then
# and there. This doesn't do anything useful beyond avoiding cpan-tester FAIL reports.
# To avoid being subjected to the abort, just comment out lines 51 and 70 below
# (which are both "exit 0;")

my $cc;

if(@ARGV) {
  for my $arg(@ARGV) {
    $cc = (split /=/, $arg)[1] if $arg =~ /^cc=/i;
  }
}

unless(defined($cc)) {
  $cc = defined($Config{cc}) ? $Config{cc} : 'cc';
}

my $opt = $Config{optimize};

print WR "\nCC = $cc\nOPTMIZE = $opt\n" if $open;

# Build with "-Wno-implicit-function-declaration" to work around the problem of
# such warnings being fatal with gcc-14 and later.
my $out = `$cc $opt -Wno-implicit-function-declaration -o try.exe -x c try.in -lm 2>&1`;

print WR "erfl & isnanl check (build): $out\n" if $open;

# No linking problem yet if try.exe exists.
unless(-e 'try.exe') {
  if($out =~ /(`|'|"|\s)_?erfl('|`|"|\s)/) {
    print "Aborting:\n$out\n";
    close WR if $open;
    unlink $log if -e $log;
    exit 0; # abort the build
  }

# Also check whether isnanl() is available and
# implement a workaround if it's not.

  if($out =~ /(`|'|"|\s)_?isnanl('|`|"|\s)/) {
    $defines .= ' -DISNANL_IS_UNAVAILABLE';
  }
}

# But now we need to see whether the linking problem doesn't show up until runtime.
else {
  my $diag = $^O =~ /mswin32/i ? `try.exe 0.6 2>&1` : `./try.exe 0.6 2>&1`;
  if(defined($diag)) {
    print WR "erfl & isnanl check (run): $diag\n" if $open; # 66
    if($diag =~ /(`|'|"|\s)_?erfl('|`|"|\s)/) {             # 67
      print "Aborting:\n$diag\n";
      close WR if $open;
      unlink $log if -e $log;
      exit 0; # abort the build
    }
  }
  else {
    print WR "Unable to obtain diagnostics re erfl() - assuming it's available\n" if $open;
  }
}

###############################################
# Try to detect whether nanl() is available and
# implement a workaround if it's not.

$out = `$cc $opt -o try3.exe -x c try3.in -lm 2>&1`;

print WR "build output (nanl check): $out\n" if $open;

# No linking problem at all if try3.exe exists.
unless(-e 'try3.exe') {

  if($out =~ /(`|'|"|\s)_?nanl('|`|"|\s)/) {
    $defines .= ' -DNANL_IS_UNAVAILABLE';
  }
}
else {
  my $diag = $^O =~ /mswin32/i ? `try3.exe 0 2>&1` : `./try3.exe 0 2>&1`;
  if(defined($diag)) {
    print WR "execution output (nanl check): $diag\n" if $open;   # 99
    unless ($diag =~ /^rop /) {                                   # 100
      $defines .= ' -DNANL_IS_UNAVAILABLE';
    }
  }
  else {
    print WR "Unable to obtain diagnostics re nanl() - assuming it's available\n" if $open;
  }
}

###############################################

# Try to detect a nan bug that has nan**0 is nan.
# (Correct implementations have nan**0 == 1.)

$out = `$cc $opt -o try2.exe -x c $defines try2.in -lm 2>&1`;

sleep 1;

print WR "build output (nan**0 check):\n$out\n" if $open;

my $diag = $^O =~ /mswin32/i ? `try2.exe nan 0 2>&1` : `./try2.exe nan 0 2>&1`;

if(defined($diag)) {
  print WR "nan**0 check diagnostic: $diag\n" if ($open);
  $defines .= ' -DNAN_POW_BUG' if $diag =~ /^NaN/i;     # 120
}
else {
    print WR "Unable to determine if nan**0 is buggy - assuming it's NOT buggy\n" if $open;
}

###############################################

# Try to detect whether signbitl() is available and
# implement a workaround if it's not.

# Build with "-Wno-implicit-function-declaration" to work around the problem of
# such warnings being fatal with gcc-14 and later.
$out = `$cc $opt -Wno-implicit-function-declaration -o try4.exe -x c try4.in -lm 2>&1`;

print WR "build output (signbitl check): $out\n" if $open;

# No linking problem yet if try4.exe exists.
unless(-e 'try4.exe') {
  if($out =~ /(`|'|"|\s)_?signbitl('|`|"|\s)/) {
    $defines .= ' -DSIGNBITL_IS_UNAVAILABLE';
  }
}
else {
  my $diag = $^O =~ /mswin32/i ? `try4.exe 0 2>&1` : `./try4.exe 0 2>&1`;
  if(defined($diag)) {
    print WR "execution output (signbitl check): $diag\n" if $open;        # 139
    unless ($diag =~ /^ret /) {                                            # 140
      $defines .= ' -DSIGNBITL_IS_UNAVAILABLE';
    }
  }
  else {
    print WR "Unable to obtain diagnostics re signbitl() - assuming it's available\n" if $open;
  }
}

###############################################

# Try to detect the absence of sincosl and implement
# workaround (-DSINCOSL_IS_UNAVAILABLE) when absence is detected.

# Build with "-Wno-implicit-function-declaration" to work around the problem of
# such warnings being fatal with gcc-14 and later.
$out = `$cc $opt -Wno-implicit-function-declaration -o try5.exe -x c try5.in -lm 2>&1`;

print WR "build output (sincosl check): $out\n" if $open;

# No linking problem yet if try5.exe exists.
unless(-e 'try5.exe') {

  if($out =~ /(`|'|"|\s)_?sincosl('|`|"|\s)/) {
    $defines .= ' -DSINCOSL_IS_UNAVAILABLE';
  }
}
else {
  my $diag = $^O =~ /mswin32/i ? `try5.exe 0 2>&1` : `./try5.exe 0 2>&1`;
  if(defined($diag)) {
    print WR "execution output (sincosl check): $diag\n" if $open;       # 163
    unless ($diag =~ /^output: /) {                                      # 164
      $defines .= ' -DSINCOSL_IS_UNAVAILABLE';
    }
  }
  else {
    print WR "Unable to obtain diagnostics re sincosl() - assuming it's available\n" if $open;
  }
}

###############################################

if($open) {close WR or warn "Unable to close $log after writing: $!"}

# Uncomment following line to test the various workarounds - should make no difference to test results.
#$defines .= ' -DNANL_IS_UNAVAILABLE -DISNANL_IS_UNAVAILABLE -DSIGNBITL_IS_UNAVAILABLE -DNAN_POW_BUG -DSINCOSL_IS_UNAVAILABLE';

$defines .= $] < 5.008 ? " -DOLDPERL" : " -DNEWPERL";

$defines .= $Config::Config{byteorder} =~ /^1234/ ? " -DWE_HAVE_LENDIAN" : " -DWE_HAVE_BENDIAN";

$defines .= " -DLONGLONG2IV_IS_OK"
  if $Config::Config{ivsize} >= $Config::Config{longlongsize};

$defines .= " -DLONG2IV_IS_OK"
  if $Config::Config{ivsize} >= $Config::Config{longsize};

# Casting an extended precision inf to a __float128 may result in a nan
$defines .= " -DNO_INF_CAST_TO_NV"
  if ($Config{nvtype} eq '__float128' && ($Config{longdblkind} == 3 || $Config{longdblkind} == 4));

$defines .= ' -DMATH_LONGDOUBLE_DEBUG'
  if "@ARGV" =~ /DEBUG/;

$defines .= " -DCFG_LONGDBLKIND=$Config{longdblkind}" if( defined $Config{longdblkind} &&
                                                                  $Config{longdblkind} >= 0 );

# Define ACTUAL_NVSIZE to the
# actual size of perl's NV:

my $nvsize = $Config{nvsize};
if($nvsize > 8) {
  $nvsize = 10 if length(sqrt(2.0)) < 30;
}
$defines .= " -DACTUAL_NVSIZE=$nvsize";

my %options = %{
{
  NAME => 'Math::LongDouble',
  LIBS => [
    '-lm'
  ],
  INC => '',
  LICENSE  => 'perl',
  VERSION_FROM => 'LongDouble.pm',
  DEFINE   => $defines,
  clean   => { FILES => '*.exe myconfig.log' },
  CCFLAGS => "$Config{ccflags}" . " -Wno-implicit-function-declaration", # such warnings are fatal with gcc-14 onwards
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-longdouble.git',
        web => 'https://github.com/sisyphus/math-longdouble',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
