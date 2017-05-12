use ExtUtils::MakeMaker;

use Config;
require 5.006;

$defines = $] < 5.008 ? "-DOLDPERL" : "-DNEWPERL";

###############################################

# Try to detect some common fatal linking errors ahead of time. If we detect
# that any of these linking problems exist, we then abort the Makefile.PL then
# and there. This doesn't do anything useful beyond avoiding cpan-tester FAIL reports.
# To avoid being subjected to the abort, just comment out line 35 below (which is "exit 0;")

my $cc;

if(@ARGV) {
  for my $arg(@ARGV) {
    $cc = (split /=/, $arg)[1] if $arg =~ /^cc=/i;
  }
}

unless(defined($cc)) {
  $cc = defined($Config{cc}) ? $Config{cc} : 'cc';
}

my $out = `$cc -o try.exe -x c try.in -lm 2>&1`;

print "output: $out\n";

# No linking problem at all if try.exe exists.
unless(-e 'try.exe') {
  if($out =~ /(`|'|"|\s)_?cpow('|`|"|\s)/) {
    print "Aborting:\n$out\n";
    exit 0; # abort the build
  }
}
# Remove the test executable
if(-e 'try.exe' && !unlink('./try.exe')) {
  warn "Failed to unlink try.exe";
}

###############################################

my %options = %{
{
  NAME => 'Math::Complex_C',
  INC => '',
  DEFINE => $defines,
  LIBS => ['-lm'],
  LICENSE  => 'perl',
  VERSION_FROM => 'Complex_C.pm',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-complex_c.git',
        web => 'https://github.com/sisyphus/math-complex_c',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
