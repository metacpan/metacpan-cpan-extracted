use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.030; # avoid buggy floating-point assignments

if($Config::Config{nvsize} != 8) {
 warn "Aborting: This module currently requires that \$Config{nvsize} is 8\n";
 exit 0;
}

my %options = %{
{
  NAME => 'Math::JS',
  VERSION_FROM => 'JS.pm',
  LICENSE  => 'perl',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-js.git',
        web => 'https://github.com/sisyphus/math-js',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
