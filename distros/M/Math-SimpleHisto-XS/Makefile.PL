use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $name = 'Math::SimpleHisto::XS';
my $define = '';
if (grep {/--debug/} @ARGV) {
  $define = '-Wall -Wextra -O0 -g';
}
else {
  $define = '-O2';
}

WriteMakefile(
    NAME              => $name,
    VERSION_FROM      => 'lib/Math/SimpleHisto/XS.pm', # finds $VERSION
    PREREQ_PM         => {
      'ExtUtils::ParseXS' => '2.2201',
      'Test::More' => '0.88',
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Math/SimpleHisto/XS.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    LIBS              => [''],
    DEFINE            => $define,
    INC               => '-I.',
    OBJECT            => '$(O_FILES)', # link all the C files too
);

if (eval "require ExtUtils::Constant; 1;") {
  open my $fh, '<', 'hist_constants.h'
    or die "Could not open 'hist_constants.h' for reading: $!";
  my @constants;
  while (<$fh>) {
    m{
      ^ \s* \# \s* define \s+
      (\w+) \s+
      [+-]?
      (?=\d|\.\d)
      \d*(?:\.\d*)?
      (?:[Ee][+-]?\d+)?
    }x or next;
    push @constants, $1;
  }

  ExtUtils::Constant::WriteConstants(
    NAME => $name,
    NAMES => \@constants,
  );
}

