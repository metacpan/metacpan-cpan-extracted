use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = %{
{
  NAME => 'Math::NumOnly',
  VERSION_FROM => 'NumOnly.pm',
  LICENSE  => 'perl',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-numonly.git',
        web => 'https://github.com/sisyphus/math-numonly',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
