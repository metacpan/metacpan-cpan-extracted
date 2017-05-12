use ExtUtils::MakeMaker;
use Config;


eval {require ActivePerl::DocTools;};
unless($@) {
  warn "\n  WARNING: The sqrt and ** (pow) overloading is buggy\n",
       "           on ActivePerl. (See the README file.)\n\n";
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


my $out = `$cc $opt -o try.exe -x c try.in -lm 2>&1`;

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
  print WR "erfl & isnanl check (run): $diag\n" if $open;
  if($diag =~ /(`|'|"|\s)_?erfl('|`|"|\s)/) {
    print "Aborting:\n$diag\n";
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

###############################################
# Try to detect whether nanl() is available and
# implement a workaround if it's not.

my $out = `$cc $opt -o try3.exe -x c try3.in -lm 2>&1`;

print WR "build output (nanl check): $out\n" if $open;

# No linking problem at all if try3.exe exists.
unless(-e 'try3.exe') {

  if($out =~ /(`|'|"|\s)_?nanl('|`|"|\s)/) {
    $defines .= ' -DNANL_IS_UNAVAILABLE';
  }
}
else {
  my $diag = $^O =~ /mswin32/i ? `try3.exe 0 2>&1` : `./try3.exe 0 2>&1`;
  print WR "execution output (nanl check): $diag\n" if $open;
  unless ($diag =~ /^rop /) {
    $defines .= ' -DNANL_IS_UNAVAILABLE';
  }
}

###############################################

# Try to detect a nan bug that has nan**0 is nan.
# (Correct implementations have nan**0 == 1.)

$out = `$cc $opt -o try2.exe -x c $defines try2.in -lm 2>&1`;

sleep 1;

print WR "build output (nan**0 check):\n$out\n" if $open;

$diag = $^O =~ /mswin32/i ? `try2.exe nan 0 2>&1` : `./try2.exe nan 0 2>&1`;

print WR "nan**0 check diagnostic: $diag\n" if ($open && defined $diag);

$defines .= ' -DNAN_POW_BUG' if $diag =~ /^NaN/i;

###############################################

# Try to detect whether signbitl() is available and
# implement a workaround if it's not.

my $out = `$cc $opt -o try4.exe -x c try4.in -lm 2>&1`;

print WR "build output (signbitl check): $out\n" if $open;

# No linking problem yet if try4.exe exists.
unless(-e 'try4.exe') {
  if($out =~ /(`|'|"|\s)_?signbitl('|`|"|\s)/) {
    $defines .= ' -DSIGNBITL_IS_UNAVAILABLE';
  }
}
else {
  my $diag = $^O =~ /mswin32/i ? `try4.exe 0 2>&1` : `./try4.exe 0 2>&1`;
  print WR "execution output (signbitl check): $diag\n" if $open;
  unless ($diag =~ /^ret /) {
    $defines .= ' -DSIGNBITL_IS_UNAVAILABLE';
  }
}

###############################################

# Try to detect the absence of sincosl and implement
# workaround (-DSINCOSL_IS_UNAVAILABLE) when absence is detected.

my $out = `$cc $opt -o try5.exe -x c try5.in -lm 2>&1`;

print WR "build output (sincosl check): $out\n" if $open;

# No linking problem yet if try5.exe exists.
unless(-e 'try5.exe') {

  if($out =~ /(`|'|"|\s)_?sincosl('|`|"|\s)/) {
    $defines .= ' -DSINCOSL_IS_UNAVAILABLE';
  }
}
else {
  my $diag = $^O =~ /mswin32/i ? `try5.exe 0 2>&1` : `./try5.exe 0 2>&1`;
  print WR "execution output (sincosl check): $diag\n" if $open;
  unless ($diag =~ /^output: /) {
    $defines .= ' -DSINCOSL_IS_UNAVAILABLE';
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

$defines .= ' -DMATH_LONGDOUBLE_DEBUG'
  if "@ARGV" =~ /DEBUG/;

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
