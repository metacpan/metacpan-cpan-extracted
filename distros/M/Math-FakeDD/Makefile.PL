use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.022; # $Config{longdblkind} is available.

my %options = %{
{
  NAME => 'Math::FakeDD',
  VERSION_FROM => 'FakeDD.pm',
  PREREQ_PM => {'Math::MPFR' => '4.22'},
  LICENSE  => 'perl',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-nv.git',
        web => 'https://github.com/sisyphus/math-nv',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
