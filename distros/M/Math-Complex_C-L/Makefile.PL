use ExtUtils::MakeMaker;
use Config;

$defines = $] < 5.008 ? "-DOLDPERL" : "-DNEWPERL";

my $log = './myconfig.log';
my $open = open WR, '>', $log;
print "Couldn't open $log for writing: $!\n" unless $open;

###############################################

# Try to detect some common fatal linking errors ahead of time. If we detect
# that any of these linking problems exist, we then abort the Makefile.PL then
# and there. This doesn't do anything useful beyond avoiding cpan-tester FAIL reports.
# Also abort if gcc compiler's version is less than 4.
# We also abort (BSD systems only) if try.exe fails to execute.
# Comment out the "exit 0;" occurrences below if they're enacted unduly (and please
# contact me - eg file a bug report).

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
print WR "\nCC = $cc\nOPTIMIZE = $opt\n" if $open;

my $out = `$cc $opt -o try.exe -x c try.in -lm 2>&1`;

print WR "catanhl & powl check: $out\n" if $open;

# There's a linking problem if try.exe does not exist.
unless(-e 'try.exe') {
  if($out =~ /(`|'|"|\s)_?catanhl('|`|"|\s)/ ||
     $out =~ /(`|'|"|\s)_?cpowl('|`|"|\s)/     ) {
    close WR if $open;
    unlink $log if -e $log;
    print "Aborting:\n$out\n";
    exit 0; # abort the build
  }
}

my $abort = 0;

# Trying to eliminate BSD cpan-tester systems that apparently have a
# compiler with only a limited range of complex long double functions.
# Haven't struck this with any systems other than NetBSD, Dragonfly BSD
# and FreeBSD - so I'll limit the checks to those systems only.
# No problems with openbsd and gnukfreebsd.

if($Config{osname} !~ /k/i && $Config{osname} !~ /open/i &&
   ($Config{osname} =~ /bsd/i || $Config{osname} =~ /dragonfly/i)) {
  if( system './try.exe', '0.25', '0.75') {$abort = 1}
  else {
    if($Config{osname} =~ /MSWin32/i) {$out =   `try.exe 0.25 0.75 2>&1`}
    else                              {$out = `./try.exe 0.25 0.75 2>&1`}
    print WR $out;
    print WR "try.exe apparently ran fine\n";
  }
}

# Remove the test executable
if(-e 'try.exe' && !unlink('./try.exe')) {
  warn "Failed to unlink try.exe";
}

if($abort) {
  close WR if $open;
  unlink $log if -e $log;
  warn "Aborting: ./try.exe threw errors";
  exit 0; # abort the build
}

###############################################
# Check to see what version of gcc we have and
# abort if it's less than 4.
my $out = `$cc $opt -o try2.exe -x c try2.in -lm 2>&1`;

print WR "gcc version check (build): $out\n" if $open;

my $diag = $^O =~ /mswin32/i ? `try2.exe 2>&1` : `./try2.exe 2>&1`;

print WR "gcc version check (run): $diag\n" if $open;

if($diag =~ /^gcc is too old/) {
  close WR if $open;
  unlink $log if -e $log;
  unlink 'try2.exe';
  print "Aborting: $diag";
  exit 0;
}

# Remove the test executable
if(-e 'try2.exe' && !unlink('./try2.exe')) {
  warn "Failed to unlink try2.exe";
}

###############################################

if($open) {close WR or warn "Unable to close $log after writing: $!"}

# Casting an extended precision inf to a __float128 may result in a nan
$defines .= " -DNO_INF_CAST_TO_NV"
  if ($Config{nvtype} eq '__float128' && ($Config{longdblkind} == 3 || $Config{longdblkind} == 4));

my %options = %{
{
  'NAME' => 'Math::Complex_C::L',
  'LIBS' => [
    '-lm'
  ],
  'DEFINE' => $defines,
  'INC' => '',
  'VERSION_FROM' => 'L.pm',
  clean   => { FILES => '*.exe myconfig.log' },
  LICENSE => 'perl',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-complex_c-l.git',
        web => 'https://github.com/sisyphus/math-complex_c-l',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
