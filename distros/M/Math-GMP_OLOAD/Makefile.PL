use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
  NAME     => 'Math::GMP_OLOAD',
  VERSION_FROM => 'GMP_OLOAD.pm',
  AUTHOR => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  ABSTRACT => 'Assist Math::GMPq/GMPz/MPFR with  overloading of Math::GMP objects',
  LICENSE  => 'perl',
  PREREQ_PM => {
                 'Test::More' => '0.88',
                 'Exporter'   => '5.58', # avoid test failures on pre perl-5.8.4
                 'Math::GMP'   => '2.11',
               },
  META_MERGE   => {
   'meta-spec' => { version => 2 },
    resources  => {
      repository => {
        type => 'git',
        url  => 'https://github.com/sisyphus/math-gmp_oload.git',
        web  => 'https://github.com/sisyphus/math-gmp_oload',
      },
    },
  },
);
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
# sub MY::makefile { '' }
