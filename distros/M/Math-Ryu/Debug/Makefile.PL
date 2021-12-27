use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (

  NAME => 'Math::Ryu::Debug',
  PREREQ_PM    => { 'Test::More' => '0.88', },
  LICENSE      => 'perl',
  DEFINE       => ' -DRYU_DEBUG',
  VERSION_FROM => 'Debug.pm',
  OBJECT       => '$(O_FILES)',
  META_MERGE   => {
    'meta-spec'  => { version => 2 },
    resources    => {
      repository   => {
        type         => 'git',
        url          => 'https://github.com/sisyphus/math-ryu.git',
        web          => 'https://github.com/sisyphus/math-ryu',
      },
    },
  },
);
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
# sub MY::makefile { '' }
