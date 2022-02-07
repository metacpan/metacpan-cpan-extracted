use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

my $defines = $] < 5.008 ? "-DOLDPERL" : "-DNEWPERL";

# Try to detect the presence/absence of a common gcc bug in ctanq() and ctanhq().
# We test only for the ctanq() bug, as either both functions are buggy or
# neither is buggy.
my $cc;

if(@ARGV) {
  for my $arg(@ARGV) {
    $cc = (split /=/, $arg)[1] if $arg =~ /^cc=/i;
  }
}

unless(defined($cc)) {
  $cc = defined($Config{cc}) ? $Config{cc} : 'cc';
}

my $out = `$cc -o try.exe -x c try.in -lquadmath 2>&1`;
my $diag = $^O =~ /mswin32/i ? `try.exe 2>&1` : `./try.exe 2>&1`;

print "\ndiag: $diag\n" if -e 'try.exe';

if($diag =~ /^bugginess detected/) {
  print "tan/tanh bug present - implementing workaround\n";
  $defines .= ' -DGCC_TAN_BUG';
}

if($diag =~ /^known bug not detected/) {
  print "tan/tanh bug absent\n";
  $defines .= ' -DNO_GCC_TAN_BUG';
}

# Remove the test executable
if(-e 'try.exe' && !unlink('./try.exe')) {
  warn "Failed to unlink try.exe";
}

# Attempt to avoid the incorrect 'FAIL' reports from Chris Williams' broken NetBSD smoker(s).
# Comment out the 'exit 0;' (26 lines further down) if this causes problems.

if($Config{osname} eq 'netbsd') {

  my $inc = '';

  if(@ARGV) {
    for my $arg(@ARGV) {
      $inc = (split /=/, $arg)[1] if $arg =~ /^inc=/i;
    }
  }

  $inc =~ s/'//g;
  $inc =~ s/"//g;

  my $opt = $Config{optimize};

  my $out = `$cc $opt $inc $Config{ccflags} -o quad.exe -x c quad.in 2>&1`;

  if($out =~ /quadmath\.h: No such file or directory/i) {
    print "Aborting: Got\n$out\n";
    exit 0;
  }
}

$defines .= " -DNV_IS_DOUBLE"
  if $Config{nvtype} eq 'double';

my %options = %{
{
  NAME => 'Math::Complex_C::Q',
  LIBS => [
    '-lm -lquadmath'
  ],
  DEFINE => $defines,
  INC => '',
  VERSION_FROM => 'Q.pm',
  clean   => { FILES => '*.exe' },
  LICENSE => 'perl',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-complex_c-q.git',
        web => 'https://github.com/sisyphus/math-complex_c-q',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
